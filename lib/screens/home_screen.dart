import '../widgets/memory_prompt_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_library_query.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../services/language_controller.dart';
import '../services/theme_controller.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/app_theme_picker.dart';
import '../widgets/cinematic_album_opening.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/occasion_cards.dart';
import '../widgets/privacy_policy_button.dart';
import 'editor_screen.dart';
import 'cards_hub.dart';
import 'memory_album_screen.dart';
import '../models/memory_period.dart';
import '../services/cover_entitlements.dart';
import '../services/reminder_service.dart';
import 'special_card_studio_screen.dart';
import 'theme_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeController,
    required this.languageController,
    this.coverEntitlements,
    this.heroMotionEnabled = true,
  });

  final ThemeController themeController;
  final LanguageController languageController;

  /// Shared with the cover picker so a purchase made there is visible here.
  final CoverEntitlements? coverEntitlements;
  final bool heroMotionEnabled;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _libraryPageSize = 12;

  List<AlbumModel> _albums = [];
  List<AlbumModel>? _matchingAlbumsCache;
  final TextEditingController _searchController = TextEditingController();
  AlbumLibraryFilter _libraryFilter = AlbumLibraryFilter.all;
  AlbumLibrarySort _librarySort = AlbumLibrarySort.updatedNewest;
  int _visibleAlbumCount = _libraryPageSize;
  bool _loading = true;
  int _section = 0;
  bool _openingMemory = false;

  @override
  void initState() {
    super.initState();
    _reload();
    ReminderService.pending.addListener(_onMemoryNotification);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _onMemoryNotification(),
    );
  }

  @override
  void dispose() {
    ReminderService.pending.removeListener(_onMemoryNotification);
    _searchController.dispose();
    super.dispose();
  }

  void _resetLibraryPage() {
    _visibleAlbumCount = _libraryPageSize;
    _matchingAlbumsCache = null;
  }

  List<AlbumModel> get _matchingAlbums =>
      _matchingAlbumsCache ??= queryAlbumLibrary(
        _albums,
        searchQuery: _searchController.text,
        filter: _libraryFilter,
        sort: _librarySort,
      );

  void _clearLibraryQuery() {
    setState(() {
      _searchController.clear();
      _libraryFilter = AlbumLibraryFilter.all;
      _librarySort = AlbumLibrarySort.updatedNewest;
      _resetLibraryPage();
    });
  }

  Future<void> _reload() async {
    final albums = (await AlbumStorage.instance.loadAlbums())
        .where((a) => a.projectType == AlbumProjectType.album)
        .toList();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _matchingAlbumsCache = null;
      _loading = false;
    });
  }

  Future<void> _createAlbum({AlbumThemeCategory? category}) async {
    HapticFeedback.selectionClick();
    final album = await Navigator.of(context).push<AlbumModel>(
      MaterialPageRoute(
        builder: (_) => ThemeScreen(
          initialCategory: category,
          entitlements: widget.coverEntitlements,
        ),
      ),
    );
    if (album == null || !mounted) return;
    await _openAlbum(album);
  }

  Future<void> _createProject() => _createAlbum();

  Future<void> _onMemoryNotification() async {
    final data = ReminderService.pending.value;
    if (data == null || !mounted || _openingMemory) return;
    ReminderService.pending.value = null;
    _openingMemory = true;
    try {
      final kinds = (data['kinds'] as String)
          .split(',')
          .where((k) => MemoryKind.values.any((v) => v.name == k))
          .map((k) => MemoryKind.values.byName(k))
          .toList();
      if (kinds.isEmpty) return;
      setState(() => _section = 0);
      final date = DateTime(
        data['year'] as int,
        data['month'] as int,
        data['day'] as int,
      );
      final kind = kinds.length == 1
          ? kinds.first
          : await showModalBottomSheet<MemoryKind>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final k in kinds)
                      ListTile(
                        title: Text(context.tr(MemoryPeriod(k, date).prompt)),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.pop(context, k),
                      ),
                  ],
                ),
              ),
            );
      if (kind != null && mounted) {
        await _startMemory(MemoryPeriod.current(kind, date));
      }
    } finally {
      _openingMemory = false;
      if (mounted && ReminderService.pending.value != null) {
        _onMemoryNotification();
      }
    }
  }

  Future<void> _startMemory(MemoryPeriod period) async {
    final albums = await AlbumStorage.instance.loadAlbums();
    if (!mounted) return;
    final matches = albums.where((a) => a.memoryPeriod == period.key).toList();
    if (matches.isNotEmpty) {
      final createNew = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('Bu döneme ait albümün var')),
          content: Text(matches.first.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Devam et')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('Yeni albüm')),
            ),
          ],
        ),
      );
      if (createNew == null || !mounted) return;
      if (!createNew) {
        await _openAlbum(matches.first);
        return;
      }
    }
    if (!mounted) return;
    final album = await Navigator.push<AlbumModel>(
      context,
      MaterialPageRoute(builder: (_) => MemoryAlbumScreen(period: period)),
    );
    if (album != null && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => EditorScreen(album: album)),
      );
      await _reload();
    }
  }

  Future<void> _openAlbum(AlbumModel album) async {
    HapticFeedback.lightImpact();
    if (album.projectType == AlbumProjectType.occasionCard) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SpecialCardStudioScreen(project: album),
        ),
      );
      await AlbumStorage.instance.flush();
      await _reload();
      return;
    }
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 430),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => _CinematicOpeningScreen(album: album),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.985, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    // Dispose'daki olası gecikmiş _persistChanges() tamamlanmadan
    // okuma yapılmaması için yazma kuyruğunun bitmesini bekle.
    await AlbumStorage.instance.flush();
    await _reload();
  }

  Future<void> _delete(AlbumModel album) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          album.projectType == AlbumProjectType.occasionCard
              ? context.tr('Kart silinsin mi?')
              : context.tr('Albüm silinsin mi?'),
        ),
        content: Text(
          context.tr(
            '“{title}” bu cihazdan kaldırılacak.',
            values: {'title': album.title},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Sil')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AlbumStorage.instance.deleteAlbum(album);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    const minimumHorizontalInset = 22.0;
    const maximumContentWidth = 1280.0;
    final centeredInset = (viewportWidth - maximumContentWidth) / 2;
    final horizontalInset = centeredInset > minimumHorizontalInset
        ? centeredInset
        : minimumHorizontalInset;
    final matchingAlbums = _matchingAlbums;
    final visibleAlbums = matchingAlbums
        .take(_visibleAlbumCount)
        .toList(growable: false);
    final remainingAlbumCount = matchingAlbums.length - visibleAlbums.length;
    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _section,
        onDestinationSelected: (value) {
          setState(() => _section = value);
          if (value == 0) _reload();
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            label: context.tr('Albümler'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            label: context.tr('Kartlar'),
          ),
        ],
      ),
      body: CraftBackdrop(
        key: const ValueKey('home-velvet-backdrop'),
        variant: CraftBackdropVariant.velvet,
        baseColor: colors.background,
        textureColor: Color.lerp(colors.text, colors.primary, .32),
        textureIntensity: .48,
        child: SafeArea(
          child: _section == 1
              ? const CardsHub()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalInset,
                          12,
                          horizontalInset,
                          8,
                        ),
                        child: Row(
                          children: [
                            const Expanded(child: _AlbumiumSignature()),
                            _LanguageButton(
                              controller: widget.languageController,
                            ),
                            const SizedBox(width: 4),
                            _PaletteButton(
                              controller: widget.themeController,
                              onTap: () => showAlbumiumThemePicker(
                                context,
                                widget.themeController,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalInset,
                          13,
                          horizontalInset,
                          27,
                        ),
                        child: SizedBox(
                          key: const ValueKey('home-hero-content'),
                          width: double.infinity,
                          child: _HeroPanel(
                            onCreate: _createProject,
                            motionEnabled: widget.heroMotionEnabled,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _CoverCategoryShowcase(
                        horizontalInset: horizontalInset,
                        onSelect: (category) =>
                            _createAlbum(category: category),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.tr('Anılarını biriktir'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      showReminderSettings(context),
                                  tooltip: context.tr('Anı hatırlatmaları'),
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                  ),
                                ),
                              ],
                            ),
                            MemoryPromptCards(
                              onSelect: (kind) => _startMemory(
                                MemoryPeriod.current(kind, DateTime.now()),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                context.tr('Koleksiyonum'),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: colors.text,
                                      fontSize: 25,
                                    ),
                              ),
                            ),
                            if (_albums.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text(
                                matchingAlbums.length == _albums.length
                                    ? '${_albums.length}'
                                    : '${matchingAlbums.length} / ${_albums.length}',
                                style: TextStyle(
                                  color: colors.mutedText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (_albums.isNotEmpty && viewportWidth >= 680) ...[
                              const Spacer(),
                              Text(
                                context.tr('Silmek için basılı tut'),
                                style: TextStyle(
                                  color: colors.mutedText,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!_loading && _albums.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalInset,
                            14,
                            horizontalInset,
                            2,
                          ),
                          child: _LibraryToolbar(
                            controller: _searchController,
                            sort: _librarySort,
                            onSearchChanged: (_) {
                              setState(_resetLibraryPage);
                            },
                            onClearSearch: () {
                              setState(() {
                                _searchController.clear();
                                _resetLibraryPage();
                              });
                            },
                            onSortChanged: (sort) {
                              setState(() {
                                _librarySort = sort;
                                _resetLibraryPage();
                              });
                            },
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22),
                          child: PrivacyPolicyButton(),
                        ),
                      ),
                    ),
                    if (_loading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_albums.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onCreate: _createProject),
                      )
                    else if (matchingAlbums.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoLibraryResults(onClear: _clearLibraryQuery),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalInset,
                          19,
                          horizontalInset,
                          remainingAlbumCount > 0 ? 20 : 112,
                        ),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 17,
                                mainAxisSpacing: 23,
                              ),
                          itemCount: visibleAlbums.length,
                          itemBuilder: (context, index) {
                            final album = visibleAlbums[index];
                            return _AlbumGridItem(
                              key: ValueKey('library-item-${album.id}'),
                              album: album,
                              onTap: () => _openAlbum(album),
                              onLongPress: () => _delete(album),
                            );
                          },
                        ),
                      ),
                    if (!_loading && remainingAlbumCount > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalInset,
                            2,
                            horizontalInset,
                            112,
                          ),
                          child: Center(
                            child: OutlinedButton.icon(
                              key: const ValueKey('library-load-more'),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _visibleAlbumCount += _libraryPageSize;
                                });
                              },
                              icon: const Icon(Icons.expand_more_rounded),
                              label: Text(
                                context.tr(
                                  'Daha fazla göster ({count})',
                                  values: {'count': remainingAlbumCount},
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
      floatingActionButton: _section == 1 || _albums.isEmpty
          ? null
          : FloatingActionButton(
              shape: const CircleBorder(),
              elevation: 2,
              onPressed: _createProject,
              tooltip: context.tr('Yeni tasarım'),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.controller,
    required this.sort,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortChanged,
  });
  final TextEditingController controller;
  final AlbumLibrarySort sort;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<AlbumLibrarySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('library-search'),
          controller: controller,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: colors.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: context.tr('Albüm ara'),
            prefixIcon: const Icon(Icons.search_rounded, size: 21),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 48,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.tr('Aramayı temizle'),
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Spacer(),
            PopupMenuButton<AlbumLibrarySort>(
              key: const ValueKey('library-sort'),
              initialValue: sort,
              tooltip: context.tr('Koleksiyonu sırala'),
              onSelected: onSortChanged,
              icon: const Icon(Icons.sort_rounded, size: 22),
              itemBuilder: (context) => AlbumLibrarySort.values
                  .map(
                    (value) => CheckedPopupMenuItem(
                      value: value,
                      checked: value == sort,
                      child: Text(context.tr(_librarySortLabel(value))),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ],
    );
  }
}

String _librarySortLabel(AlbumLibrarySort sort) => switch (sort) {
  AlbumLibrarySort.updatedNewest => 'Son düzenlenen',
  AlbumLibrarySort.createdNewest => 'En yeni',
  AlbumLibrarySort.createdOldest => 'En eski',
  AlbumLibrarySort.titleAz => 'Ada göre',
};

class _NoLibraryResults extends StatelessWidget {
  const _NoLibraryResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 96),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: colors.primary, size: 34),
              const SizedBox(height: 10),
              Text(
                context.tr('Bu seçimde bir tasarım bulamadık'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr(
                  'Arama sözcüğünü ya da filtreleri değiştirebilirsin.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                key: const ValueKey('library-clear-query'),
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('Tümünü göster')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumiumSignature extends StatelessWidget {
  const _AlbumiumSignature();

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Semantics(
      label: 'Albumium',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Image.asset(
              'assets/branding/albumium_brand_mark.png',
              width: 38,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'lbumium',
                  key: const ValueKey('home-brand-word'),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    color: colors.text,
                    letterSpacing: -.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatefulWidget {
  const _HeroPanel({required this.onCreate, required this.motionEnabled});
  final VoidCallback onCreate;
  final bool motionEnabled;

  @override
  State<_HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<_HeroPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typewriter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1550),
  );
  String? _animatedText;
  bool _started = false;
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final text = context.tr('Anılarına hoş geldin');
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      _animatedText = text;
      if (widget.motionEnabled) _beginTypewriter(reduceMotion);
    } else if (_animatedText != text) {
      _animatedText = text;
      _typewriter.value = _played ? 1 : 0;
    } else if (reduceMotion && !_typewriter.isCompleted) {
      _typewriter.value = 1;
      _played = true;
    }
  }

  @override
  void didUpdateWidget(covariant _HeroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.motionEnabled && widget.motionEnabled && !_played) {
      _beginTypewriter(MediaQuery.disableAnimationsOf(context));
    }
  }

  void _beginTypewriter(bool reduceMotion) {
    _played = true;
    _typewriter.value = reduceMotion ? 1 : 0;
    if (!reduceMotion) _typewriter.forward();
  }

  @override
  void dispose() {
    _typewriter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final wide =
        MediaQuery.sizeOf(context).width >= 860 &&
        MediaQuery.textScalerOf(context).scale(14) <= 19;
    final title = _animatedText ?? context.tr('Anılarına hoş geldin');
    final titleStyle =
        (Theme.of(context).textTheme.displaySmall ?? const TextStyle())
            .copyWith(
              color: colors.text,
              fontSize: wide ? 42 : 34,
              height: 1.12,
              letterSpacing: -.8,
            );
    final copy = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('HİKÂYEN BURADA BAŞLIYOR'),
            style: TextStyle(
              color: colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            label: title,
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  // Reserve the complete headline using its actual constraints,
                  // including tablet layouts and system text scaling.
                  Opacity(
                    opacity: 0,
                    child: RichText(
                      textScaler: MediaQuery.textScalerOf(context),
                      text: TextSpan(text: title, style: titleStyle),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _typewriter,
                      builder: (context, _) {
                        final characters = title.characters;
                        final length = (characters.length * _typewriter.value)
                            .floor()
                            .clamp(0, characters.length);
                        return Text(
                          characters.take(length).toString(),
                          key: const ValueKey('home-welcome-title'),
                          style: titleStyle,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('Albümlerini kaldığın yerden düzenle.'),
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
    final create = FilledButton.icon(
      key: const ValueKey('home-create-design'),
      onPressed: widget.onCreate,
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(context.tr('Yeni tasarım')),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.elevatedSurface, colors.heroStart, .24)!,
            Color.lerp(colors.elevatedSurface, colors.heroEnd, .08)!,
          ],
        ),
        borderRadius: BorderRadius.circular(wide ? 30 : 24),
        border: Border.all(color: colors.primary.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: colors.text.withValues(alpha: .07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(wide ? 30 : 24),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -42,
              width: 210,
              height: 210,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MemoryOrbitPainter(colors.primary),
                ),
              ),
            ),
            Positioned(
              left: -55,
              bottom: -84,
              width: 180,
              height: 180,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MemoryOrbitPainter(colors.secondary),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 34 : 22,
                wide ? 30 : 24,
                wide ? 30 : 22,
                wide ? 30 : 24,
              ),
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: 28),
                        create,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 20), create],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryOrbitPainter extends CustomPainter {
  const _MemoryOrbitPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .48);
    final line = Paint()
      ..color = color.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final inset in [12.0, 35.0, 60.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width - inset * 2,
          height: (size.height - inset * 2) * .62,
        ),
        line,
      );
    }
    final dot = Paint()..color = color.withValues(alpha: .13);
    canvas.drawCircle(Offset(size.width * .16, size.height * .45), 3.5, dot);
    canvas.drawCircle(Offset(size.width * .74, size.height * .22), 2.5, dot);
    canvas.drawCircle(Offset(size.width * .81, size.height * .69), 4, dot);
  }

  @override
  bool shouldRepaint(_MemoryOrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.controller});
  final LanguageController controller;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PopupMenuButton<AppLanguage>(
      key: const ValueKey('home-language-button'),
      tooltip: context.tr('Dili değiştir'),
      initialValue: controller.language,
      onSelected: controller.setLanguage,
      itemBuilder: (context) => AppLanguage.values
          .map(
            (language) => CheckedPopupMenuItem(
              value: language,
              checked: language == controller.language,
              child: Text(language.displayName),
            ),
          )
          .toList(growable: false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, color: colors.text, size: 20),
              const SizedBox(width: 5),
              Text(
                controller.language.shortLabel,
                key: const ValueKey('home-language-code'),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({required this.controller, required this.onTap});
  final ThemeController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('home-theme-button'),
      tooltip: context.tr('Uygulama temasını değiştir'),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.palette_outlined),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.selectedOption.previewColors.first,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumGridItem extends StatelessWidget {
  const _AlbumGridItem({
    super.key,
    required this.album,
    required this.onTap,
    required this.onLongPress,
  });
  final AlbumModel album;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final isCard = album.projectType == AlbumProjectType.occasionCard;
    final scaler = MediaQuery.textScalerOf(context);
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: isCard
            ? context.tr(
                '{title}, özel gün kartı',
                values: {'title': album.title},
              )
            : context.tr(
                '{title}, {count} sayfa',
                values: {'title': album.title, 'count': album.pages.length},
              ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 3, 2, 0),
                    child: Center(
                      child: AspectRatio(
                        key: ValueKey('library-cover-${album.id}'),
                        aspectRatio: isCard ? 5 / 7 : 15 / 22,
                        child: isCard
                            ? _SpecialCardThumbnail(project: album)
                            : AlbumCover3D(
                                album: album,
                                compact: true,
                                perspective: false,
                                showTitle: false,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height:
                      (scaler.scale(18) * 1.15).ceilToDouble() * 2 +
                      4 +
                      (scaler.scale(11) * 1.35).ceilToDouble() * 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.text,
                          fontSize: 18,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCard
                            ? context.tr('Özel gün kartı')
                            : context.tr(
                                album.pages.length == 1
                                    ? '1 sayfa · {binding}'
                                    : '{count} sayfa · {binding}',
                                values: {
                                  'count': album.pages.length,
                                  'binding': context.tr(
                                    album.bindingType.title,
                                  ),
                                },
                              ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 28, 34, 55),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 68,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
                decoration: BoxDecoration(
                  color: colors.elevatedSurface,
                  border: Border.all(color: colors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      blurRadius: 6,
                      offset: Offset(3, 5),
                    ),
                  ],
                ),
                child: ColoredBox(
                  color: colors.glow,
                  child: Icon(
                    Icons.collections_bookmark_outlined,
                    size: 31,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                context.tr('İlk tasarımın burada yaşayacak'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.auto_awesome),
                label: Text(context.tr('Tasarım oluştur')),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Fotoğraflarını seç, anılarını bir albümde biriktir.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialCardThumbnail extends StatelessWidget {
  const _SpecialCardThumbnail({required this.project});

  final AlbumModel project;

  @override
  Widget build(BuildContext context) {
    final template = occasionTemplateById(project.cardThemeId);
    return Center(
      child: AspectRatio(
        aspectRatio: 5 / 7,
        child: IgnorePointer(
          child: OccasionCardView(
            cardId: template.id,
            customTitle: project.title,
            customSubtitle: context.tr('Kartını açmak için dokun'),
            customBadge: template.badge,
          ),
        ),
      ),
    );
  }
}

class _CinematicOpeningScreen extends StatefulWidget {
  const _CinematicOpeningScreen({required this.album});

  final AlbumModel album;

  @override
  State<_CinematicOpeningScreen> createState() =>
      _CinematicOpeningScreenState();
}

class _CinematicOpeningScreenState extends State<_CinematicOpeningScreen> {
  bool _enteringEditor = false;

  void _enterEditor() {
    if (_enteringEditor || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _enteringEditor = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: child.key == const ValueKey('editor') ? 1.018 : 1.0,
              end: 1.0,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _enteringEditor
          ? EditorScreen(key: const ValueKey('editor'), album: widget.album)
          : Scaffold(
              key: const ValueKey('opening'),
              backgroundColor: colors.background,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: CinematicAlbumOpening(
                      album: widget.album,
                      backgroundColor: colors.background,
                      onCompleted: _enterEditor,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                                tooltip: context.tr('Kapat'),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _enterEditor,
                                child: Text(context.tr('Geç')),
                              ),
                            ],
                          ),
                          const Spacer(),
                          AnimatedOpacity(
                            opacity: _enteringEditor ? 0 : 1,
                            duration: const Duration(milliseconds: 180),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.6,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    context.tr('Hikâyen açılıyor'),
                                    style: TextStyle(
                                      color: colors.text,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Sends the user into the cover picker already filtered to one category.
/// These are navigation cards, not filters for this page, so they are not
/// chips: nothing on the home screen changes when one is tapped.
class _CoverCategoryShowcase extends StatelessWidget {
  const _CoverCategoryShowcase({
    required this.horizontalInset,
    required this.onSelect,
  });

  final double horizontalInset;
  final ValueChanged<AlbumThemeCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);

    Widget card({
      required Key key,
      required IconData icon,
      required String label,
      required int count,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 104,
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: key,
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: .12),
                    ),
                    child: Icon(icon, size: 18, color: colors.primary),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      context.tr(label),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('{count} kapak', values: {'count': count}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: colors.mutedText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      key: const ValueKey('home-cover-categories'),
      padding: EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              0,
              horizontalInset,
              10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Kapak temaları'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onSelect(null),
                  child: Text(context.tr('Tümünü gör')),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              children: [
                card(
                  key: const ValueKey('home-cover-category-all'),
                  icon: Icons.auto_awesome_mosaic_outlined,
                  label: 'Tümü',
                  count: albumThemes.length,
                  onTap: () => onSelect(null),
                ),
                for (final category in AlbumThemeCategory.values)
                  card(
                    key: ValueKey('home-cover-category-${category.name}'),
                    icon: category.icon,
                    label: category.label,
                    count: themesInCategory(category).length,
                    onTap: () => onSelect(category),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

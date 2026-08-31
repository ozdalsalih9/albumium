import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/album_library_query.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../services/theme_controller.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/app_theme_picker.dart';
import '../widgets/cinematic_album_opening.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/occasion_cards.dart';
import 'editor_screen.dart';
import 'special_card_studio_screen.dart';
import 'theme_screen.dart';

enum _CreationKind { album, occasionCard }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _libraryPageSize = 12;

  List<AlbumModel> _albums = [];
  final TextEditingController _searchController = TextEditingController();
  AlbumLibraryFilter _libraryFilter = AlbumLibraryFilter.all;
  AlbumLibrarySort _librarySort = AlbumLibrarySort.updatedNewest;
  int _visibleAlbumCount = _libraryPageSize;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetLibraryPage() {
    _visibleAlbumCount = _libraryPageSize;
  }

  void _clearLibraryQuery() {
    setState(() {
      _searchController.clear();
      _libraryFilter = AlbumLibraryFilter.all;
      _librarySort = AlbumLibrarySort.updatedNewest;
      _resetLibraryPage();
    });
  }

  Future<void> _reload() async {
    final albums = await AlbumStorage.instance.loadAlbums();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  Future<void> _createAlbum() async {
    HapticFeedback.selectionClick();
    final album = await Navigator.of(
      context,
    ).push<AlbumModel>(MaterialPageRoute(builder: (_) => const ThemeScreen()));
    if (album == null || !mounted) return;
    await _openAlbum(album);
  }

  Future<void> _createProject() async {
    HapticFeedback.selectionClick();
    final kind = await showModalBottomSheet<_CreationKind>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreationPickerSheet(),
    );
    if (kind == null || !mounted) return;
    if (kind == _CreationKind.album) {
      await _createAlbum();
      return;
    }
    final project = createSpecialCardProject();
    await AlbumStorage.instance.saveAlbum(project);
    if (!mounted) return;
    await _openAlbum(project);
  }

  Future<void> _openAlbum(AlbumModel album) async {
    HapticFeedback.lightImpact();
    if (album.projectType == AlbumProjectType.occasionCard) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SpecialCardStudioScreen(project: album),
        ),
      );
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
    await _reload();
  }

  Future<void> _delete(AlbumModel album) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          album.projectType == AlbumProjectType.occasionCard
              ? 'Kart silinsin mi?'
              : 'Albüm silinsin mi?',
        ),
        content: Text('“${album.title}” bu cihazdan kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
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
    final horizontalInset = viewportWidth > 1244
        ? (viewportWidth - 1200) / 2 + 22
        : 22.0;
    final albumColumns = viewportWidth >= 1100
        ? 4
        : viewportWidth >= 700
        ? 3
        : 2;
    final matchingAlbums = queryAlbumLibrary(
      _albums,
      searchQuery: _searchController.text,
      filter: _libraryFilter,
      sort: _librarySort,
    );
    final visibleAlbums = matchingAlbums
        .take(_visibleAlbumCount)
        .toList(growable: false);
    final remainingAlbumCount = matchingAlbums.length - visibleAlbums.length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CraftBackdrop(
        variant: CraftBackdropVariant.cork,
        baseColor: colors.background,
        textureIntensity: .78,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    18,
                    horizontalInset,
                    10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          label:
                              'Anılarına hoş geldin. Albüm ve kartlarını kaldığın yerden düzenle.',
                          child: PaperPanel(
                            rotationDegrees: -.18,
                            borderRadius: BorderRadius.circular(14),
                            textureIntensity: .12,
                            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                            child: Row(
                              children: [
                                SizedBox.square(
                                  dimension: viewportWidth < 380 ? 48 : 56,
                                  child: Image.asset(
                                    'assets/branding/albumium_brand_mark.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ExcludeSemantics(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Anılarına hoş geldin',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: colors.text,
                                                fontSize: viewportWidth < 380
                                                    ? 17
                                                    : 20,
                                                height: 1.05,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Albüm ve kartlarını kaldığın yerden düzenle.',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.mutedText,
                                            fontSize: 10.5,
                                            height: 1.25,
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
                      ),
                      const SizedBox(width: 10),
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
                  child: _HeroPanel(onCreate: _createProject),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: Row(
                    children: [
                      TornPaperLabel(
                        rotationDegrees: -.6,
                        padding: const EdgeInsets.fromLTRB(15, 7, 15, 8),
                        child: Text(
                          'Koleksiyonum',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: colors.text, fontSize: 25),
                        ),
                      ),
                      if (_albums.isNotEmpty) ...[
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.glow,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            matchingAlbums.length == _albums.length
                                ? '${_albums.length}'
                                : '${matchingAlbums.length} / ${_albums.length}',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (_albums.isNotEmpty && viewportWidth >= 410)
                        Text(
                          'Silmek için basılı tut',
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 10.5,
                          ),
                        ),
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
                      filter: _libraryFilter,
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
                      onFilterChanged: (filter) {
                        setState(() {
                          _libraryFilter = filter;
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: albumColumns,
                      childAspectRatio: 0.61,
                      crossAxisSpacing: 17,
                      mainAxisSpacing: 23,
                    ),
                    itemCount: visibleAlbums.length,
                    itemBuilder: (context, index) {
                      final album = visibleAlbums[index];
                      return _AlbumGridItem(
                        key: ValueKey('library-item-${album.id}'),
                        album: album,
                        index: index,
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
                        label: Text('Daha fazla göster ($remainingAlbumCount)'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _albums.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _createProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni tasarım'),
            ),
    );
  }
}

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.controller,
    required this.filter,
    required this.sort,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final AlbumLibraryFilter filter;
  final AlbumLibrarySort sort;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<AlbumLibraryFilter> onFilterChanged;
  final ValueChanged<AlbumLibrarySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PaperPanel(
      rotationDegrees: .12,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(12),
      textureIntensity: .1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('library-search'),
            controller: controller,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Albüm veya kart ara',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.elevatedSurface.withValues(alpha: .64),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LibraryFilterChip(
                key: const ValueKey('library-filter-all'),
                label: 'Tümü',
                icon: Icons.grid_view_rounded,
                selected: filter == AlbumLibraryFilter.all,
                onSelected: () => onFilterChanged(AlbumLibraryFilter.all),
              ),
              _LibraryFilterChip(
                key: const ValueKey('library-filter-albums'),
                label: 'Albümler',
                icon: Icons.auto_stories_outlined,
                selected: filter == AlbumLibraryFilter.albums,
                onSelected: () => onFilterChanged(AlbumLibraryFilter.albums),
              ),
              _LibraryFilterChip(
                key: const ValueKey('library-filter-cards'),
                label: 'Kartlar',
                icon: Icons.mark_email_read_outlined,
                selected: filter == AlbumLibraryFilter.cards,
                onSelected: () => onFilterChanged(AlbumLibraryFilter.cards),
              ),
              PopupMenuButton<AlbumLibrarySort>(
                key: const ValueKey('library-sort'),
                initialValue: sort,
                tooltip: 'Koleksiyonu sırala',
                onSelected: onSortChanged,
                itemBuilder: (context) => AlbumLibrarySort.values
                    .map(
                      (value) => PopupMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            if (value == sort) ...[
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                            ] else
                              const SizedBox(width: 26),
                            Text(_librarySortLabel(value)),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.elevatedSurface.withValues(alpha: .58),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 17,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _librarySortLabel(sort),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.text,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 19,
                        color: colors.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryFilterChip extends StatelessWidget {
  const _LibraryFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
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
        child: PaperPanel(
          borderRadius: BorderRadius.circular(12),
          rotationDegrees: -.25,
          textureIntensity: .12,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: colors.primary, size: 34),
              const SizedBox(height: 10),
              Text(
                'Bu seçimde bir tasarım bulamadık',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Arama sözcüğünü ya da filtreleri değiştirebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                key: const ValueKey('library-clear-query'),
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tümünü göster'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PaperPanel(
      color: colors.heroEnd,
      rotationDegrees: .45,
      borderRadius: BorderRadius.circular(7),
      padding: EdgeInsets.zero,
      tapePositions: const [
        CraftTapePosition.topRight,
        CraftTapePosition.bottomLeft,
      ],
      tapeColor: Color.lerp(colors.secondary, colors.elevatedSurface, .55),
      tapeWidth: 55,
      tapeHeight: 17,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 190),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 12,
              bottom: 12,
              width: 92,
              child: _MemoryScraps(colors: colors),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 21, 104, 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün hangi\nhikâyeyi anlatalım?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Fotoğraflarını, notlarını ve küçük hatıralarını kendi albümünde bir araya getir.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 13),
                  StitchedBorder(
                    color: colors.onPrimary.withValues(alpha: .78),
                    inset: 3,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(9),
                    child: FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Yeni tasarım'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryScraps extends StatelessWidget {
  const _MemoryScraps({required this.colors});

  final AlbumiumThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 10,
          top: 17,
          child: Transform.rotate(
            angle: -.12,
            child: Container(
              width: 62,
              height: 80,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
              decoration: BoxDecoration(
                color: colors.elevatedSurface,
                border: Border.all(color: colors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(3, 5),
                  ),
                ],
              ),
              child: ColoredBox(
                color: colors.primary.withValues(alpha: .17),
                child: Icon(
                  Icons.photo_camera_back_outlined,
                  color: colors.primary,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 7,
          child: Transform.rotate(
            angle: .10,
            child: TornPaperLabel(
              color: Color.lerp(colors.surface, colors.secondary, .12),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              edgeDepth: 2.3,
              child: Text(
                'anı\ndefteri',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontSize: 18,
                  height: .86,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 0,
          child: Icon(
            Icons.push_pin_rounded,
            color: colors.primary,
            size: 23,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({required this.controller, required this.onTap});

  final ThemeController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final option = controller.selectedOption;
    return Tooltip(
      message: 'Uygulama temasını değiştir',
      child: PaperPanel(
        rotationDegrees: .9,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(9),
        textureIntensity: .18,
        child: IconButton(
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.palette_outlined),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: option.previewColors.first,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumGridItem extends StatelessWidget {
  const _AlbumGridItem({
    super.key,
    required this.album,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  final AlbumModel album;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final isCard = album.projectType == AlbumProjectType.occasionCard;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 460 + (index.clamp(0, 5) * 75)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 22),
            child: Transform.scale(scale: 0.94 + value * 0.06, child: child),
          ),
        );
      },
      child: PaperPanel(
        rotationDegrees: index.isEven ? -.8 : .75,
        borderRadius: BorderRadius.circular(5),
        padding: const EdgeInsets.fromLTRB(8, 13, 8, 9),
        tapePositions: const [CraftTapePosition.topCenter],
        tapeWidth: 44,
        tapeHeight: 14,
        textureIntensity: .2,
        child: Semantics(
          button: true,
          label: isCard
              ? '${album.title}, özel gün kartı'
              : '${album.title}, ${album.pages.length} sayfa',
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 3, bottom: 2),
                    child: isCard
                        ? _SpecialCardThumbnail(project: album)
                        : AlbumCover3D(album: album, compact: true),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.text,
                    fontSize: 19,
                    height: .95,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCard
                      ? 'Özel gün kartı · ${occasionTemplateById(album.cardThemeId).badge}'
                      : '${album.pages.length} sayfa · ${album.bindingType.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.mutedText, fontSize: 9.5),
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
        child: PaperPanel(
          rotationDegrees: -.65,
          borderRadius: BorderRadius.circular(6),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 17),
          tapePositions: const [
            CraftTapePosition.topLeft,
            CraftTapePosition.bottomRight,
          ],
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
                'İlk tasarımın burada yaşayacak',
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
                label: const Text('Tasarım oluştur'),
              ),
              const StitchedDivider(height: 12),
              Text(
                'Gerçek bir albüm oluştur veya temalı bir özel gün kartı tasarla.',
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

class _CreationPickerSheet extends StatelessWidget {
  const _CreationPickerSheet();

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TornPaperLabel(
                rotationDegrees: -.45,
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
                child: Text(
                  'Ne tasarlamak istersin?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Her iki tasarım da kaydedilir; fotoğraf, yazı, süs ve şekillerle kişiselleştirilebilir.',
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
              const SizedBox(height: 17),
              if (tablet)
                Row(
                  children: [
                    Expanded(
                      child: _CreationChoice(
                        icon: Icons.auto_stories_rounded,
                        title: 'Fiziksel Albüm',
                        subtitle: 'Kapak, cilt ve gerçekçi çevrilen sayfalar',
                        colors: [colors.primary, colors.secondary],
                        onTap: () =>
                            Navigator.pop(context, _CreationKind.album),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CreationChoice(
                        icon: Icons.mark_email_read_rounded,
                        title: 'Özel Gün Kartı',
                        subtitle: 'Tema seç, özgürce tasarla ve PNG paylaş',
                        colors: const [Color(0xFFE9A4B5), Color(0xFF9C5270)],
                        onTap: () =>
                            Navigator.pop(context, _CreationKind.occasionCard),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _CreationChoice(
                      icon: Icons.auto_stories_rounded,
                      title: 'Fiziksel Albüm',
                      subtitle: 'Kapak, cilt ve gerçekçi çevrilen sayfalar',
                      colors: [colors.primary, colors.secondary],
                      onTap: () => Navigator.pop(context, _CreationKind.album),
                    ),
                    const SizedBox(height: 11),
                    _CreationChoice(
                      icon: Icons.mark_email_read_rounded,
                      title: 'Özel Gün Kartı',
                      subtitle: 'Tema seç, özgürce tasarla ve PNG paylaş',
                      colors: const [Color(0xFFE9A4B5), Color(0xFF9C5270)],
                      onTap: () =>
                          Navigator.pop(context, _CreationKind.occasionCard),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationChoice extends StatelessWidget {
  const _CreationChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      borderRadius: BorderRadius.circular(7),
      padding: EdgeInsets.zero,
      rotationDegrees: title == 'Fiziksel Albüm' ? -.35 : .35,
      tapePositions: const [CraftTapePosition.topRight],
      tapeColor: Color.lerp(colors.first, Colors.white, .52),
      tapeWidth: 45,
      tapeHeight: 14,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.first.withValues(alpha: .52),
                    ),
                  ),
                  child: Icon(icon, color: colors.first, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11.5, height: 1.25),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.first,
                  size: 16,
                ),
              ],
            ),
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
    if (project.pages.isEmpty) {
      return OccasionCardView(cardId: template.id);
    }
    return Center(
      child: AspectRatio(
        aspectRatio: 5 / 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(7, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IgnorePointer(
              child: AlbumPageCanvas(
                page: project.pages.first,
                theme: specialCardThemeFor(template),
                showPageNumber: false,
              ),
            ),
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
    _enteringEditor = true;
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => EditorScreen(album: widget.album),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.018, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Scaffold(
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
                        tooltip: 'Kapat',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _enterEditor,
                        child: const Text('Geç'),
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
                            'Hikâyen açılıyor',
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
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../services/cover_entitlements.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/cover_purchase_sheet.dart';
import '../widgets/handmade_craft.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key, this.initialCategory, this.entitlements});

  /// Opens the picker filtered to one category. Null shows every cover.
  final AlbumThemeCategory? initialCategory;

  /// Which covers are unlocked. A screen opened without one runs its own,
  /// so tests and deep links can pump this screen bare.
  final CoverEntitlements? entitlements;

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  static const _phoneViewportFraction = 0.70;
  static const _tabletViewportFraction = 0.42;
  static const _bindingCardWidth = 146.0;
  static const _bindingCardGap = 10.0;

  // The carousel is filtered, so a position in it is meaningless on its own.
  // Keeping the chosen cover by id survives category changes.
  late String _selectedThemeId;
  AlbumThemeCategory? _category;
  AlbumBindingType _selectedBinding = AlbumBindingType.spiral;
  final _titleController = TextEditingController();
  PageController? _pageController;

  List<AlbumThemePreset> get _visibleThemes => themesInCategory(_category);

  AlbumThemePreset get _selectedTheme => themeById(_selectedThemeId);

  int get _selectedIndex {
    final index = _visibleThemes.indexWhere(
      (theme) => theme.id == _selectedThemeId,
    );
    return index < 0 ? 0 : index;
  }

  late final CoverEntitlements _entitlements;
  late final bool _ownsEntitlements;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _selectedThemeId = _visibleThemes.first.id;
    _ownsEntitlements = widget.entitlements == null;
    _entitlements = widget.entitlements ?? CoverEntitlements();
    // A purchase can land from the sheet or from another screen, so follow the
    // service rather than assuming this screen caused the change.
    _entitlements.addListener(_onEntitlementsChanged);
    if (_ownsEntitlements) unawaited(_entitlements.initialize());
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final viewportFraction = tablet
        ? _tabletViewportFraction
        : _phoneViewportFraction;
    final currentController = _pageController;
    if (currentController?.viewportFraction == viewportFraction) return;
    _rebuildPageController(viewportFraction: viewportFraction);
  }

  void _rebuildPageController({double? viewportFraction}) {
    final currentController = _pageController;
    final fraction =
        viewportFraction ??
        currentController?.viewportFraction ??
        _phoneViewportFraction;
    _pageController = PageController(
      initialPage: _selectedIndex,
      keepPage: false,
      viewportFraction: fraction,
    );
    if (currentController == null) return;

    // The previous controller can still be attached to this frame's PageView.
    // Dispose it after the rebuilt carousel has adopted the replacement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentController.dispose();
    });
  }

  void _selectCategory(AlbumThemeCategory? category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      final visible = _visibleThemes;
      // Keep the chosen cover when it is still on screen; otherwise start at
      // the top of the new category.
      if (!visible.any((theme) => theme.id == _selectedThemeId)) {
        _selectedThemeId = visible.first.id;
      }
      // Rebuilding beats animateToPage here: the item count changes in the
      // same frame, and it also cancels a fling that is still in flight.
      _rebuildPageController();
    });
  }

  void _onEntitlementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entitlements.removeListener(_onEntitlementsChanged);
    if (_ownsEntitlements) _entitlements.dispose();
    _pageController?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _openPurchaseSheet() async {
    final theme = _selectedTheme;
    final unlocked = await showCoverPurchaseSheet(
      context,
      theme: theme,
      entitlements: _entitlements,
    );
    if (!unlocked || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            '{theme} kapağı açıldı.',
            values: {'theme': context.tr(theme.name)},
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final theme = _selectedTheme;
    final now = DateTime.now();
    final album = AlbumModel(
      id: newId(),
      title: _titleController.text.trim().isEmpty
          ? context.tr('Benim Albümüm')
          : _titleController.text.trim(),
      themeId: theme.id,
      bindingType: _selectedBinding,
      createdAt: now,
      updatedAt: now,
      pages: [
        AlbumPageModel(
          id: newId(),
          backgroundColor: theme.pageColor.toARGB32(),
        ),
      ],
    );
    await AlbumStorage.instance.saveAlbum(album);
    if (mounted) Navigator.pop(context, album);
  }

  Widget _buildThemedCover(AlbumThemePreset theme, String title) {
    final displayTitle = title.isEmpty ? theme.name : title;
    final previewDate = DateTime(2026);
    final previewAlbum = AlbumModel(
      id: 'preview-${theme.id}',
      title: displayTitle,
      themeId: theme.id,
      bindingType: _selectedBinding,
      createdAt: previewDate,
      updatedAt: previewDate,
      pages: [
        AlbumPageModel(
          id: 'preview-page-${theme.id}',
          backgroundColor: theme.pageColor.toARGB32(),
        ),
      ],
    );

    final colors = AlbumiumAppTheme.colorsOf(context);
    final locked = !_entitlements.isUnlockedTheme(theme);

    return Center(
      child: AspectRatio(
        aspectRatio: 15 / 22,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AlbumCover3D(album: previewAlbum),
              ),
            ),
            // The artwork stays fully visible: a locked cover should still be
            // worth wanting. Only the badge says it has to be unlocked.
            if (locked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  key: ValueKey('theme-lock-badge-${theme.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 13, color: colors.primary),
                      const SizedBox(width: 5),
                      Text(
                        _entitlements.priceLabelFor(theme.id),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
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

  Widget _buildCategoryStrip(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);

    Widget chip({
      required Key key,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: key,
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? colors.onPrimary : colors.text,
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        selectedColor: colors.primary,
        backgroundColor: colors.surface,
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );

    return SizedBox(
      height: 40,
      child: ListView(
        key: const ValueKey('theme-category-strip'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          chip(
            key: const ValueKey('theme-category-all'),
            label: context.tr('Tümü'),
            selected: _category == null,
            onTap: () => _selectCategory(null),
          ),
          for (final category in AlbumThemeCategory.values)
            chip(
              key: ValueKey('theme-category-${category.name}'),
              label: context.tr(category.label),
              selected: _category == category,
              onTap: () => _selectCategory(category),
            ),
        ],
      ),
    );
  }

  Widget _buildBindingSelector(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);

    return SizedBox(
      height: 118,
      child: ListView.separated(
        key: const ValueKey('binding-selector'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 5, 24, 7),
        itemCount: AlbumBindingType.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: _bindingCardGap),
        itemBuilder: (context, index) {
          final binding = AlbumBindingType.values[index];
          final selected = binding == _selectedBinding;

          return Semantics(
            key: ValueKey('binding-card-${binding.name}'),
            button: true,
            selected: selected,
            label: context.tr(binding.title),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _selectedBinding = binding),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: _bindingCardWidth,
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: .10)
                      : colors.surface.withValues(alpha: .70),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? colors.primary
                        : colors.border.withValues(alpha: .70),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: .16),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? colors.primary
                                : colors.primary.withValues(alpha: .12),
                          ),
                          child: Icon(
                            binding.icon,
                            size: 15,
                            color: selected ? colors.onPrimary : colors.primary,
                          ),
                        ),
                        const Spacer(),
                        AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          scale: selected ? 1 : 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(binding.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        context.tr(binding.description),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.32,
                          color: colors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final mediaSize = MediaQuery.sizeOf(context);
    final tablet = mediaSize.shortestSide >= 600;
    // The cover takes whatever height is left, up to these caps, so the whole
    // setup fits on one screen. Below the minimum layout height (a short
    // phone with the keyboard open) the page scrolls instead of overflowing.
    final maxCover = tablet ? 380.0 : 280.0;
    const minLayoutHeight = 620.0;
    final currentTitle = _titleController.text.trim();
    final selectedTheme = _selectedTheme;
    final visibleThemes = _visibleThemes;
    final selectedLocked = !_entitlements.isUnlockedTheme(selectedTheme);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(context.tr('Albümünü Hazırla')),
        backgroundColor: colors.background,
      ),
      body: CraftBackdrop(
        variant: CraftBackdropVariant.studio,
        baseColor: colors.background,
        textureIntensity: .62,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tablet ? 820 : double.infinity,
              ),
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  child: SizedBox(
                    height: viewport.maxHeight < minLayoutHeight
                        ? minLayoutHeight
                        : viewport.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
                          child: Text(
                            context.tr('Hangi hikâyeyi anlatıyoruz?'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontSize: tablet ? 38 : 32,
                                  height: 1.12,
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '${context.tr(selectedTheme.name)} · ${context.tr(selectedTheme.subtitle)}'
                            ' · ${_selectedIndex + 1}/${visibleThemes.length}',
                            key: const ValueKey('selected-theme-summary'),
                            style: TextStyle(
                              color: colors.mutedText,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (selectedLocked)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                            child: Text(
                              context.tr(
                                'Kilitli · {price}',
                                values: {
                                  'price': _entitlements.priceLabelFor(
                                    selectedTheme.id,
                                  ),
                                },
                              ),
                              key: const ValueKey('theme-lock-note'),
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _buildCategoryStrip(context),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, space) => Center(
                              child: SizedBox(
                                height: space.maxHeight < maxCover
                                    ? space.maxHeight
                                    : maxCover,
                                child: PageView.builder(
                                  key: const ValueKey('theme-carousel'),
                                  controller: _pageController,
                                  itemCount: visibleThemes.length,
                                  onPageChanged: (index) => setState(
                                    () => _selectedThemeId =
                                        visibleThemes[index].id,
                                  ),
                                  itemBuilder: (context, index) {
                                    final theme = visibleThemes[index];
                                    final selected = index == _selectedIndex;
                                    return AnimatedPadding(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: selected ? 0 : 14,
                                      ),
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        scale: selected ? 1 : 0.94,
                                        child: _buildThemedCover(
                                          theme,
                                          currentTitle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            context.tr('Ciltleme Türü'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBindingSelector(context),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
                          child: TextField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: context.tr('Albüm adı (isteğe bağlı)'),
                              hintText: context.tr('Örn. Bizim Yazımız'),
                              prefixIcon: const Icon(Icons.edit_outlined),
                              suffixText: selectedTheme.emoji,
                              suffixStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                              key: const ValueKey('theme-primary-action'),
                              onPressed: selectedLocked
                                  ? _openPurchaseSheet
                                  : _continue,
                              icon: Icon(
                                selectedLocked
                                    ? Icons.lock_open_rounded
                                    : Icons.auto_stories_rounded,
                              ),
                              label: Text(
                                selectedLocked
                                    ? context.tr(
                                        '{price} · Kapağı aç',
                                        values: {
                                          'price': _entitlements.priceLabelFor(
                                            selectedTheme.id,
                                          ),
                                        },
                                      )
                                    : context.tr(
                                        '{theme} ile Başla',
                                        values: {
                                          'theme': context.tr(
                                            selectedTheme.name,
                                          ),
                                        },
                                      ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

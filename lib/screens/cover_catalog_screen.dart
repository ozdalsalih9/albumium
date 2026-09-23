import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_library_query.dart';
import '../models/album_models.dart';
import '../services/cover_entitlements.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/cover_purchase_sheet.dart';
import '../widgets/handmade_craft.dart';

/// How the catalogue orders its covers. The free ones lead by default, so a
/// newcomer meets what they can use straight away; the enum order is also the
/// order of the menu.
enum CoverCatalogSort { freeFirst, paidFirst, alphabetical }

String _sortLabel(CoverCatalogSort sort) => switch (sort) {
  CoverCatalogSort.freeFirst => 'Önce ücretsiz',
  CoverCatalogSort.paidFirst => 'Önce ücretli',
  CoverCatalogSort.alphabetical => 'Alfabetik',
};

/// What the shelf says about a cover: its price, or how it came to be open.
///
/// A cover that was paid for must not read "Ücretsiz" after a reinstall — the
/// user would think their purchase had been handed to everyone.
String coverStatusLabel(
  BuildContext context, {
  required AlbumThemePreset theme,
  required bool locked,
  String? priceLabel,
}) {
  if (locked) return priceLabel ?? theme.price.label ?? '';
  return context.tr(theme.isPremium ? 'Satın alındı' : 'Ücretsiz');
}

/// A preview album so a cover can be drawn on its own, outside any album.
AlbumModel coverPreviewAlbum(AlbumThemePreset theme) {
  final date = DateTime(2026);
  return AlbumModel(
    id: 'catalog-${theme.id}',
    title: theme.name,
    themeId: theme.id,
    createdAt: date,
    updatedAt: date,
    pages: [
      AlbumPageModel(
        id: 'catalog-page-${theme.id}',
        backgroundColor: theme.pageColor.toARGB32(),
      ),
    ],
  );
}

/// Browsable shelf of every cover, grouped by category.
///
/// This is the shop window; picking a cover opens its page, and starting an
/// album from there goes through the usual setup screen.
class CoverCatalogScreen extends StatefulWidget {
  const CoverCatalogScreen({
    super.key,
    required this.onStartAlbum,
    this.entitlements,
  });

  /// Opens the album setup screen on the chosen cover.
  final Future<void> Function(String themeId) onStartAlbum;
  final CoverEntitlements? entitlements;

  @override
  State<CoverCatalogScreen> createState() => _CoverCatalogScreenState();
}

class _CoverCatalogScreenState extends State<CoverCatalogScreen> {
  AlbumThemeCategory? _category;
  CoverCatalogSort _sort = CoverCatalogSort.freeFirst;
  final _searchController = TextEditingController();

  late final CoverEntitlements _entitlements;
  late final bool _ownsEntitlements;

  @override
  void initState() {
    super.initState();
    _ownsEntitlements = widget.entitlements == null;
    _entitlements = widget.entitlements ?? CoverEntitlements();
    if (_ownsEntitlements) _entitlements.initialize();
    _entitlements.addListener(_onEntitlementsChanged);
    _searchController.addListener(() => setState(() {}));
  }

  void _onEntitlementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entitlements.removeListener(_onEntitlementsChanged);
    if (_ownsEntitlements) _entitlements.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AlbumThemePreset> get _covers {
    final query = _searchController.text.trim().toLowerCase();
    final covers = themesInCategory(_category).where((theme) {
      if (query.isEmpty) return true;
      return theme.name.toLowerCase().contains(query) ||
          theme.subtitle.toLowerCase().contains(query);
    }).toList();

    // Names are Turkish, so İstanbul belongs next to Izmir rather than after
    // Trabzon, which is where a plain code-unit comparison puts it.
    int byName(AlbumThemePreset a, AlbumThemePreset b) =>
        compareTurkishTitles(a.name, b.name);

    switch (_sort) {
      case CoverCatalogSort.freeFirst:
        // CoverPrice is declared free, then cheap, then dear, so its index is
        // already the order a shopper reads prices in.
        covers.sort((a, b) {
          final byPrice = a.price.index.compareTo(b.price.index);
          return byPrice != 0 ? byPrice : byName(a, b);
        });
      case CoverCatalogSort.paidFirst:
        // Dearest first, so the richest covers open the shelf.
        covers.sort((a, b) {
          final byPrice = b.price.index.compareTo(a.price.index);
          return byPrice != 0 ? byPrice : byName(a, b);
        });
      case CoverCatalogSort.alphabetical:
        covers.sort(byName);
    }
    return covers;
  }

  Future<void> _openCover(AlbumThemePreset theme) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoverDetailScreen(
          theme: theme,
          entitlements: _entitlements,
          onStartAlbum: widget.onStartAlbum,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final covers = _covers;

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            key: const ValueKey('catalog-category-strip'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              _CategoryChip(
                key: const ValueKey('catalog-category-all'),
                label: context.tr('Tümü'),
                dotColor: colors.primary,
                selected: _category == null,
                onTap: () => setState(() => _category = null),
              ),
              for (final category in AlbumThemeCategory.values)
                _CategoryChip(
                  key: ValueKey('catalog-category-${category.name}'),
                  label: context.tr(category.label),
                  dotColor:
                      themesInCategory(category).firstOrNull?.accent ??
                      colors.primary,
                  selected: _category == category,
                  onTap: () => setState(() => _category = category),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('catalog-search'),
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.tr('Kapak ara'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<CoverCatalogSort>(
                key: const ValueKey('catalog-sort'),
                initialValue: _sort,
                tooltip: context.tr('Sırala'),
                icon: const Icon(Icons.sort_rounded),
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (context) => CoverCatalogSort.values
                    .map(
                      (value) => CheckedPopupMenuItem(
                        value: value,
                        checked: value == _sort,
                        child: Text(context.tr(_sortLabel(value))),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: covers.isEmpty
              ? Center(
                  key: const ValueKey('catalog-empty'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.tr('Aramanla eşleşen kapak yok'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.mutedText),
                    ),
                  ),
                )
              : GridView.builder(
                  key: const ValueKey('catalog-grid'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: .58,
                  ),
                  itemCount: covers.length,
                  itemBuilder: (context, index) {
                    final theme = covers[index];
                    return _CoverTile(
                      theme: theme,
                      locked: !_entitlements.isUnlockedTheme(theme),
                      priceLabel: _entitlements.priceLabelFor(theme.id),
                      onTap: () => _openCover(theme),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: CircleAvatar(backgroundColor: dotColor, radius: 5),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? colors.onPrimary : colors.text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        selectedColor: colors.primary,
        backgroundColor: colors.surface,
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.theme,
    required this.locked,
    required this.priceLabel,
    required this.onTap,
  });

  final AlbumThemePreset theme;
  final bool locked;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);

    return Column(
      key: ValueKey('catalog-cover-${theme.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 15 / 22,
                    child: AlbumCover3D(
                      album: coverPreviewAlbum(theme),
                      compact: true,
                      perspective: false,
                      showTitle: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(theme.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                coverStatusLabel(context, theme: theme, locked: locked),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: locked ? colors.text : colors.primary,
                ),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: Material(
                color: colors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One cover, shown large, with the rest of its category underneath.
class CoverDetailScreen extends StatefulWidget {
  const CoverDetailScreen({
    super.key,
    required this.theme,
    required this.entitlements,
    required this.onStartAlbum,
  });

  final AlbumThemePreset theme;
  final CoverEntitlements entitlements;
  final Future<void> Function(String themeId) onStartAlbum;

  @override
  State<CoverDetailScreen> createState() => _CoverDetailScreenState();
}

class _CoverDetailScreenState extends State<CoverDetailScreen> {
  late AlbumThemePreset _theme = widget.theme;

  @override
  void initState() {
    super.initState();
    widget.entitlements.addListener(_onEntitlementsChanged);
  }

  void _onEntitlementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.entitlements.removeListener(_onEntitlementsChanged);
    super.dispose();
  }

  Future<void> _unlock() async {
    final unlocked = await showCoverPurchaseSheet(
      context,
      theme: _theme,
      entitlements: widget.entitlements,
    );
    if (!unlocked || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            '{theme} kapağı açıldı.',
            values: {'theme': context.tr(_theme.name)},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final locked = !widget.entitlements.isUnlockedTheme(_theme);
    final siblings = themesInCategory(_theme.category);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(context.tr(_theme.name)),
        backgroundColor: colors.background,
      ),
      body: CraftBackdrop(
        variant: CraftBackdropVariant.studio,
        baseColor: colors.background,
        textureIntensity: .62,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('Temalar')} · ${context.tr(_theme.category.label)}',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 420),
                          child: AspectRatio(
                            aspectRatio: 15 / 22,
                            child: AlbumCover3D(
                              key: ValueKey('cover-detail-${_theme.id}'),
                              album: coverPreviewAlbum(_theme),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (siblings.length > 1)
                        SizedBox(
                          height: 86,
                          child: ListView.separated(
                            key: const ValueKey('cover-detail-siblings'),
                            scrollDirection: Axis.horizontal,
                            itemCount: siblings.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final sibling = siblings[index];
                              final selected = sibling.id == _theme.id;
                              return GestureDetector(
                                key: ValueKey('cover-thumb-${sibling.id}'),
                                onTap: () => setState(() => _theme = sibling),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? colors.primary
                                          : colors.border,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 15 / 22,
                                    child: AlbumCover3D(
                                      album: coverPreviewAlbum(sibling),
                                      compact: true,
                                      perspective: false,
                                      showTitle: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr(_theme.subtitle),
                        style: TextStyle(color: colors.mutedText, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.elevatedSurface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('Albüm kapağı'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.mutedText,
                            ),
                          ),
                          Text(
                            coverStatusLabel(
                              context,
                              theme: _theme,
                              locked: locked,
                              priceLabel: widget.entitlements.priceLabelFor(
                                _theme.id,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('cover-detail-action'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: locked
                              ? _unlock
                              : () => widget.onStartAlbum(_theme.id),
                          icon: Icon(
                            locked
                                ? Icons.lock_open_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(
                            locked
                                ? context.tr('Kapağı aç')
                                : context.tr('Hikâyeni Başlat'),
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
      ),
    );
  }
}

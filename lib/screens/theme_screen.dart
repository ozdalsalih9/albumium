import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/handmade_craft.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  static const _phoneViewportFraction = 0.70;
  static const _tabletViewportFraction = 0.42;

  int _selected = 0;
  AlbumBindingType _selectedBinding = AlbumBindingType.spiral;
  final _titleController = TextEditingController();
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
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

    _pageController = PageController(
      initialPage: _selected,
      keepPage: false,
      viewportFraction: viewportFraction,
    );
    if (currentController == null) return;

    // The previous controller can still be attached to this frame's PageView.
    // Dispose it after the rebuilt carousel has adopted the replacement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentController.dispose();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final theme = albumThemes[_selected];
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

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 300,
        height: 440,
        child: AlbumCover3D(album: previewAlbum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final mediaSize = MediaQuery.sizeOf(context);
    final tablet = mediaSize.shortestSide >= 600;
    final compact = mediaSize.height < 740 && !tablet;
    final coverHeight = tablet
        ? (mediaSize.height * 0.46).clamp(300.0, 380.0)
        : compact
        ? 220.0
        : 280.0;
    final currentTitle = _titleController.text.trim();
    final selectedTheme = albumThemes[_selected];

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
                maxWidth: tablet ? 1040 : double.infinity,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(22, 6, 22, 2),
                      child: TornPaperLabel(
                        rotationDegrees: -.45,
                        color: colors.elevatedSurface,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
                        child: Text(
                          context.tr('Hangi hikâyeyi anlatıyoruz?'),
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 30),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        '${context.tr(selectedTheme.name)} · ${context.tr(selectedTheme.subtitle)}',
                        key: const ValueKey('selected-theme-summary'),
                        style: TextStyle(
                          color: colors.text.withValues(alpha: .82),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: coverHeight,
                      child: PageView.builder(
                        key: const ValueKey('theme-carousel'),
                        controller: _pageController,
                        itemCount: albumThemes.length,
                        onPageChanged: (index) =>
                            setState(() => _selected = index),
                        itemBuilder: (context, index) {
                          final theme = albumThemes[index];
                          final selected = index == _selected;
                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 220),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: selected ? 0 : 14,
                            ),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 220),
                              scale: selected ? 1 : 0.94,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: _buildThemedCover(theme, currentTitle),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < albumThemes.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _selected ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _selected
                                    ? selectedTheme.accent
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const StitchedDivider(
                      height: 20,
                      indent: 22,
                      endIndent: 22,
                    ),
                    // Ciltleme Seçenekleri (Binding Styles)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: TornPaperLabel(
                        rotationDegrees: .35,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          context.tr('Ciltleme Türü'),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        scrollDirection: Axis.horizontal,
                        itemCount: AlbumBindingType.values.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final binding = AlbumBindingType.values[index];
                          final isSelected = _selectedBinding == binding;
                          return ChoiceChip(
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedBinding = binding),
                            avatar: Icon(
                              binding.icon,
                              size: 16,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            label: Text(context.tr(binding.title)),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
                      child: PaperPanel(
                        borderRadius: BorderRadius.circular(7),
                        padding: const EdgeInsets.all(5),
                        rotationDegrees: -.2,
                        tapePositions: const [CraftTapePosition.topRight],
                        tapeWidth: 42,
                        tapeHeight: 13,
                        child: TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: context.tr('Albüm adı (isteğe bağlı)'),
                            hintText: context.tr('Örn. Bizim Yazımız'),
                            prefixIcon: const Icon(Icons.edit_outlined),
                            suffixText: selectedTheme.emoji,
                            suffixStyle: const TextStyle(fontSize: 18),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                      child: StitchedBorder(
                        color: colors.onPrimary.withValues(alpha: .78),
                        inset: 3,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _continue,
                            icon: const Icon(Icons.auto_stories_rounded),
                            label: Text(
                              context.tr(
                                '{theme} ile Başla',
                                values: {
                                  'theme': context.tr(selectedTheme.name),
                                },
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
          ),
        ),
      ),
    );
  }
}

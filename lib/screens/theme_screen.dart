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
  static const _bindingCardWidth = 156.0;
  static const _bindingCardGap = 10.0;

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

    return Center(
      child: AspectRatio(
        aspectRatio: 15 / 22,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AlbumCover3D(album: previewAlbum),
        ),
      ),
    );
  }

  Widget _buildBindingSelector(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);

    return SizedBox(
      height: 130,
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
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? colors.primary
                                : colors.primary.withValues(alpha: .12),
                          ),
                          child: Icon(
                            binding.icon,
                            size: 17,
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
                    const SizedBox(height: 11),
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
                maxWidth: tablet ? 820 : double.infinity,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
                        '${context.tr(selectedTheme.name)} · ${context.tr(selectedTheme.subtitle)}',
                        key: const ValueKey('selected-theme-summary'),
                        style: TextStyle(
                          color: colors.mutedText,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
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
                              child: _buildThemedCover(theme, currentTitle),
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
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        context.tr('Ciltleme Türü'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBindingSelector(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
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
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 17,
                            ),
                          ),
                          onPressed: _continue,
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: Text(
                            context.tr(
                              '{theme} ile Başla',
                              values: {'theme': context.tr(selectedTheme.name)},
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
    );
  }
}

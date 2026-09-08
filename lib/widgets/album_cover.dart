import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../themes/album_themes.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    required this.album,
    this.compact = false,
    this.showTitle = true,
    this.onTap,
  });

  final AlbumModel album;
  final bool compact;
  final bool showTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = album.title.trim().isEmpty
        ? context.tr('İsimsiz Albüm')
        : album.title.trim();
    final visualTitle = showTitle ? title : '';
    final theme = themeById(album.themeId);
    final subtitle = context.tr(theme.subtitle);

    final Widget coverWidget = album.coverPhotoPath != null
        ? GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(album.coverPhotoPath!),
                    fit: BoxFit.cover,
                    cacheWidth: compact ? 600 : 1200,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: theme.coverStart),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                  if (showTitle)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          visualTitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        : theme.coverAsset != null
        ? _OrnateAssetCover(
            assetPath: theme.coverAsset!,
            title: visualTitle,
            semanticTitle: title,
            theme: theme,
            cacheWidth: compact ? 600 : themeImageCacheWidth,
            onTap: onTap,
          )
        : switch (album.themeId) {
            'animals' => AnimalsCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'soft_romance' => SoftRomanceCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'vintage_diary' => VintageDiaryCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'travel_postcard' => TravelPostcardCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'best_friends' => BestFriendsCover(
              title: visualTitle,
              subtitle: subtitle,
              emoji: theme.emoji,
              onTap: onTap,
            ),
            'minimal_editorial' => MinimalEditorialCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'dark_leather' => DarkLeatherCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
            _ => SoftRomanceCover(
              title: visualTitle,
              subtitle: subtitle,
              onTap: onTap,
            ),
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 16 : 14),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(width: 300, height: 440, child: coverWidget),
            ),
          ),
        );
      },
    );
  }
}

/// Uses the generated cover art as a material texture, then draws all variable
/// text in Flutter so album names stay crisp, localisable and accessible.
class _OrnateAssetCover extends StatelessWidget {
  const _OrnateAssetCover({
    required this.assetPath,
    required this.title,
    required this.semanticTitle,
    required this.theme,
    required this.cacheWidth,
    this.onTap,
  });

  final String assetPath;
  final String title;
  final String semanticTitle;
  final AlbumThemePreset theme;
  final int cacheWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gold = Color.lerp(theme.accent, const Color(0xFFFFE4A8), 0.38)!;
    return Semantics(
      button: onTap != null,
      label: context.tr('{title} albümü', values: {'title': semanticTitle}),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 300,
            height: 440,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.coverStart, theme.coverEnd],
                    ),
                  ),
                ),
                Image.asset(
                  assetPath,
                  fit: BoxFit.fill,
                  filterQuality: cacheWidth < themeImageCacheWidth
                      ? FilterQuality.medium
                      : FilterQuality.high,
                  cacheWidth: cacheWidth,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const _CoverMaterialLighting(),
                if (title.isNotEmpty)
                  Positioned(
                    left: 46,
                    right: 26,
                    bottom: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          theme.coverEnd,
                          Colors.black,
                          0.48,
                        )!.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.85),
                          width: 1.1,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x88000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                          BoxShadow(
                            color: gold.withValues(alpha: 0.20),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ALBUMIUM',
                              style: TextStyle(
                                color: gold.withValues(alpha: 0.84),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 0.7,
                              color: gold.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFFFF4DD),
                                  fontFamily: 'serif',
                                  fontSize: title.length > 18 ? 16 : 21,
                                  height: 1.05,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xCC000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 0.7,
                              color: gold.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              theme.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: gold.withValues(alpha: 0.78),
                                fontSize: 6.8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.13),
                          width: 0.8,
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
    );
  }
}

class _CoverMaterialLighting extends StatelessWidget {
  const _CoverMaterialLighting();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1.1, -1),
            end: Alignment(.55, 1),
            colors: [
              Colors.transparent,
              Color(0x08FFFFFF),
              Color(0x1AFFFFFF),
              Color(0x05000000),
              Colors.transparent,
            ],
            stops: [0, 0.39, 0.48, 0.57, 1],
          ),
        ),
      ),
    );
  }
}

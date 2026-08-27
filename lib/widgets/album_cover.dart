import 'package:flutter/material.dart';

import '../models/album_models.dart';
import '../themes/album_themes.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    required this.album,
    this.compact = false,
    this.onTap,
  });

  final AlbumModel album;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = album.title.trim().isEmpty
        ? 'İsimsiz Albüm'
        : album.title.trim();
    final theme = themeById(album.themeId);
    final subtitle = theme.subtitle;

    final Widget coverWidget = theme.coverAsset != null
        ? _OrnateAssetCover(
            assetPath: theme.coverAsset!,
            title: title,
            theme: theme,
            onTap: onTap,
          )
        : switch (album.themeId) {
            'animals' => AnimalsCover(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'soft_romance' => SoftRomanceCover(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'vintage_diary' => VintageDiaryCover(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'travel_postcard' => TravelPostcardCover(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'best_friends' => BestFriendsCover(
              title: title,
              subtitle: subtitle,
              emoji: theme.emoji,
              onTap: onTap,
            ),
            'minimal_editorial' => MinimalEditorialCover(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
            'dark_leather' => DarkLeatherCover(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
            _ => SoftRomanceCover(
              title: title,
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
    required this.theme,
    this.onTap,
  });

  final String assetPath;
  final String title;
  final AlbumThemePreset theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gold = Color.lerp(theme.accent, const Color(0xFFFFE4A8), 0.38)!;
    return Semantics(
      button: onTap != null,
      label: '$title albümü',
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
                  filterQuality: FilterQuality.high,
                  cacheWidth: themeImageCacheWidth,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const _CoverMaterialLighting(),
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
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -1.25, end: 1.25),
        duration: const Duration(milliseconds: 2600),
        curve: Curves.easeInOutCubic,
        builder: (context, value, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(value - 0.7, -1),
                end: Alignment(value + 0.7, 1),
                colors: const [
                  Colors.transparent,
                  Color(0x0AFFFFFF),
                  Color(0x26FFFFFF),
                  Color(0x06000000),
                  Colors.transparent,
                ],
                stops: const [0, 0.39, 0.48, 0.57, 1],
              ),
            ),
          );
        },
      ),
    );
  }
}

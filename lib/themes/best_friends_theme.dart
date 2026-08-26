import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// BEST FRIENDS — mor enerji, konfeti noktaları, tombul fontlar.
/// Kahkaha dolu, renkli, utanmazca neşeli.
/// ─────────────────────────────────────────────────────────────

class BestFriendsPalette {
  static const Color lilac = Color(0xFFF3EEFA);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color deepViolet = Color(0xFF6D3FD1);
  static const Color sunshine = Color(0xFFFFC94D);
  static const Color coral = Color(0xFFFF7A85);
  static const Color ink = Color(0xFF3D2C5A);
}

class BestFriendsTypography {
  static TextStyle get coverTitle => GoogleFonts.fredoka(
    fontSize: 38,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 1.0,
  );

  static TextStyle get coverSubtitle => GoogleFonts.quicksand(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: BestFriendsPalette.lilac,
  );

  static TextStyle get caption => GoogleFonts.fredoka(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: BestFriendsPalette.deepViolet,
    height: 1.3,
  );

  static TextStyle get pageNumber => GoogleFonts.quicksand(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: BestFriendsPalette.violet,
  );
}

/// KAPAK — mor degrade, konfeti, büyük emoji tarzı ikon, tombul başlık.
class BestFriendsCover extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji; // örn. "🎉"
  final VoidCallback? onTap;

  const BestFriendsCover({
    super.key,
    required this.title,
    this.subtitle = '',
    this.emoji = '🎉',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BestFriendsPalette.violet, BestFriendsPalette.deepViolet],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x556D3FD1),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _Confetti()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      title.isEmpty ? 'En İyi Dostlar' : title,
                      textAlign: TextAlign.center,
                      style: BestFriendsTypography.coverTitle,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: BestFriendsTypography.coverSubtitle,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SAYFA — lila zemin, eğik kalın çerçeveli fotoğraf, emoji rozet, eğlenceli yazı.
class BestFriendsPhotoPage extends StatelessWidget {
  final int pageNumber;
  final String photoUrl;
  final String caption;
  final String emoji;

  const BestFriendsPhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrl,
    this.caption = '',
    this.emoji = '💜',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BestFriendsPalette.lilac,
      child: Stack(
        children: [
          const Positioned.fill(child: _Confetti(dense: false)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: 0.03,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x336D3FD1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ThemeImage(
                            url: photoUrl,
                            height: 300,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.star_border_rounded,
                          ),
                        ),
                      ),
                    ),
                    // Emoji rozet — çerçevenin köşesinde
                    Positioned(
                      top: -18,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: BestFriendsPalette.sunshine,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x40FFC94D), blurRadius: 10),
                          ],
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: BestFriendsTypography.caption,
                  ),
                const Spacer(),
                Text('$pageNumber', style: BestFriendsTypography.pageNumber),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Konfeti noktaları — sabit konumlu renkli daireler.
class _Confetti extends StatelessWidget {
  final bool dense;
  const _Confetti({this.dense = true});

  @override
  Widget build(BuildContext context) {
    final dots = <_Dot>[
      const _Dot(0.08, 0.10, 8, BestFriendsPalette.sunshine),
      const _Dot(0.85, 0.08, 6, BestFriendsPalette.coral),
      const _Dot(0.15, 0.85, 7, BestFriendsPalette.coral),
      const _Dot(0.90, 0.80, 9, BestFriendsPalette.sunshine),
      const _Dot(0.70, 0.15, 5, Colors.white),
      const _Dot(0.20, 0.25, 5, Colors.white),
      if (dense) ...[
        const _Dot(0.50, 0.06, 6, BestFriendsPalette.coral),
        const _Dot(0.30, 0.90, 6, BestFriendsPalette.sunshine),
        const _Dot(0.75, 0.92, 5, Colors.white),
      ],
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: dots
            .map(
              (d) => Positioned(
                left: constraints.maxWidth * d.x,
                top: constraints.maxHeight * d.y,
                child: Opacity(
                  opacity: 0.55,
                  child: Container(
                    width: d.size,
                    height: d.size,
                    decoration: BoxDecoration(
                      color: d.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Dot {
  final double x, y, size;
  final Color color;
  const _Dot(this.x, this.y, this.size, this.color);
}

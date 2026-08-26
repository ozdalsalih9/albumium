import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// SOFT ROMANCE — pudra pembesi, krem, eğik polaroid çerçeveler.
/// Sıcak, şefkatli, "sarılma" hissi. İki kişilik hikâyeler için.
/// ─────────────────────────────────────────────────────────────

class SoftRomancePalette {
  static const Color cream = Color(0xFFFBF5F0);
  static const Color blush = Color(0xFFF6DDE0);
  static const Color rose = Color(0xFFE8A0AC);
  static const Color deepRose = Color(0xFFC26B7A);
  static const Color cocoa = Color(0xFF5C4340);
  static const Color heart = Color(0xFFE85D75);
  static const Color paper = Color(0xFFFFFDFB);
}

class SoftRomanceTypography {
  static TextStyle get coverTitle => GoogleFonts.cormorantGaramond(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: SoftRomancePalette.cocoa,
    letterSpacing: 0.5,
  );

  static TextStyle get coverSubtitle => GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: SoftRomancePalette.deepRose,
    letterSpacing: 3.0,
  );

  static TextStyle get caption => GoogleFonts.caveat(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: SoftRomancePalette.deepRose,
    height: 1.25,
  );

  static TextStyle get pageNumber => GoogleFonts.jost(
    fontSize: 11,
    color: SoftRomancePalette.rose,
    letterSpacing: 2.0,
  );
}

/// KAPAK — yumuşak degrade, kabartma kalp, el yazısı başlık.
class SoftRomanceCover extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SoftRomanceCover({
    super.key,
    required this.title,
    this.subtitle = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6),
            bottomLeft: Radius.circular(6),
            topRight: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SoftRomancePalette.blush, SoftRomancePalette.rose],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33C26B7A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Kitap sırtı çizgisi
            Positioned(
              left: 14,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: const Color(0x2EFFFFFF)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: SoftRomancePalette.heart,
                    size: 44,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      title.isEmpty ? 'Bizim Hikâyemiz' : title,
                      textAlign: TextAlign.center,
                      style: SoftRomanceTypography.coverTitle,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      subtitle.toUpperCase(),
                      style: SoftRomanceTypography.coverSubtitle,
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

/// SAYFA — krem zemin, iki eğik polaroid, arada kalp, altta el yazısı.
class SoftRomancePhotoPage extends StatelessWidget {
  final int pageNumber;
  final List<String> photoUrls; // 1-2 fotoğraf
  final String caption;

  const SoftRomancePhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrls,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SoftRomancePalette.cream,
      child: Stack(
        children: [
          // Sol üst köşede silik kalp deseni
          const Positioned(
            top: 24,
            right: 24,
            child: Icon(
              Icons.favorite_border,
              color: SoftRomancePalette.blush,
              size: 60,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  height: 340,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (photoUrls.isNotEmpty)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: _Polaroid(url: photoUrls.first, angle: -0.06),
                        ),
                      if (photoUrls.length > 1)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _Polaroid(url: photoUrls[1], angle: 0.05),
                        ),
                      if (photoUrls.length > 1)
                        const Positioned(
                          child: Icon(
                            Icons.favorite,
                            color: SoftRomancePalette.heart,
                            size: 34,
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: SoftRomanceTypography.caption,
                  ),
                const Spacer(),
                Text(
                  '— $pageNumber —',
                  style: SoftRomanceTypography.pageNumber,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Polaroid extends StatelessWidget {
  final String url;
  final double angle;

  const _Polaroid({required this.url, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 190,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 34),
        decoration: BoxDecoration(
          color: SoftRomancePalette.paper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x265C4340),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: ThemeImage(
            url: url,
            height: 170,
            width: 170,
            fit: BoxFit.cover,
            placeholderIcon: Icons.favorite_border,
          ),
        ),
      ),
    );
  }
}

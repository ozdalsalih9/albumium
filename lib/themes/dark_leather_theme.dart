import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// DARK LEATHER — deri cilt, altın varak, dikiş detayı.
/// Ağırbaşlı, zamansız, "kitaplık klasiği" hissi.
/// ─────────────────────────────────────────────────────────────

class DarkLeatherPalette {
  static const Color leather = Color(0xFF2B2118);
  static const Color leatherLight = Color(0xFF3D2F22);
  static const Color page = Color(0xFFEFE7D8);
  static const Color gold = Color(0xFFC9A45C);
  static const Color goldSoft = Color(0xFFE0C88F);
  static const Color stitch = Color(0xFF7A6547);
  static const Color ink = Color(0xFF33291C);
}

class DarkLeatherTypography {
  static TextStyle get coverTitle => GoogleFonts.marcellus(
    fontSize: 32,
    color: DarkLeatherPalette.gold,
    letterSpacing: 3.0,
  );

  static TextStyle get coverSubtitle => GoogleFonts.marcellus(
    fontSize: 13,
    color: DarkLeatherPalette.goldSoft,
    letterSpacing: 5.0,
  );

  static TextStyle get caption => GoogleFonts.cormorantGaramond(
    fontSize: 20,
    fontStyle: FontStyle.italic,
    color: DarkLeatherPalette.ink,
    height: 1.4,
  );

  static TextStyle get pageNumber => GoogleFonts.marcellus(
    fontSize: 11,
    color: DarkLeatherPalette.stitch,
    letterSpacing: 2.0,
  );
}

/// KAPAK — koyu deri, altın çift çerçeve, kabartma başlık, dikiş kenarı.
class DarkLeatherCover extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const DarkLeatherCover({
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
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DarkLeatherPalette.leatherLight,
              DarkLeatherPalette.leather,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x802B2118),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dikiş kenarı (sol)
            Positioned(
              left: 16,
              top: 12,
              bottom: 12,
              child: CustomPaint(
                size: const Size(2, double.infinity),
                painter: _StitchPainter(),
              ),
            ),
            // Altın çift çerçeve
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: DarkLeatherPalette.gold.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: DarkLeatherPalette.gold.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Varak rozet
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DarkLeatherPalette.gold,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: DarkLeatherPalette.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      (title.isEmpty ? 'PREMIUM ALBUM' : title).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: DarkLeatherTypography.coverTitle,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      subtitle.toUpperCase(),
                      style: DarkLeatherTypography.coverSubtitle,
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

/// SAYFA — krem kağıt, ince altın köşe süsleri, çerçeveli fotoğraf.
class DarkLeatherPhotoPage extends StatelessWidget {
  final int pageNumber;
  final String photoUrl;
  final String caption;

  const DarkLeatherPhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrl,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DarkLeatherPalette.page,
      child: Stack(
        children: [
          // Altın köşe süsleri
          const Positioned(top: 16, left: 16, child: _Corner()),
          const Positioned(
            top: 16,
            right: 16,
            child: RotatedBox(quarterTurns: 1, child: _Corner()),
          ),
          const Positioned(
            bottom: 16,
            right: 16,
            child: RotatedBox(quarterTurns: 2, child: _Corner()),
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            child: RotatedBox(quarterTurns: 3, child: _Corner()),
          ),
          Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                const Spacer(),
                // Fotoğraf — ince altın çift çerçeve
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: DarkLeatherPalette.gold.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: DarkLeatherPalette.gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ThemeImage(
                      url: photoUrl,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.menu_book_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Varak ayraç
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 1,
                      color: DarkLeatherPalette.gold,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.diamond,
                        size: 8,
                        color: DarkLeatherPalette.gold,
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 1,
                      color: DarkLeatherPalette.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: DarkLeatherTypography.caption,
                  ),
                const Spacer(),
                Text(
                  '· $pageNumber ·',
                  style: DarkLeatherTypography.pageNumber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// L şeklinde altın köşe süsü.
class _Corner extends StatelessWidget {
  const _Corner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DarkLeatherPalette.gold.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dikey dikiş çizgisi (kesikli).
class _StitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DarkLeatherPalette.stitch
      ..strokeWidth = 1.5;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 6), paint);
      y += 12;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

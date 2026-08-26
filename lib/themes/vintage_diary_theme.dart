import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// VINTAGE DIARY — eskimiş kağıt, daktilo yazısı, bant köşeleri,
/// mürekkep lekeleri. Nostaljik bir günlük sayfası hissi.
/// ─────────────────────────────────────────────────────────────

class VintageDiaryPalette {
  static const Color agedPaper = Color(0xFFF3E9D2);
  static const Color paperDark = Color(0xFFE7D8B8);
  static const Color ink = Color(0xFF4A3B2A);
  static const Color fadedInk = Color(0xFF8A7458);
  static const Color sepia = Color(0xFFB08D57);
  static const Color tape = Color(0x99E8DCC0);
  static const Color stampRed = Color(0xFFA64942);
}

class VintageDiaryTypography {
  static TextStyle get coverTitle => GoogleFonts.specialElite(
    fontSize: 30,
    color: VintageDiaryPalette.ink,
    letterSpacing: 1.5,
  );

  static TextStyle get coverSubtitle =>
      GoogleFonts.caveat(fontSize: 20, color: VintageDiaryPalette.fadedInk);

  static TextStyle get caption => GoogleFonts.caveat(
    fontSize: 22,
    color: VintageDiaryPalette.ink,
    height: 1.3,
  );

  static TextStyle get dateStamp => GoogleFonts.specialElite(
    fontSize: 12,
    color: VintageDiaryPalette.stampRed,
    letterSpacing: 2.0,
  );

  static TextStyle get pageNumber => GoogleFonts.specialElite(
    fontSize: 11,
    color: VintageDiaryPalette.fadedInk,
  );
}

/// KAPAK — kumaş cilt hissi, ortada etiket çerçevesi.
class VintageDiaryCover extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const VintageDiaryCover({
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
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          color: VintageDiaryPalette.paperDark,
          border: Border.all(color: VintageDiaryPalette.sepia, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x404A3B2A),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: VintageDiaryPalette.agedPaper,
              border: Border.all(color: VintageDiaryPalette.sepia),
              boxShadow: const [
                BoxShadow(color: Color(0x1A4A3B2A), blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.isEmpty ? 'Hatıra Defteri' : title,
                  textAlign: TextAlign.center,
                  style: VintageDiaryTypography.coverTitle,
                ),
                const SizedBox(height: 6),
                const Divider(
                  color: VintageDiaryPalette.sepia,
                  thickness: 1,
                  indent: 30,
                  endIndent: 30,
                ),
                const SizedBox(height: 6),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: VintageDiaryTypography.coverSubtitle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SAYFA — çizgili kağıt, bantla tutturulmuş fotoğraf, tarih damgası.
class VintageDiaryPhotoPage extends StatelessWidget {
  final int pageNumber;
  final String photoUrl;
  final String caption;
  final String date; // örn. "14 Şubat 2025"

  const VintageDiaryPhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrl,
    this.caption = '',
    this.date = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VintageDiaryPalette.agedPaper,
      child: Stack(
        children: [
          // Defter çizgileri
          Positioned.fill(child: CustomPaint(painter: _RuledLinesPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date.isNotEmpty)
                  Text(
                    date.toUpperCase(),
                    style: VintageDiaryTypography.dateStamp,
                  ),
                const Spacer(),
                Center(
                  child: Transform.rotate(
                    angle: -0.03,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFFFFBF0),
                          child: ThemeImage(
                            url: photoUrl,
                            height: 260,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.auto_stories_outlined,
                          ),
                        ),
                        // Bant köşeleri
                        const Positioned(top: -10, left: 24, child: _Tape()),
                        const Positioned(top: -10, right: 24, child: _Tape()),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (caption.isNotEmpty)
                  Center(
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: VintageDiaryTypography.caption,
                    ),
                  ),
                const Spacer(),
                Center(
                  child: Text(
                    '$pageNumber',
                    style: VintageDiaryTypography.pageNumber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tape extends StatelessWidget {
  const _Tape();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(width: 60, height: 20, color: VintageDiaryPalette.tape),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33B08D57)
      ..strokeWidth = 1;
    for (double y = 60; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Sol kırmızı marj çizgisi
    final marginPaint = Paint()
      ..color = const Color(0x40A64942)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(44, 0), Offset(44, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

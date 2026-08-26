import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// MINIMAL EDITORIAL — dergi sadeliği. Bol boşluk, ince tipografi,
/// büyük sayı numaraları. Az ama çok zarif.
/// ─────────────────────────────────────────────────────────────

class MinimalEditorialPalette {
  static const Color paper = Color(0xFFFAFAF7);
  static const Color ink = Color(0xFF1E1E1C);
  static const Color grey = Color(0xFF9C9A94);
  static const Color hairline = Color(0xFFE4E2DC);
  static const Color accent = Color(0xFF8C7B66); // sıcak taupe
}

class MinimalEditorialTypography {
  static TextStyle get coverTitle => GoogleFonts.cormorant(
    fontSize: 38,
    fontWeight: FontWeight.w300,
    color: MinimalEditorialPalette.ink,
    letterSpacing: 4.0,
    height: 1.2,
  );

  static TextStyle get coverSubtitle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: MinimalEditorialPalette.grey,
    letterSpacing: 4.0,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MinimalEditorialPalette.ink,
    height: 1.6,
    letterSpacing: 0.3,
  );

  static TextStyle get bigNumber => GoogleFonts.cormorant(
    fontSize: 64,
    fontWeight: FontWeight.w300,
    color: MinimalEditorialPalette.accent,
  );

  static TextStyle get pageNumber => GoogleFonts.inter(
    fontSize: 10,
    color: MinimalEditorialPalette.grey,
    letterSpacing: 2.0,
  );
}

/// KAPAK — saf beyaz, ince çerçeve, büyük harf aralıklı başlık.
class MinimalEditorialCover extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const MinimalEditorialCover({
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
        color: MinimalEditorialPalette.paper,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: MinimalEditorialPalette.hairline,
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 1,
                  color: MinimalEditorialPalette.ink,
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    (title.isEmpty ? 'EDITORIAL' : title).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: MinimalEditorialTypography.coverTitle,
                  ),
                ),
                const SizedBox(height: 28),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle.toUpperCase(),
                    style: MinimalEditorialTypography.coverSubtitle,
                  ),
                const SizedBox(height: 28),
                Container(
                  width: 24,
                  height: 1,
                  color: MinimalEditorialPalette.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SAYFA — büyük sayfa numarası, tam genişlik fotoğraf, ince alt bilgi.
class MinimalEditorialPhotoPage extends StatelessWidget {
  final int pageNumber;
  final String photoUrl;
  final String caption;
  final String location; // opsiyonel, küçük harfli detay

  const MinimalEditorialPhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrl,
    this.caption = '',
    this.location = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MinimalEditorialPalette.paper,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Büyük sayfa numarası — dergi tarzı
          Text(
            pageNumber.toString().padLeft(2, '0'),
            style: MinimalEditorialTypography.bigNumber,
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 1,
            color: MinimalEditorialPalette.accent,
          ),
          const Spacer(),
          // Fotoğraf — çerçevesiz, tam genişlik
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ThemeImage(
              url: photoUrl,
              fit: BoxFit.cover,
              placeholderIcon: Icons.crop_square_outlined,
            ),
          ),
          const SizedBox(height: 20),
          if (caption.isNotEmpty)
            Text(caption, style: MinimalEditorialTypography.caption),
          const Spacer(),
          // Alt bilgi satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                location.toUpperCase(),
                style: MinimalEditorialTypography.pageNumber,
              ),
              Text(
                '${pageNumber.toString().padLeft(2, '0')} / —',
                style: MinimalEditorialTypography.pageNumber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

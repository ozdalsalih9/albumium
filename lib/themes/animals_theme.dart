import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// ANIMALS — kum ve adaçayı tonları, pati izleri, yuvarlak formlar.
/// Evcil hayvan albümleri için sıcak ve oyuncu.
/// ─────────────────────────────────────────────────────────────

class AnimalsPalette {
  static const Color cream = Color(0xFFFAF6EE);
  static const Color sand = Color(0xFFE8DCC4);
  static const Color sage = Color(0xFF9DB48C);
  static const Color deepSage = Color(0xFF6B8A5A);
  static const Color bark = Color(0xFF5D4E37);
  static const Color paw = Color(0xFFD9C6A5);
}

class AnimalsTypography {
  static TextStyle get coverTitle => GoogleFonts.baloo2(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AnimalsPalette.bark,
  );

  static TextStyle get coverSubtitle => GoogleFonts.quicksand(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AnimalsPalette.deepSage,
    letterSpacing: 1.0,
  );

  static TextStyle get caption => GoogleFonts.quicksand(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AnimalsPalette.bark,
    height: 1.4,
  );

  static TextStyle get pageNumber => GoogleFonts.quicksand(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AnimalsPalette.sage,
  );
}

/// KAPAK — adaçayı zemin, ortada yuvarlak fotoğraf penceresi gibi düşünülmüş
/// pati rozeti, tombul başlık.
class AnimalsCover extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const AnimalsCover({
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
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AnimalsPalette.sage, AnimalsPalette.deepSage],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x406B8A5A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dağınık pati izleri
            const Positioned(top: 30, left: 28, child: _PawPrint(size: 26)),
            const Positioned(top: 70, right: 36, child: _PawPrint(size: 18)),
            const Positioned(bottom: 90, left: 44, child: _PawPrint(size: 20)),
            const Positioned(bottom: 40, right: 30, child: _PawPrint(size: 28)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AnimalsPalette.cream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 46,
                      color: AnimalsPalette.deepSage,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      title.isEmpty ? 'Sevimli Dostum' : title,
                      textAlign: TextAlign.center,
                      style: AnimalsTypography.coverTitle.copyWith(
                        color: AnimalsPalette.cream,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AnimalsTypography.coverSubtitle.copyWith(
                        color: AnimalsPalette.sand,
                      ),
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

/// SAYFA — krem zemin, büyük yuvarlak köşeli fotoğraf, pati ayraç, samimi not.
class AnimalsPhotoPage extends StatelessWidget {
  final int pageNumber;
  final String photoUrl;
  final String caption;

  const AnimalsPhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrl,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AnimalsPalette.cream,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Fotoğraf — kalın kum çerçeve, büyük radius
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AnimalsPalette.sand,
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x265D4E37),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ThemeImage(
                url: photoUrl,
                height: 320,
                fit: BoxFit.cover,
                placeholderIcon: Icons.pets_outlined,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Pati ayraç
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PawPrint(size: 14, color: AnimalsPalette.paw),
              SizedBox(width: 10),
              _PawPrint(size: 20, color: AnimalsPalette.sage),
              SizedBox(width: 10),
              _PawPrint(size: 14, color: AnimalsPalette.paw),
            ],
          ),
          const SizedBox(height: 20),
          if (caption.isNotEmpty)
            Text(
              caption,
              textAlign: TextAlign.center,
              style: AnimalsTypography.caption,
            ),
          const Spacer(),
          Text('$pageNumber', style: AnimalsTypography.pageNumber),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Basit pati izi — bir büyük + üç küçük daire.
class _PawPrint extends StatelessWidget {
  final double size;
  final Color color;

  const _PawPrint({this.size = 22, this.color = const Color(0x66FAF6EE)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(bottom: 0, left: size * 0.25, child: _dot(size * 0.5)),
          Positioned(top: 0, left: 0, child: _dot(size * 0.28)),
          Positioned(
            top: -size * 0.08,
            left: size * 0.36,
            child: _dot(size * 0.28),
          ),
          Positioned(top: 0, right: 0, child: _dot(size * 0.28)),
        ],
      ),
    );
  }

  Widget _dot(double d) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

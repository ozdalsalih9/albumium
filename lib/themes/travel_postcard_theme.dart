import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_image_helper.dart';

/// ─────────────────────────────────────────────────────────────
/// TRAVEL POSTCARD — kartpostal kağıdı, pul, posta damgası,
/// airmail çizgileri. Yolculuk anıları için nostaljik ve canlı.
/// ─────────────────────────────────────────────────────────────

class TravelPostcardPalette {
  static const Color paper = Color(0xFFF7F0E1);
  static const Color kraft = Color(0xFFD9C19B);
  static const Color airmailRed = Color(0xFFBF4545);
  static const Color airmailBlue = Color(0xFF3E5C76);
  static const Color ink = Color(0xFF3B3328);
  static const Color faded = Color(0xFF8B7D6B);
  static const Color stampGreen = Color(0xFF7A8B6F);
}

class TravelPostcardTypography {
  static TextStyle get coverTitle => GoogleFonts.libreBaskerville(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: TravelPostcardPalette.ink,
    letterSpacing: 1.0,
  );

  static TextStyle get coverSubtitle => GoogleFonts.ibmPlexMono(
    fontSize: 12,
    color: TravelPostcardPalette.faded,
    letterSpacing: 3.0,
  );

  static TextStyle get caption => GoogleFonts.caveat(
    fontSize: 22,
    color: TravelPostcardPalette.ink,
    height: 1.3,
  );

  static TextStyle get postmark => GoogleFonts.ibmPlexMono(
    fontSize: 10,
    color: TravelPostcardPalette.airmailBlue,
    letterSpacing: 1.5,
  );

  static TextStyle get pageNumber =>
      GoogleFonts.ibmPlexMono(fontSize: 11, color: TravelPostcardPalette.faded);
}

/// KAPAK — kartpostal: üstte airmail şeridi, sağda pul, ortada başlık.
class TravelPostcardCover extends StatelessWidget {
  final String title;
  final String subtitle; // örn. "İSTANBUL — LİZBON"
  final VoidCallback? onTap;

  const TravelPostcardCover({
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
          color: TravelPostcardPalette.paper,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x403B3328),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const _AirmailStrip(),
            Expanded(
              child: Stack(
                children: [
                  // Pul (sağ üst)
                  Positioned(top: 20, right: 20, child: _Stamp()),
                  // Posta damgası
                  Positioned(
                    top: 36,
                    right: 64,
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TravelPostcardPalette.airmailBlue.withValues(
                              alpha: 0.55,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'PAR AVION',
                          style: TravelPostcardTypography.postmark,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flight_takeoff,
                          color: TravelPostcardPalette.airmailRed,
                          size: 36,
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            title.isEmpty ? 'Seyahat Günlüğü' : title,
                            textAlign: TextAlign.center,
                            style: TravelPostcardTypography.coverTitle,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            subtitle.toUpperCase(),
                            style: TravelPostcardTypography.coverSubtitle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const _AirmailStrip(),
          ],
        ),
      ),
    );
  }
}

/// SAYFA — kartpostal düzeni: solda fotoğraf, sağda el yazısı not + pul.
class TravelPostcardPhotoPage extends StatelessWidget {
  final int pageNumber;
  final String photoUrl;
  final String caption;
  final String location; // örn. "Kapadokya"

  const TravelPostcardPhotoPage({
    super.key,
    required this.pageNumber,
    required this.photoUrl,
    this.caption = '',
    this.location = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TravelPostcardPalette.paper,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Fotoğraf — beyaz kartpostal çerçevesi, hafif eğik
          Transform.rotate(
            angle: -0.02,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TravelPostcardPalette.kraft),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x263B3328),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemeImage(
                    url: photoUrl,
                    height: 240,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.landscape_outlined,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      location.toUpperCase(),
                      style: TravelPostcardTypography.coverSubtitle,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Noktalı ayraç
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              12,
              (i) => Container(
                width: 6,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i.isEven
                    ? TravelPostcardPalette.airmailRed
                    : TravelPostcardPalette.airmailBlue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (caption.isNotEmpty)
            Text(
              caption,
              textAlign: TextAlign.center,
              style: TravelPostcardTypography.caption,
            ),
          const Spacer(),
          Text('NO. $pageNumber', style: TravelPostcardTypography.pageNumber),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AirmailStrip extends StatelessWidget {
  const _AirmailStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        children: List.generate(
          30,
          (i) => Expanded(
            child: Container(
              color: i.isEven
                  ? TravelPostcardPalette.airmailRed
                  : (i % 4 == 1
                        ? Colors.white
                        : TravelPostcardPalette.airmailBlue),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 68,
      decoration: BoxDecoration(
        color: TravelPostcardPalette.stampGreen,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x333B3328), blurRadius: 4)],
      ),
      child: const Center(
        child: Icon(Icons.landscape, color: Colors.white, size: 26),
      ),
    );
  }
}

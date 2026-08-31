import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _BundledFont {
  const _BundledFont(this.label, this.assetPath, this.style);

  final String label;
  final String assetPath;
  final TextStyle style;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Google Fonts used by the app are bundled for offline use', (
    tester,
  ) async {
    final previousRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() {
      GoogleFonts.config.allowRuntimeFetching = previousRuntimeFetching;
    });

    final fonts = <_BundledFont>[
      _BundledFont(
        'Baloo 2 Bold',
        'assets/fonts/google/Baloo2-Bold.ttf',
        GoogleFonts.baloo2(fontWeight: FontWeight.w700),
      ),
      _BundledFont(
        'Caveat Regular',
        'assets/fonts/google/Caveat-Regular.ttf',
        GoogleFonts.caveat(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Caveat SemiBold',
        'assets/fonts/google/Caveat-SemiBold.ttf',
        GoogleFonts.caveat(fontWeight: FontWeight.w600),
      ),
      _BundledFont(
        'Cinzel Bold',
        'assets/fonts/google/Cinzel-Bold.ttf',
        GoogleFonts.cinzel(fontWeight: FontWeight.w700),
      ),
      _BundledFont(
        'Cormorant Light',
        'assets/fonts/google/Cormorant-Light.ttf',
        GoogleFonts.cormorant(fontWeight: FontWeight.w300),
      ),
      _BundledFont(
        'Cormorant Garamond Italic',
        'assets/fonts/google/CormorantGaramond-Italic.ttf',
        GoogleFonts.cormorantGaramond(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
      ),
      _BundledFont(
        'Cormorant Garamond SemiBold Italic',
        'assets/fonts/google/CormorantGaramond-SemiBoldItalic.ttf',
        GoogleFonts.cormorantGaramond(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
      _BundledFont(
        'Cormorant Garamond Bold',
        'assets/fonts/google/CormorantGaramond-Bold.ttf',
        GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w700),
      ),
      _BundledFont(
        'Dancing Script Bold',
        'assets/fonts/google/DancingScript-Bold.ttf',
        GoogleFonts.dancingScript(fontWeight: FontWeight.w700),
      ),
      _BundledFont(
        'Fredoka Medium',
        'assets/fonts/google/Fredoka-Medium.ttf',
        GoogleFonts.fredoka(fontWeight: FontWeight.w500),
      ),
      _BundledFont(
        'Fredoka SemiBold',
        'assets/fonts/google/Fredoka-SemiBold.ttf',
        GoogleFonts.fredoka(fontWeight: FontWeight.w600),
      ),
      _BundledFont(
        'IBM Plex Mono Regular',
        'assets/fonts/google/IBMPlexMono-Regular.ttf',
        GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Inter Regular',
        'assets/fonts/google/Inter-Regular.ttf',
        GoogleFonts.inter(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Inter Medium',
        'assets/fonts/google/Inter-Medium.ttf',
        GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      _BundledFont(
        'Inter ExtraBold',
        'assets/fonts/google/Inter-ExtraBold.ttf',
        GoogleFonts.inter(fontWeight: FontWeight.w800),
      ),
      _BundledFont(
        'Jost Regular',
        'assets/fonts/google/Jost-Regular.ttf',
        GoogleFonts.jost(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Libre Baskerville Bold',
        'assets/fonts/google/LibreBaskerville-Bold.ttf',
        GoogleFonts.libreBaskerville(fontWeight: FontWeight.w700),
      ),
      _BundledFont(
        'Marcellus Regular',
        'assets/fonts/google/Marcellus-Regular.ttf',
        GoogleFonts.marcellus(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Pacifico Regular',
        'assets/fonts/google/Pacifico-Regular.ttf',
        GoogleFonts.pacifico(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Quicksand Regular',
        'assets/fonts/google/Quicksand-Regular.ttf',
        GoogleFonts.quicksand(fontWeight: FontWeight.w400),
      ),
      _BundledFont(
        'Quicksand Medium',
        'assets/fonts/google/Quicksand-Medium.ttf',
        GoogleFonts.quicksand(fontWeight: FontWeight.w500),
      ),
      _BundledFont(
        'Quicksand SemiBold',
        'assets/fonts/google/Quicksand-SemiBold.ttf',
        GoogleFonts.quicksand(fontWeight: FontWeight.w600),
      ),
      _BundledFont(
        'Quicksand Bold',
        'assets/fonts/google/Quicksand-Bold.ttf',
        GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      ),
      _BundledFont(
        'Special Elite Regular',
        'assets/fonts/google/SpecialElite-Regular.ttf',
        GoogleFonts.specialElite(fontWeight: FontWeight.w400),
      ),
    ];

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundledAssets = manifest.listAssets();
    for (final font in fonts) {
      expect(
        bundledAssets,
        contains(font.assetPath),
        reason: '${font.label} is missing from the Flutter asset manifest.',
      );
      final bytes = await rootBundle.load(font.assetPath);
      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '${font.label} has no bundled font data.',
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final font in fonts)
                Text('Albumium hatırası — ${font.label}', style: font.style),
            ],
          ),
        ),
      ),
    );
    await GoogleFonts.pendingFonts();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsNWidgets(fonts.length));
  });
}

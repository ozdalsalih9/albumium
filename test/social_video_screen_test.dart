import 'package:albumium/l10n/albumium_localizations.dart';
import 'package:albumium/models/social_video_draft.dart';
import 'package:albumium/screens/social_video_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'social_video_draft_test.dart' show socialTestAlbum;

Widget app(Widget child, {double scale = 1, String language = 'tr'}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AlbumiumLocalizations.supportedLocales,
      localizationsDelegates: const [
        AlbumiumLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void main() {
  setUpAll(() async {
    for (final family in ['AlbumiumSans', 'AlbumiumDisplay', 'Roboto']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/fonts/google/Inter-Regular.ttf')))
          .load();
    }
  });
  testWidgets(
    'studio previews duration and keeps controls accessible on a narrow phone',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final album = socialTestAlbum()..coverPhotoPath = null;
      final original = album.toJson();
      await tester.pumpWidget(
        app(SocialVideoScreen(album: album), scale: 2, language: 'en'),
      );
      await tester.pumpAndSettle();
      final draft = tester
          .widget<SocialVideoFrame>(find.byType(SocialVideoFrame))
          .draft;
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '30 seconds'));
      await tester.tap(find.widgetWithText(ChoiceChip, '30 seconds'));
      await tester.pumpAndSettle();
      expect(draft.totalFrames, 900);
      // Drag the outer page gutter, away from the independently scrolling page list.
      for (
        var i = 0;
        i < 12 &&
            find.byKey(const ValueKey('social-export')).evaluate().isEmpty;
        i++
      ) {
        await tester.dragFrom(const Offset(8, 620), const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const ValueKey('social-export')));
      await tester.pumpAndSettle();
      expect(find.text('1080p'), findsOneWidget);
      expect(find.text('720p'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('social-export')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      expect(album.toJson(), original);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'all templates keep long titles and notes inside the video composition',
    (tester) async {
      final album = socialTestAlbum()
        ..coverPhotoPath = null
        ..title = 'Uzun bir yaz hatırası ' * 12;
      for (final template in SocialVideoTemplate.values) {
        final draft = SocialVideoDraft(album)
          ..template = template
          ..closingNote = 'Bütün güzel anılarımız hep bizimle kalsın. ' * 3;
        for (final frame in [15, 90, 440]) {
          await tester.pumpWidget(
            app(
              Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 360,
                    height: 640,
                    child: SocialVideoFrame(
                      album: album,
                      draft: draft,
                      frame: frame,
                    ),
                  ),
                ),
              ),
              scale: 2,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

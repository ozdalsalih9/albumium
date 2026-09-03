import 'package:albumium/main.dart';
import 'package:albumium/screens/special_card_studio_screen.dart';
import 'package:albumium/screens/theme_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('empty library opens the album creation flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();

    expect(find.text('Anılarına hoş geldin'), findsOneWidget);
    expect(find.text('ALBUMIUM'), findsNothing);
    expect(find.text('Tasarım oluştur'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/branding/albumium_brand_mark.png')),
      findsOneWidget,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasarım oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Ne tasarlamak istersin?'), findsOneWidget);
    await tester.tap(find.text('Fiziksel Albüm'));
    await tester.pumpAndSettle();
    expect(find.text('Hangi hikâyeyi anlatıyoruz?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('app palette changes without leaving the theme sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Uygulama temasını değiştir'));
    await tester.pumpAndSettle();
    expect(find.text('Uygulama görünümü'), findsOneWidget);

    await tester.tap(find.text('Gül Pembesi'));
    await tester.pumpAndSettle();

    expect(find.text('Uygulama görünümü'), findsOneWidget);
    expect(find.text('Gül Pembesi temasını kullan'), findsOneWidget);
    expect(find.text('Anılarına hoş geldin'), findsOneWidget);
    expect(find.text('ALBUMIUM'), findsNothing);
  });

  testWidgets('special day card opens in its dedicated studio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final project = createSpecialCardProject();
    await tester.pumpWidget(
      MaterialApp(home: SpecialCardStudioScreen(project: project)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kart Teması'), findsOneWidget);
    expect(find.text('Şekiller'), findsOneWidget);
  });

  testWidgets('language control is left of theme and switches to English', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();

    final languageButton = find.byKey(
      const ValueKey('home-language-button'),
    );
    final themeButton = find.byKey(const ValueKey('home-theme-button'));
    expect(languageButton, findsOneWidget);
    expect(themeButton, findsOneWidget);
    expect(
      tester.getTopLeft(languageButton).dx,
      lessThan(tester.getTopLeft(themeButton).dx),
    );

    await tester.tap(languageButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to your memories'), findsOneWidget);
    expect(find.text('New design'), findsWidgets);
    expect(find.text('EN'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to your memories'), findsOneWidget);
  });

  testWidgets('theme carousel preserves selection across tablet viewports', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(450, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ThemeScreen()));
    await tester.pumpAndSettle();

    PageView carousel = tester.widget<PageView>(
      find.byKey(const ValueKey('theme-carousel')),
    );
    expect(carousel.controller?.viewportFraction, 0.70);

    await tester.drag(
      find.byKey(const ValueKey('theme-carousel')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('selected-theme-summary')))
          .data,
      startsWith('Vintage Diary ·'),
    );

    for (final viewport in const <Size>[
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 768),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'Theme layout should not overflow at '
            '${viewport.width}×${viewport.height}.',
      );
      carousel = tester.widget<PageView>(
        find.byKey(const ValueKey('theme-carousel')),
      );
      expect(carousel.controller?.viewportFraction, 0.42);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('selected-theme-summary')))
            .data,
        startsWith('Vintage Diary ·'),
      );
    }
  });
}

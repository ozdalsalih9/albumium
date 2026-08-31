import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:albumium/widgets/albumium_launch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildLaunchScreen({
    required VoidCallback onFinished,
    bool disableAnimations = false,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return MaterialApp(
      theme: AlbumiumAppTheme.light(AlbumiumAppTheme.defaultThemeId),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: AlbumiumLaunchScreen(duration: duration, onFinished: onFinished),
      ),
    );
  }

  testWidgets('shows the premium mark and completes exactly once', (
    tester,
  ) async {
    var finishCount = 0;
    await tester.pumpWidget(buildLaunchScreen(onFinished: () => finishCount++));

    expect(
      find.image(const AssetImage('assets/branding/albumium_brand_mark.png')),
      findsNWidgets(2),
    );
    expect(find.text('Anılar, zarafetle saklanır.'), findsOneWidget);
    expect(find.text('ALBUMIUM'), findsNothing);
    expect(
      find.bySemanticsLabel('Uygulama açılıyor. Anılar, zarafetle saklanır.'),
      findsOneWidget,
    );
    expect(finishCount, 0);

    // Give the ticker its first timestamp, then advance through the sequence.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 101));
    expect(finishCount, 0);
    await tester.pump();
    expect(finishCount, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(finishCount, 1);
  });

  testWidgets('reduced motion finishes on the next frame', (tester) async {
    var finishCount = 0;
    await tester.pumpWidget(
      buildLaunchScreen(
        disableAnimations: true,
        onFinished: () => finishCount++,
      ),
    );

    final launchScreen = find.byType(AlbumiumLaunchScreen);
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: launchScreen, matching: find.byType(FadeTransition)),
    );
    final scale = tester.widget<ScaleTransition>(
      find.descendant(of: launchScreen, matching: find.byType(ScaleTransition)),
    );
    expect(fade.opacity.value, 1);
    expect(scale.scale.value, 1);
    expect(finishCount, 0);

    await tester.pump();
    expect(finishCount, 1);
    await tester.pump();
    expect(finishCount, 1);
  });
}

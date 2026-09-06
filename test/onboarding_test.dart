import 'package:albumium/main.dart';
import 'package:albumium/screens/home_screen.dart';
import 'package:albumium/screens/onboarding_screen.dart';
import 'package:albumium/services/photo_selection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'first launch completes four steps and stays completed after restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Tamam'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AlbumiumApp.onboardingCompletedKey), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(800, 1280),
    const Size(1280, 800),
  ]) {
    testWidgets('onboarding fits $size in both languages and large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AlbumiumApp(showLaunchAnimation: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
    });
  }

  testWidgets(
    'gallery explanation is contextual and cancel does not mark it accepted',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => PhotoSelectionService.pick(context),
                child: const Text('Pick'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(find.text('Fotoğraflarını seç'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          PhotoSelectionService.explanationKey,
        ),
        isNull,
      );
    },
  );
}

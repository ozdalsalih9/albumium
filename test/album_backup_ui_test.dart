import 'package:albumium/models/album_models.dart';
import 'package:albumium/screens/home_screen.dart';
import 'package:albumium/screens/preview_screen.dart';
import 'package:albumium/services/album_backup_service.dart';
import 'package:albumium/services/language_controller.dart';
import 'package:albumium/services/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('iPhone share menu names iCloud and explains folder selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: PreviewScreen(
          album: AlbumModel(
            id: 'backup-ui',
            title: 'Anılar',
            themeId: 'vintage_diary',
            createdAt: now,
            updatedAt: now,
            pages: [
              AlbumPageModel(
                id: 'page',
                backgroundColor: 0xFFF2E8D3,
                paperPattern: 'rose',
              ),
            ],
          ),
          openShareOnReady: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('iCloud’a yedekle'), findsOneWidget);
    expect(find.textContaining('iCloud Drive klasörünü seç'), findsOneWidget);
    expect(find.text('Google Drive’a yedekle'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('empty library offers restore and cancelling leaves it usable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme = ThemeController();
    final language = LanguageController();
    addTearDown(theme.dispose);
    addTearDown(language.dispose);
    var calls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AlbumBackupService.channel, (
      call,
    ) async {
      expect(call.method, 'pick');
      calls++;
      return null;
    });
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(AlbumBackupService.channel, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          themeController: theme,
          languageController: language,
          heroMotionEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('restore_cloud_backup'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    expect(find.textContaining('Yedek açılamadı'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

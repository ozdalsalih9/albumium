import 'package:albumium/services/theme_controller.dart';
import 'package:albumium/theme/albumium_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('all selectable palettes produce Material 3 light and dark themes', () {
    expect(AlbumiumAppTheme.options, hasLength(4));

    for (final option in AlbumiumAppTheme.options) {
      final light = AlbumiumAppTheme.light(option.id);
      final dark = AlbumiumAppTheme.dark(option.id);

      expect(light.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.useMaterial3, isTrue);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<AlbumiumThemeColors>(), isNotNull);
      expect(dark.extension<AlbumiumThemeColors>(), isNotNull);
      expect(light.textTheme.bodyMedium?.fontFamily, 'AlbumiumSans');
      expect(light.textTheme.headlineSmall?.fontFamily, 'AlbumiumDisplay');
      expect(dark.textTheme.bodyMedium?.fontFamily, 'AlbumiumSans');
      expect(dark.textTheme.headlineSmall?.fontFamily, 'AlbumiumDisplay');
    }
  });

  test('selection and theme mode survive a controller reload', () async {
    final controller = ThemeController();
    await controller.initialize();

    await controller.setTheme(AlbumiumThemeId.rose);
    await controller.setThemeMode(ThemeMode.system);

    final restoredController = ThemeController();
    await restoredController.initialize();

    expect(restoredController.themeId, AlbumiumThemeId.rose);
    expect(restoredController.themeMode, ThemeMode.system);
    expect(restoredController.selectedOption.name, 'Gül Pembesi');
  });

  test('unknown stored values safely use defaults', () async {
    SharedPreferences.setMockInitialValues({
      ThemeController.themeIdPreferenceKey: 'missing-palette',
      ThemeController.themeModePreferenceKey: 'cinematic',
    });

    final controller = ThemeController();
    await controller.initialize();

    expect(controller.themeId, AlbumiumAppTheme.defaultThemeId);
    expect(controller.themeMode, ThemeMode.light);
  });
}

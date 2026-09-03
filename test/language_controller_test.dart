import 'package:albumium/services/language_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('selected language survives a controller reload', () async {
    final controller = LanguageController();
    await controller.initialize();
    await controller.setLanguage(AppLanguage.english);

    final restored = LanguageController();
    await restored.initialize();

    expect(restored.language, AppLanguage.english);
    expect(restored.locale.languageCode, 'en');
  });

  test('unknown stored language safely uses Turkish', () async {
    SharedPreferences.setMockInitialValues({
      LanguageController.languagePreferenceKey: 'de',
    });

    final controller = LanguageController();
    await controller.initialize();

    expect(controller.language, AppLanguage.turkish);
  });
}

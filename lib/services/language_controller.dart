import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  turkish('tr', 'TR', 'Türkçe'),
  english('en', 'EN', 'English');

  const AppLanguage(this.code, this.shortLabel, this.displayName);

  final String code;
  final String shortLabel;
  final String displayName;

  Locale get locale => Locale(code);
}

/// Owns and persists the language selected inside Albumium.
class LanguageController extends ChangeNotifier {
  LanguageController({
    AppLanguage initialLanguage = AppLanguage.turkish,
    SharedPreferences? preferences,
  }) : _language = initialLanguage,
       _preferences = preferences;

  static const languagePreferenceKey = 'albumium.language.code.v1';

  AppLanguage _language;
  SharedPreferences? _preferences;
  Future<void>? _initialization;
  bool _isInitialized = false;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() => _initialization ??= _loadPreferences();

  Future<void> _loadPreferences() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    _language = _parseLanguage(
          preferences.getString(languagePreferenceKey),
        ) ??
        _language;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    final preferences = await _getPreferences();
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await preferences.setString(languagePreferenceKey, language.code);
  }

  Future<SharedPreferences> _getPreferences() async {
    await initialize();
    return _preferences!;
  }

  static AppLanguage? _parseLanguage(String? value) {
    for (final language in AppLanguage.values) {
      if (language.code == value || language.name == value) return language;
    }
    return null;
  }
}

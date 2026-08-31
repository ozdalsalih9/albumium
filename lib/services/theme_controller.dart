import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/albumium_app_theme.dart';

/// Owns the selected application palette and brightness preference.
///
/// Call [initialize] before `runApp`, then bind [lightTheme], [darkTheme] and
/// [themeMode] to a `MaterialApp`. Changes are reflected immediately and are
/// persisted automatically.
class ThemeController extends ChangeNotifier {
  ThemeController({
    AlbumiumThemeId initialThemeId = AlbumiumAppTheme.defaultThemeId,
    ThemeMode initialThemeMode = ThemeMode.light,
    SharedPreferences? preferences,
  }) : _themeId = initialThemeId,
       _themeMode = initialThemeMode,
       _preferences = preferences;

  static const themeIdPreferenceKey = 'albumium.app_theme.id.v1';
  static const themeModePreferenceKey = 'albumium.app_theme.mode.v1';

  AlbumiumThemeId _themeId;
  ThemeMode _themeMode;
  SharedPreferences? _preferences;
  Future<void>? _initialization;
  bool _isInitialized = false;

  AlbumiumThemeId get themeId => _themeId;
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  AlbumiumThemeOption get selectedOption =>
      AlbumiumAppTheme.optionFor(_themeId);
  ThemeData get lightTheme => AlbumiumAppTheme.light(_themeId);
  ThemeData get darkTheme => AlbumiumAppTheme.dark(_themeId);

  /// Loads the saved values. Multiple calls share the same initialization.
  Future<void> initialize() {
    return _initialization ??= _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final savedThemeId = _parseThemeId(
      preferences.getString(themeIdPreferenceKey),
    );
    final savedThemeMode = _parseThemeMode(
      preferences.getString(themeModePreferenceKey),
    );

    _themeId = savedThemeId ?? _themeId;
    _themeMode = savedThemeMode ?? _themeMode;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setTheme(AlbumiumThemeId id) async {
    final preferences = await _getPreferences();
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();
    await preferences.setString(themeIdPreferenceKey, id.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preferences = await _getPreferences();
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await preferences.setString(themeModePreferenceKey, mode.name);
  }

  Future<void> reset() async {
    final preferences = await _getPreferences();
    final changed =
        _themeId != AlbumiumAppTheme.defaultThemeId ||
        _themeMode != ThemeMode.light;
    _themeId = AlbumiumAppTheme.defaultThemeId;
    _themeMode = ThemeMode.light;
    if (changed) notifyListeners();

    await Future.wait([
      preferences.remove(themeIdPreferenceKey),
      preferences.remove(themeModePreferenceKey),
    ]);
  }

  Future<SharedPreferences> _getPreferences() async {
    await initialize();
    return _preferences!;
  }

  static AlbumiumThemeId? _parseThemeId(String? value) {
    if (value == null) return null;
    for (final id in AlbumiumThemeId.values) {
      if (id.name == value) return id;
    }
    return null;
  }

  static ThemeMode? _parseThemeMode(String? value) {
    if (value == null) return null;
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

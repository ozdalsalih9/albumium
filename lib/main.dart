import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/theme_controller.dart';
import 'theme/albumium_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final themeController = ThemeController();
  await themeController.initialize();
  runApp(AlbumiumApp(themeController: themeController));
}

class AlbumiumApp extends StatefulWidget {
  const AlbumiumApp({super.key, this.themeController});

  /// Optional for tests and embedders. The app owns the controller it creates
  /// when this is null.
  final ThemeController? themeController;

  @override
  State<AlbumiumApp> createState() => _AlbumiumAppState();
}

class _AlbumiumAppState extends State<AlbumiumApp> {
  late final ThemeController _themeController;
  late final bool _ownsThemeController;

  @override
  void initState() {
    super.initState();
    _ownsThemeController = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeController();
    if (!_themeController.isInitialized) {
      unawaited(_themeController.initialize());
    }
  }

  @override
  void dispose() {
    if (_ownsThemeController) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Albumium',
          debugShowCheckedModeBanner: false,
          theme: _themeController.lightTheme,
          darkTheme: _themeController.darkTheme,
          themeMode: _themeController.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 420),
          themeAnimationCurve: Curves.easeInOutCubic,
          builder: (context, child) {
            final theme = Theme.of(context);
            final colors = theme.extension<AlbumiumThemeColors>()!;
            final isDark = theme.brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: colors.background,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: HomeScreen(themeController: _themeController),
        );
      },
    );
  }
}

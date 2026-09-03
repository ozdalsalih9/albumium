import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'l10n/albumium_localizations.dart';
import 'screens/album_import_screen.dart';
import 'screens/home_screen.dart';
import 'services/album_incoming_intent_service.dart';
import 'services/error_reporter.dart';
import 'services/language_controller.dart';
import 'services/theme_controller.dart';
import 'theme/albumium_app_theme.dart';
import 'widgets/albumium_launch_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Albumium is offline-first. Every Google Fonts variant used by the themes
  // is bundled under assets/fonts/google, so rendering and exports never make
  // a runtime font request.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Kancalar her şeyden önce kurulur; başlangıç sırasında oluşan bir hata da
  // yakalansın.
  ErrorReporter.install();
  // Phone layouts remain portrait-first, while tablets can rotate to landscape
  // so the two-page editor has enough horizontal room for a true book spread.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final themeController = ThemeController();
  final languageController = LanguageController();
  await Future.wait([
    themeController.initialize(),
    languageController.initialize(),
  ]);
  runApp(
    AlbumiumApp(
      themeController: themeController,
      languageController: languageController,
    ),
  );
}

class AlbumiumApp extends StatefulWidget {
  const AlbumiumApp({
    super.key,
    this.themeController,
    this.languageController,
    this.showLaunchAnimation = true,
    this.launchAnimationDuration = const Duration(milliseconds: 920),
  });

  /// Optional for tests and embedders. The app owns the controller it creates
  /// when this is null.
  final ThemeController? themeController;
  final LanguageController? languageController;

  /// Can be disabled by focused widget tests and embedders that provide their
  /// own launch experience.
  final bool showLaunchAnimation;

  final Duration launchAnimationDuration;

  @override
  State<AlbumiumApp> createState() => _AlbumiumAppState();
}

class _AlbumiumAppState extends State<AlbumiumApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final List<String> _pendingAlbumPackages = <String>[];
  late final ThemeController _themeController;
  late final LanguageController _languageController;
  late final AlbumIncomingIntentService _incomingIntentService;
  late final bool _ownsThemeController;
  late final bool _ownsLanguageController;
  late bool _showLaunchAnimation;
  Key _homeKey = UniqueKey();
  bool _handlingIncomingPackage = false;

  @override
  void initState() {
    super.initState();
    _ownsThemeController = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeController();
    _ownsLanguageController = widget.languageController == null;
    _languageController = widget.languageController ?? LanguageController();
    _incomingIntentService = AlbumIncomingIntentService();
    _showLaunchAnimation = widget.showLaunchAnimation;
    if (!_themeController.isInitialized) {
      unawaited(_themeController.initialize());
    }
    if (!_languageController.isInitialized) {
      unawaited(_languageController.initialize());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _incomingIntentService.start(
          onPackage: _queueIncomingAlbumPackage,
          onError: _showIncomingAlbumError,
        ),
      );
    });
  }

  void _queueIncomingAlbumPackage(String path) {
    if (!_pendingAlbumPackages.contains(path)) {
      _pendingAlbumPackages.add(path);
    }
    unawaited(_openNextIncomingAlbumPackage());
  }

  Future<void> _openNextIncomingAlbumPackage() async {
    if (!mounted || _handlingIncomingPackage || _pendingAlbumPackages.isEmpty) {
      return;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_openNextIncomingAlbumPackage());
      });
      return;
    }
    _handlingIncomingPackage = true;
    final path = _pendingAlbumPackages.removeAt(0);
    final imported = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => AlbumImportScreen(packagePath: path)),
    );
    if (mounted && imported == true) {
      setState(() => _homeKey = UniqueKey());
    }
    _handlingIncomingPackage = false;
    if (_pendingAlbumPackages.isNotEmpty) {
      unawaited(_openNextIncomingAlbumPackage());
    }
  }

  void _showIncomingAlbumError(String message) {
    if (!mounted) return;
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'Gelen albüm alınamadı: {error}',
            values: {'error': message},
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_incomingIntentService.dispose());
    if (_ownsThemeController) _themeController.dispose();
    if (_ownsLanguageController) _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_themeController, _languageController]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Albumium',
          debugShowCheckedModeBanner: false,
          theme: _themeController.lightTheme,
          darkTheme: _themeController.darkTheme,
          themeMode: _themeController.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 420),
          themeAnimationCurve: Curves.easeInOutCubic,
          locale: _languageController.locale,
          supportedLocales: AlbumiumLocalizations.supportedLocales,
          localizationsDelegates: const [
            AlbumiumLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
          home: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  excluding: _showLaunchAnimation,
                  child: HomeScreen(
                    key: _homeKey,
                    themeController: _themeController,
                    languageController: _languageController,
                  ),
                ),
              ),
              if (_showLaunchAnimation)
                Positioned.fill(
                  child: AlbumiumLaunchScreen(
                    duration: widget.launchAnimationDuration,
                    onFinished: () {
                      if (!mounted) return;
                      setState(() => _showLaunchAnimation = false);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

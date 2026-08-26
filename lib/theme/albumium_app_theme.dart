import 'package:flutter/material.dart';

/// The visual personalities that can be selected for the whole application.
enum AlbumiumThemeId { rose, navy, obsidian, amber }

/// User-facing metadata for an [AlbumiumThemeId].
@immutable
class AlbumiumThemeOption {
  const AlbumiumThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.previewColors,
  });

  final AlbumiumThemeId id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> previewColors;
}

/// Semantic colors used by Albumium in addition to Material's [ColorScheme].
///
/// Read these colors from a widget with:
///
/// ```dart
/// final colors = Theme.of(context).extension<AlbumiumThemeColors>()!;
/// ```
@immutable
class AlbumiumThemeColors extends ThemeExtension<AlbumiumThemeColors> {
  const AlbumiumThemeColors({
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.heroStart,
    required this.heroEnd,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.text,
    required this.mutedText,
    required this.border,
    required this.glow,
  });

  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color heroStart;
  final Color heroEnd;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color text;
  final Color mutedText;
  final Color border;
  final Color glow;

  @override
  AlbumiumThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? heroStart,
    Color? heroEnd,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? text,
    Color? mutedText,
    Color? border,
    Color? glow,
  }) {
    return AlbumiumThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      glow: glow ?? this.glow,
    );
  }

  @override
  AlbumiumThemeColors lerp(
    covariant ThemeExtension<AlbumiumThemeColors>? other,
    double t,
  ) {
    if (other is! AlbumiumThemeColors) return this;
    return AlbumiumThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

/// Material 3 theme factory and the catalogue displayed by a theme picker.
abstract final class AlbumiumAppTheme {
  static const defaultThemeId = AlbumiumThemeId.amber;

  static const options = <AlbumiumThemeOption>[
    AlbumiumThemeOption(
      id: AlbumiumThemeId.rose,
      name: 'Gül Pembesi',
      description: 'Romantik, yumuşak ve zarif pembe tonlar',
      icon: Icons.local_florist_rounded,
      previewColors: [Color(0xFFF39AB5), Color(0xFF7F4058), Color(0xFF201217)],
    ),
    AlbumiumThemeOption(
      id: AlbumiumThemeId.navy,
      name: 'Gece Mavisi',
      description: 'Derin lacivert ve sinematik mavi ışıklar',
      icon: Icons.nightlight_round,
      previewColors: [Color(0xFF79AFFF), Color(0xFF284D86), Color(0xFF091321)],
    ),
    AlbumiumThemeOption(
      id: AlbumiumThemeId.obsidian,
      name: 'Obsidyen',
      description: 'Minimal, güçlü ve zamansız siyah tonlar',
      icon: Icons.dark_mode_rounded,
      previewColors: [Color(0xFFE4E0D8), Color(0xFF676B73), Color(0xFF08090B)],
    ),
    AlbumiumThemeOption(
      id: AlbumiumThemeId.amber,
      name: 'Sıcak Kehribar',
      description: 'Nostaljik, sıcak ve doğal albüm hissi',
      icon: Icons.wb_sunny_rounded,
      previewColors: [Color(0xFFFFAA5E), Color(0xFF93572E), Color(0xFF181310)],
    ),
  ];

  static AlbumiumThemeOption optionFor(AlbumiumThemeId id) {
    return options.firstWhere((option) => option.id == id);
  }

  static ThemeData light(AlbumiumThemeId id) {
    return _buildTheme(_lightColors(id), Brightness.light);
  }

  static ThemeData dark(AlbumiumThemeId id) {
    return _buildTheme(_darkColors(id), Brightness.dark);
  }

  static ThemeData _buildTheme(
    AlbumiumThemeColors colors,
    Brightness brightness,
  ) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          secondary: colors.secondary,
          onSecondary: _foregroundFor(colors.secondary),
          surface: colors.surface,
          onSurface: colors.text,
          surfaceContainerLowest: colors.background,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.elevatedSurface,
          surfaceContainerHigh: Color.lerp(
            colors.elevatedSurface,
            colors.text,
            0.06,
          ),
          surfaceContainerHighest: Color.lerp(
            colors.elevatedSurface,
            colors.text,
            0.11,
          ),
          outline: colors.border,
          outlineVariant: Color.lerp(colors.border, colors.surface, 0.45),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      fontFamily: 'sans-serif',
      visualDensity: VisualDensity.standard,
    );

    final roundedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.border),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: base.textTheme
          .apply(bodyColor: colors.text, displayColor: colors.text)
          .copyWith(
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w800,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              color: colors.mutedText,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.elevatedSurface,
        modalBackgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.mutedText),
        labelStyle: TextStyle(color: colors.mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: roundedInputBorder,
        enabledBorder: roundedInputBorder,
        focusedBorder: roundedInputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: roundedInputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: BorderSide(color: colors.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 5,
        focusElevation: 7,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.glow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.mutedText,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? colors.text : colors.mutedText,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surface,
        selectedColor: colors.glow,
        disabledColor: colors.surface,
        side: BorderSide(color: colors.border),
        labelStyle: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.mutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : colors.elevatedSurface;
        }),
        trackOutlineColor: WidgetStatePropertyAll(colors.border),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.elevatedSurface,
        contentTextStyle: TextStyle(color: colors.text),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surface,
        circularTrackColor: colors.surface,
      ),
      dividerColor: colors.border,
      splashColor: colors.glow,
      highlightColor: colors.glow,
    );
  }

  static Color _foregroundFor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF15110F);
  }

  static AlbumiumThemeColors _lightColors(AlbumiumThemeId id) {
    return switch (id) {
      AlbumiumThemeId.rose => _roseLight,
      AlbumiumThemeId.navy => _navyLight,
      AlbumiumThemeId.obsidian => _obsidianLight,
      AlbumiumThemeId.amber => _amberLight,
    };
  }

  static AlbumiumThemeColors _darkColors(AlbumiumThemeId id) {
    return switch (id) {
      AlbumiumThemeId.rose => _roseDark,
      AlbumiumThemeId.navy => _navyDark,
      AlbumiumThemeId.obsidian => _obsidianDark,
      AlbumiumThemeId.amber => _amberDark,
    };
  }

  static const _roseLight = AlbumiumThemeColors(
    background: Color(0xFFFFF8FA),
    surface: Color(0xFFFFEEF3),
    elevatedSurface: Color(0xFFFFE3EC),
    heroStart: Color(0xFFFFDCE7),
    heroEnd: Color(0xFFFFF8FA),
    primary: Color(0xFFB83F68),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF875363),
    text: Color(0xFF2C151D),
    mutedText: Color(0xFF765C65),
    border: Color(0x2F703849),
    glow: Color(0x35E15D88),
  );

  static const _roseDark = AlbumiumThemeColors(
    background: Color(0xFF171013),
    surface: Color(0xFF24181D),
    elevatedSurface: Color(0xFF312128),
    heroStart: Color(0xFF4A2835),
    heroEnd: Color(0xFF1C1216),
    primary: Color(0xFFF39AB5),
    onPrimary: Color(0xFF35101D),
    secondary: Color(0xFFD0A2B0),
    text: Color(0xFFFFF3F6),
    mutedText: Color(0xFFC5AAB3),
    border: Color(0x32FFD8E4),
    glow: Color(0x45F26F9A),
  );

  static const _navyLight = AlbumiumThemeColors(
    background: Color(0xFFF7F9FE),
    surface: Color(0xFFEDF2FC),
    elevatedSurface: Color(0xFFE1EAF9),
    heroStart: Color(0xFFDDE9FF),
    heroEnd: Color(0xFFF7F9FE),
    primary: Color(0xFF235EA9),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF536A8E),
    text: Color(0xFF101C2D),
    mutedText: Color(0xFF5C6878),
    border: Color(0x30274A77),
    glow: Color(0x3A5597ED),
  );

  static const _navyDark = AlbumiumThemeColors(
    background: Color(0xFF08111E),
    surface: Color(0xFF101C2E),
    elevatedSurface: Color(0xFF18273E),
    heroStart: Color(0xFF203D67),
    heroEnd: Color(0xFF0B1422),
    primary: Color(0xFF79AFFF),
    onPrimary: Color(0xFF081B35),
    secondary: Color(0xFFA9C7F8),
    text: Color(0xFFF4F7FF),
    mutedText: Color(0xFFAAB8CC),
    border: Color(0x354A6C9F),
    glow: Color(0x48558FE7),
  );

  static const _obsidianLight = AlbumiumThemeColors(
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFEDEDEA),
    elevatedSurface: Color(0xFFE2E2DE),
    heroStart: Color(0xFFD8D8D3),
    heroEnd: Color(0xFFF7F7F5),
    primary: Color(0xFF24262A),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF5C6068),
    text: Color(0xFF111214),
    mutedText: Color(0xFF666970),
    border: Color(0x3022262C),
    glow: Color(0x2822262C),
  );

  static const _obsidianDark = AlbumiumThemeColors(
    background: Color(0xFF08090B),
    surface: Color(0xFF121316),
    elevatedSurface: Color(0xFF1C1E22),
    heroStart: Color(0xFF2A2D33),
    heroEnd: Color(0xFF0C0D0F),
    primary: Color(0xFFE4E0D8),
    onPrimary: Color(0xFF171717),
    secondary: Color(0xFFAAAEB7),
    text: Color(0xFFF5F3EE),
    mutedText: Color(0xFFA9A9A5),
    border: Color(0x35D9D9D3),
    glow: Color(0x29DDD9D0),
  );

  static const _amberLight = AlbumiumThemeColors(
    background: Color(0xFFFFFAF5),
    surface: Color(0xFFF8EFE6),
    elevatedSurface: Color(0xFFF1E2D3),
    heroStart: Color(0xFFFFE5CB),
    heroEnd: Color(0xFFFFFAF5),
    primary: Color(0xFFB95816),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF856046),
    text: Color(0xFF2A1A10),
    mutedText: Color(0xFF756355),
    border: Color(0x326C4328),
    glow: Color(0x3AF08B3F),
  );

  static const _amberDark = AlbumiumThemeColors(
    background: Color(0xFF181310),
    surface: Color(0xFF241D19),
    elevatedSurface: Color(0xFF312721),
    heroStart: Color(0xFF4A3020),
    heroEnd: Color(0xFF1C1714),
    primary: Color(0xFFFFAA5E),
    onPrimary: Color(0xFF2B1708),
    secondary: Color(0xFFD9B18E),
    text: Color(0xFFFFF5ED),
    mutedText: Color(0xFFC0B0A4),
    border: Color(0x35FFE0C7),
    glow: Color(0x45F08B3F),
  );
}

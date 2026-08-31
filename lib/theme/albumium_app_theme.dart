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
      description: 'Toz pembe kâğıtlar ve çiçekli washi bantlar',
      icon: Icons.local_florist_rounded,
      previewColors: [Color(0xFFC47C82), Color(0xFFF2DDD5), Color(0xFF4B302F)],
    ),
    AlbumiumThemeOption(
      id: AlbumiumThemeId.navy,
      name: 'Gece Mavisi',
      description: 'Solgun mavi kâğıt ve lacivert mürekkep izleri',
      icon: Icons.nightlight_round,
      previewColors: [Color(0xFF526C80), Color(0xFFE4E4DA), Color(0xFF24313C)],
    ),
    AlbumiumThemeOption(
      id: AlbumiumThemeId.obsidian,
      name: 'Obsidyen',
      description: 'Eskitilmiş gri kâğıt ve kömür kalem dokusu',
      icon: Icons.dark_mode_rounded,
      previewColors: [Color(0xFF4B4945), Color(0xFFE4DED2), Color(0xFF24231F)],
    ),
    AlbumiumThemeOption(
      id: AlbumiumThemeId.amber,
      name: 'Sıcak Kehribar',
      description: 'Mantar pano, kraft kâğıt ve sıcak ahşap tonları',
      icon: Icons.wb_sunny_rounded,
      previewColors: [Color(0xFFB9825D), Color(0xFFF3E6D2), Color(0xFF392B24)],
    ),
  ];

  static AlbumiumThemeOption optionFor(AlbumiumThemeId id) {
    return options.firstWhere((option) => option.id == id);
  }

  /// Reads the active Albumium palette and falls back to the default craft
  /// palette when a screen is embedded in a plain [MaterialApp].
  static AlbumiumThemeColors colorsOf(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AlbumiumThemeColors>() ??
        (theme.brightness == Brightness.dark
            ? _darkColors(defaultThemeId)
            : _lightColors(defaultThemeId));
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
      canvasColor: colors.surface,
      fontFamily: 'AlbumiumSans',
      visualDensity: VisualDensity.standard,
    );

    final roundedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: colors.border, width: 1.2),
    );

    final functionalTextTheme = base.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
      fontFamily: 'AlbumiumSans',
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: functionalTextTheme.copyWith(
        displaySmall: TextStyle(
          color: colors.text,
          fontFamily: 'AlbumiumDisplay',
          fontSize: 38,
          height: 1.04,
          fontWeight: FontWeight.w400,
          letterSpacing: -.4,
        ),
        headlineSmall: TextStyle(
          color: colors.text,
          fontFamily: 'AlbumiumDisplay',
          fontSize: 30,
          height: 1.08,
          fontWeight: FontWeight.w400,
          letterSpacing: -.25,
        ),
        titleLarge: TextStyle(
          color: colors.text,
          fontFamily: 'AlbumiumDisplay',
          fontSize: 24,
          height: 1.08,
          fontWeight: FontWeight.w400,
        ),
        titleMedium: functionalTextTheme.titleMedium?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: functionalTextTheme.bodyMedium?.copyWith(
          color: colors.mutedText,
          height: 1.35,
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
          fontFamily: 'AlbumiumDisplay',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: -.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.border, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border, width: 1.2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.elevatedSurface,
        modalBackgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
          textStyle: const TextStyle(
            fontFamily: 'AlbumiumSans',
            fontWeight: FontWeight.w800,
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: .30),
          side: BorderSide(
            color: Color.lerp(colors.primary, Colors.black, .22)!,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: BorderSide(color: colors.border),
          textStyle: const TextStyle(
            fontFamily: 'AlbumiumSans',
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontFamily: 'AlbumiumSans',
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 5,
        focusElevation: 7,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        labelStyle: TextStyle(color: colors.text, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    background: Color(0xFFC89A92),
    surface: Color(0xFFF2DDD5),
    elevatedSurface: Color(0xFFFFF3E8),
    heroStart: Color(0xFFE8BAB1),
    heroEnd: Color(0xFFF0D6CA),
    primary: Color(0xFF9A4D58),
    onPrimary: Color(0xFFFFF8F0),
    secondary: Color(0xFF747765),
    text: Color(0xFF432E2D),
    mutedText: Color(0xFF78615D),
    border: Color(0x5C704945),
    glow: Color(0x55D89591),
  );

  static const _roseDark = AlbumiumThemeColors(
    background: Color(0xFF332221),
    surface: Color(0xFF4B3532),
    elevatedSurface: Color(0xFF614641),
    heroStart: Color(0xFF70433F),
    heroEnd: Color(0xFF3D2927),
    primary: Color(0xFFE3A29F),
    onPrimary: Color(0xFF3A2221),
    secondary: Color(0xFFC7BE9E),
    text: Color(0xFFFFEEDF),
    mutedText: Color(0xFFD6BDB1),
    border: Color(0x4DFFE4D6),
    glow: Color(0x4DC87977),
  );

  static const _navyLight = AlbumiumThemeColors(
    background: Color(0xFF81909B),
    surface: Color(0xFFE7E4D8),
    elevatedSurface: Color(0xFFF6F1E4),
    heroStart: Color(0xFFB9C8CC),
    heroEnd: Color(0xFFD9DDD7),
    primary: Color(0xFF3F5E73),
    onPrimary: Color(0xFFFFFBEE),
    secondary: Color(0xFF8B664F),
    text: Color(0xFF26343D),
    mutedText: Color(0xFF5E6A6E),
    border: Color(0x5946545B),
    glow: Color(0x4D7599AA),
  );

  static const _navyDark = AlbumiumThemeColors(
    background: Color(0xFF202B31),
    surface: Color(0xFF34434A),
    elevatedSurface: Color(0xFF475A62),
    heroStart: Color(0xFF405966),
    heroEnd: Color(0xFF27363D),
    primary: Color(0xFF9EC0CC),
    onPrimary: Color(0xFF1E3038),
    secondary: Color(0xFFD4BFA8),
    text: Color(0xFFF7ECD9),
    mutedText: Color(0xFFC3C7BE),
    border: Color(0x4DE3E0D3),
    glow: Color(0x456A99A8),
  );

  static const _obsidianLight = AlbumiumThemeColors(
    background: Color(0xFF8B8377),
    surface: Color(0xFFE6DED1),
    elevatedSurface: Color(0xFFF5EEE2),
    heroStart: Color(0xFFC9C1B5),
    heroEnd: Color(0xFFE0D8CC),
    primary: Color(0xFF45423D),
    onPrimary: Color(0xFFFFFBF2),
    secondary: Color(0xFF78634E),
    text: Color(0xFF2F2D29),
    mutedText: Color(0xFF69645C),
    border: Color(0x593D3A35),
    glow: Color(0x3D5C5851),
  );

  static const _obsidianDark = AlbumiumThemeColors(
    background: Color(0xFF24231F),
    surface: Color(0xFF393732),
    elevatedSurface: Color(0xFF4A4842),
    heroStart: Color(0xFF555149),
    heroEnd: Color(0xFF2D2B27),
    primary: Color(0xFFD9D0C1),
    onPrimary: Color(0xFF262520),
    secondary: Color(0xFFC0A98B),
    text: Color(0xFFF4EADC),
    mutedText: Color(0xFFC7BFB3),
    border: Color(0x4DEDE2D2),
    glow: Color(0x3DD7CBB7),
  );

  static const _amberLight = AlbumiumThemeColors(
    background: Color(0xFFB9825D),
    surface: Color(0xFFF3E6D2),
    elevatedSurface: Color(0xFFFFF8EC),
    heroStart: Color(0xFFE7C29F),
    heroEnd: Color(0xFFF0D5B8),
    primary: Color(0xFF8F452E),
    onPrimary: Color(0xFFFFF8EC),
    secondary: Color(0xFF6F725F),
    text: Color(0xFF392B24),
    mutedText: Color(0xFF746055),
    border: Color(0x666F4C3A),
    glow: Color(0x55E4B773),
  );

  static const _amberDark = AlbumiumThemeColors(
    background: Color(0xFF2A1C16),
    surface: Color(0xFF47342B),
    elevatedSurface: Color(0xFF5B4437),
    heroStart: Color(0xFF6B4933),
    heroEnd: Color(0xFF3A251B),
    primary: Color(0xFFD99664),
    onPrimary: Color(0xFF2C190F),
    secondary: Color(0xFFC9B58E),
    text: Color(0xFFF8EAD5),
    mutedText: Color(0xFFCDB9A4),
    border: Color(0x4DF0D6B6),
    glow: Color(0x4DC97848),
  );
}

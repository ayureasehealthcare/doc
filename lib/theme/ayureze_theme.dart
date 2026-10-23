import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AyurezeTheme {
  /// The one font family for the whole app: Uni Neue, a licensed family
  /// bundled under assets/fonts/UniNeue/ (declared in pubspec.yaml). Screens
  /// should reach `Theme.of(context).textTheme` rather than naming this
  /// directly, but centralizing it here is what keeps every screen's type on
  /// the same family instead of drifting to the platform default.
  static const String fontFamily = 'Uni Neue';

  static TextStyle font(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Osler UI Kit Colors
  static const Color oslerGray100 = Color(0xFF111A14);
  static const Color oslerGray50 = Color(0xFF849087);
  static const Color oslerGray10 = Color(0xFFF5F5F5);

  // NOTE: these are mode-independent constants, not dark-aware tokens.
  // They intentionally keep their value in dark mode, which makes them safe
  // as accents and foregrounds but unsafe as page/card backgrounds. For
  // backgrounds, borders and body text use the getters below (surface,
  // surfaceMuted, canvas, border, textPrimary, textSecondary).
  //
  // Pixel-verified against the real Osler UI Kit (Figma community file,
  // strangehelix.bio) source PDFs: healingGreen50 is the kit's actual
  // primary brand green (a lime, not the emerald this app had drifted to -
  // #10B981 never once appeared across ~25 sampled kit screens, while
  // #84CC16 was the dominant accent on nearly every one).
  static const Color healingGreen100 = Color(0xFF1A2E05); // kit green-950
  static const Color healingGreen50 = Color(0xFF84CC16); // kit green-500
  static const Color healingGreen10 = Color(0xFFECFCCB); // kit green-100

  // Fill for filled controls that carry a white glyph or label (FAB,
  // checkbox, circular play/AI buttons). healingGreen50 is a bright lime
  // and only reaches 1.98:1 against white, which fails both WCAG AA for
  // text (4.5:1) and the UI-component threshold (3:1). green-700 from the
  // same kit scale reaches 4.99:1, so white content is legible.
  static const Color healingGreenFill = Color(0xFF4D7C0F); // kit green-700

  static const Color remoteRed100 = Color(0xFF4C050B);
  static const Color remoteRed50 = Color(0xFFF43F5E);
  static const Color remoteRed10 = Color(0xFFFFE4E7);

  // Red counterpart of healingGreenFill, for destructive filled buttons
  // with a white label. remoteRed50 reaches only 3.67:1 against white (and
  // 3.98:1 against healingGreen100), short of the 4.5:1 a 16px label needs;
  // rose-700 from the same kit scale reaches 6.29:1.
  static const Color remoteRedFill = Color(0xFFBE123C); // kit rose-700

  static const Color sunshineYellow100 = Color(0xFF422006);
  // Confirmed against the real kit's own published Color Palette
  // reference page (Yellow 50 = #EAB308) - the app had drifted to
  // #F59E0B (Tailwind amber-500), which isn't any step of this scale.
  static const Color sunshineYellow50 = Color(0xFFEAB308);
  static const Color sunshineYellow10 = Color(0xFFFEF9C3);

  static const Color caringViolet100 = Color(0xFF311065);
  static const Color caringViolet50 = Color(0xFF8B5CF6);
  static const Color caringViolet10 = Color(0xFFEDE9FE);

  static const Color connectivityBlue100 = Color(0xFF172554);
  static const Color connectivityBlue50 = Color(0xFF3B82F6);
  static const Color connectivityBlue10 = Color(0xFFEFF6FF);

  // Private state for dynamic theme support
  static bool _isDark = false;
  static void updateThemeMode(bool value) => _isDark = value;

  // Semantic Colors - Light Definitions
  static const Color lightCanvas = Color(0xFFE9EEE4);
  static const Color lightSurface = Color(0xFFF7F8F2);
  static const Color lightSurfaceMuted = Color(0xFFEFF3EA);
  static const Color lightBorder = Color(0xFFD4DDCC);
  static const Color lightTextPrimary = Color(0xFF203126);
  static const Color lightTextSecondary = Color(0xFF607063);

  // Semantic Colors - Dark Definitions
  static const Color darkCanvas = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkSurfaceMuted = Color(0xFF3D3D3D);
  static const Color darkBorder = Color(0xFF4D4D4D);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  // 4.15:1 against darkSurfaceMuted (#3D3D3D) failed WCAG AA (needs 4.5).
  // #B4B4B4 gives 5.24:1 on darkSurfaceMuted and 6.64:1 on darkSurface.
  static const Color darkTextSecondary = Color(0xFFB4B4B4);

  // Dynamic Getters
  static Color get canvas => _isDark ? darkCanvas : lightCanvas;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get surfaceMuted =>
      _isDark ? darkSurfaceMuted : lightSurfaceMuted;
  static Color get border => _isDark ? darkBorder : lightBorder;
  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? darkTextSecondary : lightTextSecondary;

  // Aliases for backwards compatibility
  static const Color forestDeep = healingGreen100;
  static const Color forest = healingGreen50;
  static const Color moss = oslerGray50;
  static const Color lightGreen = healingGreen50;
  static const Color lightGreenSoft = healingGreen10;
  static const Color danger = remoteRed50;
  static const Color warning = sunshineYellow50;
  static const Color purple = caringViolet50;

  // Additional semantic getters
  static Color get surfaceDark => darkSurface;
  static Color get textMuted => darkTextSecondary;
  static Color get borderMuted => border;
  static Color get shadow =>
      _isDark ? const Color(0x66000000) : const Color(0x26000000);

  // Dynamic Icon/SVG Colors - ensures visibility in both modes
  static Color get iconPrimary => _isDark ? Colors.white : healingGreen100;
  static Color get iconSecondary => _isDark ? darkTextSecondary : oslerGray50;
  static Color get iconOnDark => _isDark ? Colors.white : Colors.white;
  static Color get iconOnLight => _isDark ? Colors.white : Colors.white;
  static Color get logoColor => _isDark ? Colors.white : Colors.white;

  // Action button colors for dark/light mode
  static Color get actionButtonPrimary =>
      _isDark ? healingGreen50 : healingGreen100;
  static Color get actionButtonSecondary =>
      _isDark ? oslerGray50 : healingGreen50;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  // Corner radius scale. Before this existed the UI used 14 different radii
  // with no shared vocabulary, so "the same" card could be 12, 16 or 24
  // depending on the screen. These are the values the Osler kit already
  // reached for; naming them makes the choice deliberate.
  static const double radiusXs = 6; // checkbox, tight chips
  static const double radiusSm = 8; // tooltips, small badges
  static const double radiusMd = 12; // inline alerts, toast
  static const double radiusLg = 16; // inputs, dropdowns, alert cards
  static const double radiusXl = 24; // cards, sheets
  static const double radius2xl = 28; // modals
  static const double radiusPill = 999; // fully rounded / pills

  // Spacing scale, in the 4pt rhythm the screens mostly follow already.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;

  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadius2xl => BorderRadius.circular(radius2xl);
  static BorderRadius get borderRadiusPill => BorderRadius.circular(radiusPill);

  static ThemeData theme({bool isDarkMode = false}) {
    if (isDarkMode) {
      return darkTheme();
    }
    return lightTheme();
  }

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: healingGreen100,
      brightness: Brightness.light,
      primary: healingGreenFill,
      secondary: oslerGray50,
      surface: lightSurface,
    ).copyWith(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      error: remoteRed50,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightCanvas,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardColor: lightSurface,
      dividerColor: lightBorder,
      shadowColor: const Color(0x16000000),
      textTheme: ThemeData.light()
          .textTheme
          .apply(fontFamily: fontFamily)
          .copyWith(
            headlineLarge: font(
              32,
              FontWeight.w800,
              lightTextPrimary,
              height: 1.05,
            ),
            headlineMedium: font(
              24,
              FontWeight.w800,
              lightTextPrimary,
              height: 1.15,
            ),
            titleLarge: font(20, FontWeight.w700, lightTextPrimary),
            titleMedium: font(16, FontWeight.w700, lightTextPrimary),
            bodyLarge: font(15, FontWeight.w500, lightTextPrimary, height: 1.4),
            bodyMedium: font(
              14,
              FontWeight.w500,
              lightTextSecondary,
              height: 1.35,
            ),
            labelLarge: font(
              14,
              FontWeight.w700,
              lightTextPrimary,
              letterSpacing: 0.2,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightCanvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: font(22, FontWeight.w800, lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: healingGreen100,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: font(15, FontWeight.w700, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: lightSurface,
          foregroundColor: lightTextPrimary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: font(15, FontWeight.w700, lightTextPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: font(14, FontWeight.w500, lightTextSecondary),
        labelStyle: font(14, FontWeight.w500, lightTextSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: healingGreen100, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: remoteRed50),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: remoteRed50, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: healingGreen10,
        disabledColor: lightSurfaceMuted,
        selectedColor: healingGreen50,
        secondarySelectedColor: healingGreen50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: font(13, FontWeight.w700, healingGreen100),
        secondaryLabelStyle: font(13, FontWeight.w700, healingGreen100),
        brightness: Brightness.light,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static BoxDecoration heroDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: auroraGradient,
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 24,
          offset: Offset(0, 16),
        ),
      ],
    );
  }

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration mutedPanelDecoration() {
    return BoxDecoration(
      color: surfaceMuted,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: border),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: healingGreen100,
      brightness: Brightness.dark,
      primary: healingGreenFill,
      secondary: oslerGray50,
      surface: darkSurface,
    ).copyWith(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      error: remoteRed50,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkCanvas,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardColor: darkSurface,
      dividerColor: darkBorder,
      shadowColor: const Color(0x40000000),
      textTheme: ThemeData.dark()
          .textTheme
          .apply(fontFamily: fontFamily)
          .copyWith(
            headlineLarge: font(
              32,
              FontWeight.w800,
              darkTextPrimary,
              height: 1.05,
            ),
            headlineMedium: font(
              24,
              FontWeight.w800,
              darkTextPrimary,
              height: 1.15,
            ),
            titleLarge: font(20, FontWeight.w700, darkTextPrimary),
            titleMedium: font(16, FontWeight.w700, darkTextPrimary),
            bodyLarge: font(15, FontWeight.w500, darkTextPrimary, height: 1.4),
            bodyMedium: font(
              14,
              FontWeight.w500,
              darkTextSecondary,
              height: 1.35,
            ),
            labelLarge: font(14, FontWeight.w700, darkTextPrimary),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: font(18, FontWeight.w700, darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: healingGreenFill,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: font(15, FontWeight.w700, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: healingGreen50,
          side: const BorderSide(color: healingGreen50, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: font(15, FontWeight.w700, healingGreen50),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: healingGreen50, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: remoteRed50),
        ),
        hintStyle: font(14, FontWeight.w500, darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: healingGreen50,
        unselectedItemColor: darkTextSecondary,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: darkSurface),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: healingGreenFill,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceMuted,
        labelStyle: font(13, FontWeight.w700, darkTextPrimary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: healingGreen50,
        unselectedLabelColor: darkTextSecondary,
      ),
    );
  }

  static BoxDecoration darkPanelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF2D2D2D),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF4D4D4D)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static InputDecoration textFieldDecoration({
    String? labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: healingGreen100, width: 2),
      ),
      filled: true,
      fillColor: surface,
      labelStyle: font(14, FontWeight.w500, textSecondary),
      hintStyle: font(
        14,
        FontWeight.w500,
        textSecondary.withValues(alpha: 0.6),
      ),
    );
  }

  /// A frosted, translucent surface for headers/sheets that sit over other
  /// content (e.g. a sticky app bar over a scrolling hero). Pair with
  /// `BackdropFilter(filter: ImageFilter.blur(...))` in the widget; this only
  /// supplies the fill/border/shadow so every glass surface in the app looks
  /// the same.
  static BoxDecoration glassDecoration({double radius = radius2xl}) {
    return BoxDecoration(
      color: (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: _isDark ? 0.08 : 0.35),
      ),
      boxShadow: [
        BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 12)),
      ],
    );
  }

  /// The signature multi-stop brand gradient for hero surfaces that want more
  /// depth than `heroDecoration`'s flat two-stop gradient - the dashboard
  /// header, onboarding, and other "first thing you see" moments.
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [healingGreen100, healingGreenFill, healingGreen50],
    stops: [0.0, 0.55, 1.0],
  );
}

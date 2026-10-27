import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AyurezeTheme {
  /// Interface and data font, shared with the patient app's "Serene
  /// Herbalist" design system: Inter (bundled, SIL OFL). Screens should
  /// reach `Theme.of(context).textTheme` rather than naming this directly;
  /// centralising it here keeps every screen on the same family.
  static const String fontFamily = 'Inter';

  /// Editorial serif for greetings and headlines ("Good morning, Dr Rao"),
  /// never for clinical data. Newsreader (bundled, SIL OFL), as in the
  /// patient app.
  static const String serifFamily = 'Newsreader';

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

  /// Like [font] but in the editorial serif. For headings and greetings.
  static TextStyle serif(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: serifFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Palette: the patient app's Serene Herbalist system (deep sage, sage
  // mint, turmeric, clay, warm cream) mapped onto the existing token names
  // by ROLE, so every pairing the app already relies on keeps its meaning:
  //   *100  deep ink / dark fill under white
  //   *50   bright accent (icons/borders on dark, fills under dark ink)
  //   *10   pale tint behind its own *100 ink
  //   *Fill mid tone that carries white text on filled controls
  // The token names predate the rebrand (healingGreen, sunshineYellow,
  // remoteRed); the values are sage, turmeric and clay now.
  static const Color oslerGray100 = Color(0xFF1B231F);
  static const Color oslerGray50 = Color(0xFF717973);
  static const Color oslerGray10 = Color(0xFFEFF4F0);

  // NOTE: these are mode-independent constants, not dark-aware tokens.
  // They intentionally keep their value in dark mode, which makes them safe
  // as accents and foregrounds but unsafe as page/card backgrounds. For
  // backgrounds, borders and body text use the getters below (surface,
  // surfaceMuted, canvas, border, textPrimary, textSecondary).
  static const Color healingGreen100 = Color(0xFF1E4F3C); // deep sage ink
  // Sage mint: same lightness role the old lime had, so dark ink on it
  // still clears AA (healingGreen100 on it: 4.88:1).
  static const Color healingGreen50 = Color(0xFF8FC7AC);
  static const Color healingGreen10 = Color(0xFFE8F5EE); // sage tint

  // Fill for filled controls that carry a white glyph or label (primary
  // buttons, FAB, checkbox, circular play/AI buttons): the patient app's
  // primary sage. White on it: 5.78:1.
  static const Color healingGreenFill = Color(0xFF3F6F5A);

  static const Color remoteRed100 = Color(0xFF410002);
  static const Color remoteRed50 =
      Color(0xFFC4473A); // clay red, 4.87:1 on white
  static const Color remoteRed10 = Color(0xFFFFDAD6);

  // Red counterpart of healingGreenFill, for destructive filled buttons
  // with a white label (the patient app's clay alert). White on it: 6.46:1.
  static const Color remoteRedFill = Color(0xFFBA1A1A);

  // Turmeric gold - streaks, highlights, gentle warnings.
  static const Color sunshineYellow100 = Color(0xFF2B1700);
  static const Color sunshineYellow50 = Color(0xFFC98A3E);
  static const Color sunshineYellow10 = Color(0xFFFCEFDC);

  // Violet stays the Astra/AI accent.
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
  // Warm cream canvas, white cards, warm-parchment containers.
  static const Color lightCanvas = Color(0xFFFBF9F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF4EFE6);
  static const Color lightBorder = Color(0xFFDDE5DF);
  static const Color lightTextPrimary = Color(0xFF1B231F);
  static const Color lightTextSecondary = Color(0xFF4A5A52); // 6.38:1 on muted

  // Semantic Colors - Dark Definitions
  // Sage-tinted darks, as in the patient app (not neutral grey).
  static const Color darkCanvas = Color(0xFF131A16);
  static const Color darkSurface = Color(0xFF18221D);
  static const Color darkSurfaceMuted = Color(0xFF1E2B24);
  static const Color darkBorder = Color(0xFF34463C);
  static const Color darkTextPrimary = Color(0xFFE6EFE9);
  static const Color darkTextSecondary = Color(0xFFA5B4AB); // 6.81:1 on muted

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
  // Diffused, warm-tinted ambient shadow - never a hard black drop.
  static Color get shadow =>
      _isDark ? const Color(0x59000000) : const Color(0x142D3730);

  /// Brand accent drawn straight on the page (spinners, progress, active
  /// marks): primary sage in light mode, sage mint in dark. The fixed
  /// healingGreen50 mint is only ~1.8:1 on the cream canvas - too faint for
  /// a progress indicator (3:1).
  static Color get accent => _isDark ? healingGreen50 : healingGreenFill;

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
  static const double radiusCard = 20; // standard cards (design master radius)
  static const double radiusXl = 24; // hero containers, sheets
  static const double radius2xl = 28; // modals
  static const double radiusPill = 999; // fully rounded / pills

  // Spacing scale, in the 4pt rhythm the screens mostly follow already.
  // Type size scale. The theme's textTheme is built from these, so a
  // literal TextStyle(fontSize: AyurezeTheme.textMd) lands on the same
  // steps as Theme.of(context).textTheme.* - prefer the textTheme where a
  // BuildContext is handy, these where it isn't (const styles, painters).
  static const double textXs = 11; // labelSmall
  static const double textSm = 12; // bodySmall
  static const double textMd = 14; // bodyMedium, labelLarge
  static const double textBase = 15; // bodyLarge
  static const double textLg = 16; // titleMedium
  static const double textXl = 20; // titleLarge
  static const double text2xl = 24; // headlineMedium
  static const double text3xl = 32; // headlineLarge

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
      seedColor: healingGreenFill,
      brightness: Brightness.light,
      primary: healingGreenFill,
      secondary: oslerGray50,
      surface: lightSurface,
    ).copyWith(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      error: remoteRedFill,
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
      shadowColor: const Color(0x142D3730),
      textTheme: ThemeData.light()
          .textTheme
          .apply(fontFamily: fontFamily)
          .copyWith(
            // Editorial serif for greetings and section entrances;
            // everything functional stays in the sans.
            headlineLarge: serif(
              text3xl,
              FontWeight.w500,
              lightTextPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            headlineMedium: serif(
              text2xl,
              FontWeight.w500,
              lightTextPrimary,
              height: 1.25,
            ),
            titleLarge: font(textXl, FontWeight.w600, lightTextPrimary),
            titleMedium: font(textLg, FontWeight.w600, lightTextPrimary),
            bodyLarge:
                font(textBase, FontWeight.w400, lightTextPrimary, height: 1.6),
            bodyMedium: font(
              textMd,
              FontWeight.w400,
              lightTextSecondary,
              height: 1.55,
            ),
            labelLarge: font(
              textMd,
              FontWeight.w600,
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
        titleTextStyle: font(textXl, FontWeight.w600, lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: healingGreenFill,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: font(textBase, FontWeight.w600, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: healingGreen100,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: healingGreenFill, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: font(textBase, FontWeight.w600, healingGreen100),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        // Warm parchment fields, no cold white; the border only appears
        // on focus (1.5px sage), as in the patient app.
        filled: true,
        fillColor: lightSurfaceMuted,
        hintStyle: font(textMd, FontWeight.w400, lightTextSecondary),
        labelStyle: font(textMd, FontWeight.w500, lightTextSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: healingGreenFill, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: remoteRed50),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: remoteRed50, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: healingGreen10,
        disabledColor: lightSurfaceMuted,
        selectedColor: healingGreen50,
        secondarySelectedColor: healingGreen50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: font(textMd, FontWeight.w600, healingGreen100),
        secondaryLabelStyle: font(textMd, FontWeight.w600, healingGreen100),
        brightness: Brightness.light,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill)),
      ),
    );
  }

  static BoxDecoration heroDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusXl),
      gradient: auroraGradient,
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F1E4F3C),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(color: border),
      // Tier-1 card: ultra-diffused ambient shadow, not a drop.
      boxShadow: [
        BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 4)),
      ],
    );
  }

  static BoxDecoration mutedPanelDecoration() {
    return BoxDecoration(
      color: surfaceMuted,
      borderRadius: BorderRadius.circular(radiusXl),
      border: Border.all(color: border),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: healingGreenFill,
      brightness: Brightness.dark,
      primary: healingGreenFill,
      secondary: oslerGray50,
      surface: darkSurface,
    ).copyWith(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      error: remoteRedFill,
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
            // Editorial serif for greetings and section entrances;
            // everything functional stays in the sans.
            headlineLarge: serif(
              text3xl,
              FontWeight.w500,
              darkTextPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            headlineMedium: serif(
              text2xl,
              FontWeight.w500,
              darkTextPrimary,
              height: 1.25,
            ),
            titleLarge: font(textXl, FontWeight.w600, darkTextPrimary),
            titleMedium: font(textLg, FontWeight.w600, darkTextPrimary),
            bodyLarge:
                font(textBase, FontWeight.w400, darkTextPrimary, height: 1.6),
            bodyMedium: font(
              textMd,
              FontWeight.w400,
              darkTextSecondary,
              height: 1.55,
            ),
            labelLarge: font(textMd, FontWeight.w600, darkTextPrimary,
                letterSpacing: 0.2),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCanvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: font(textXl, FontWeight.w600, darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: healingGreenFill,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: font(textBase, FontWeight.w600, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: healingGreen50,
          side: const BorderSide(color: healingGreen50, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: font(textBase, FontWeight.w600, healingGreen50),
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
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: healingGreen50, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: remoteRed50),
        ),
        hintStyle: font(textMd, FontWeight.w500, darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: healingGreenFill,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceMuted,
        labelStyle: font(textMd, FontWeight.w600, darkTextPrimary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: healingGreen50,
        unselectedLabelColor: darkTextSecondary,
      ),
    );
  }

  static BoxDecoration darkPanelDecoration() {
    return BoxDecoration(
      color: darkSurface,
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(color: darkBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 20,
          offset: Offset(0, 4),
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
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: iconPrimary, width: 1.5),
      ),
      filled: true,
      fillColor: surfaceMuted,
      labelStyle: font(textMd, FontWeight.w500, textSecondary),
      hintStyle: font(
        textMd,
        FontWeight.w500,
        textSecondary.withValues(alpha: 0.6),
      ),
    );
  }

  /// The panel behind every `GlassSurface`. In the Serene Herbalist system
  /// this is a Tier-1 card: a near-opaque surface with a faint sage outline
  /// and an ultra-diffused ambient shadow (the old 14% white frost was
  /// near-invisible on the cream canvas, so panels read as borderless).
  /// Still slightly translucent, so a `BackdropFilter` behind it softens
  /// any imagery underneath. Every panel's content uses dark-aware ink, so
  /// the surface follows the theme.
  static BoxDecoration glassDecoration({double radius = radius2xl}) {
    return BoxDecoration(
      color: surface.withValues(alpha: _isDark ? 0.92 : 0.94),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _isDark ? darkBorder : healingGreenFill.withValues(alpha: 0.1),
      ),
      boxShadow: [
        BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 4)),
      ],
    );
  }

  // In-call (video) surfaces. Deliberately dark in BOTH themes - a call
  // UI stays dark so video is the brightest thing on screen - so these are
  // constants, not dark-aware getters.
  static const Color callBackground = darkCanvas;
  static const LinearGradient callWaitingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F766E), Color(0xFF134E4A)], // teal-700 -> teal-900
  );
  static const Color callTileShadow = Color(0x55000000);
  // Text and icons drawn straight on the call background. NOT textPrimary:
  // that flips to dark ink in light mode, 1.45:1 on the teal gradient.
  static const Color callForeground = Colors.white;

  /// The signature brand gradient for hero surfaces - the dashboard header,
  /// onboarding and other "first thing you see" moments. Deep forest to
  /// primary sage, like the patient app's "Talk to Astra" card; white text
  /// clears AA on every stop (5.78:1 at the lightest).
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [healingGreen100, Color(0xFF265643), healingGreenFill],
    stops: [0.0, 0.55, 1.0],
  );
}

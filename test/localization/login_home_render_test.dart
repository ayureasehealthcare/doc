import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/language_localization.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:doctro/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the first screen shown after login, where the black screen was
/// reported: the subtree failed to build, so the area between the status and
/// navigation bars stayed empty.
///
/// Everything runs in a single test body on purpose. Re-pumping at different
/// widths inside one test is reliable; separate `testWidgets` in the same file
/// leave the localizations delegate unresolved for all but the first, and the
/// app then builds no child at all.
/// Swastu breathes in an endless idle loop, so a screen showing it never
/// "settles". Turning on the platform's reduce-motion setting (which
/// Swastu honours) lets pumpAndSettle finish, and covers that path too.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders after login and fits across screen widths',
      (tester) async {
    _reduceMotion(tester);
    // tester.view drives MediaQuery. setSurfaceSize does not, so it cannot
    // reproduce width-dependent layout.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'current_language_code': 'en',
      'name': 'Test Doctor',
    });
    await SharedPreferenceHelper.initWithPreferences(
        await SharedPreferences.getInstance());

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        home: const LoginHomeScreen(chat: ''),
        locale: const Locale('en', 'US'),
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          LanguageLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ));
    await tester.pumpAndSettle();

    // The blank screen had a Scaffold but zero Text descendants.
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(Text), findsWidgets);
    expect(find.textContaining('Test Doctor'), findsWidgets);
    expect(find.text('Welcome back,'), findsWidgets);

    // The stat-card grid sized its tiles from an aspect ratio, so the tile
    // height fell with the width until the card's fixed content overflowed.
    // 360 and 800 sit on either side of the layout's 500pt breakpoint.
    for (final width in [360.0, 412.0, 800.0]) {
      tester.view.physicalSize = Size(width, 915);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'layout overflowed at ${width.toInt()}pt wide');
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'screen stopped building at ${width.toInt()}pt wide');
    }
  });
}

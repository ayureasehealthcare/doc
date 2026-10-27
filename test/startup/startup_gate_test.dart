import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/features/authentication/SignIn.dart';
import 'package:doctro/features/shell/app_shell.dart';
import 'package:doctro/features/startup_gate.dart';
import 'package:doctro/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for `StartupGate`'s destination logic, and coverage for
/// the branded intro animation layered on top of it.
///
/// The app used to open on a `SplashScreen` that showed the brand logo and
/// then waited on a 3s `Timer` before choosing between sign-in and the
/// dashboard - the destination was not known until the wait was over. That
/// choice now happens synchronously in `StartupGate`, from a flag already in
/// memory, so the destination widget is mounted (and doing its own startup
/// work) from the very first frame. A short animated logo reveal plays over
/// it for a fixed ~900ms and then removes itself; it never gates or changes
/// the destination, only what's drawn on top of it briefly.
///
/// `StartupGate` is booted directly rather than through `MyApp`, because `MyApp`
/// initializes Firebase, notifications and the chat providers, which need live
/// platform channels. The gate only reads one stored flag, so it can be
/// exercised on its own.
///
/// `LanguageLocalization.delegate` is deliberately omitted: it resolves
/// asynchronously, and with it the widget tree builds no child in every
/// `testWidgets` after the first. The gate does not depend on translations.
/// Swastu breathes in an endless idle loop, so a screen showing it never
/// "settles". Turning on the platform's reduce-motion setting (which
/// Swastu honours) lets pumpAndSettle finish, and covers that path too.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Settles past the intro. Its removal is a ~900ms wall-clock Timer, and
/// under reduced motion the intro's animations finish instantly, so
/// pumpAndSettle alone would return with that Timer still pending.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(WidgetTester tester, {required bool loggedIn}) async {
    // Keyed off the constant, not a literal: the stored name is "isLoggedIn",
    // and a hand-written literal here silently reads back as false.
    SharedPreferences.setMockInitialValues({
      Preferences.is_logged_in: loggedIn,
      'current_language_code': 'en',
      Preferences.name: 'Test Doctor',
    });
    await SharedPreferenceHelper.initWithPreferences(
        await SharedPreferences.getInstance());

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: const MaterialApp(home: StartupGate()),
    ));
  }

  group('StartupGate', () {
    testWidgets(
        'signed out mounts sign-in on the very first frame, under the intro',
        (tester) async {
      _reduceMotion(tester);
      await boot(tester, loggedIn: false);

      // Checked before pumpAndSettle: the destination must already be in the
      // tree on the first frame, not only after some wait resolves it. The
      // intro animation drawn over it does not change this.
      expect(find.byType(SignIn), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      // Drains the intro animation and the settings request SignInViewModel
      // issues on construction.
      await _settle(tester);
      expect(find.byType(SignIn), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a stored session mounts the dashboard shell on the very first frame, under the intro',
        (tester) async {
      _reduceMotion(tester);
      await boot(tester, loggedIn: true);

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(SignIn), findsNothing);

      await _settle(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the intro animation removes itself once its fixed beat elapses',
        (tester) async {
      _reduceMotion(tester);
      await boot(tester, loggedIn: false);

      // The intro is a Positioned.fill over the destination, so it is the
      // last (topmost) widget in the Stack while visible. Matched by its
      // zero insets rather than bare byType(Positioned): SignIn's own
      // decorative background blobs are also Positioned widgets, just not
      // full-bleed ones.
      Finder findPositionedFill() => find.byWidgetPredicate((widget) =>
          widget is Positioned &&
          widget.left == 0 &&
          widget.top == 0 &&
          widget.right == 0 &&
          widget.bottom == 0);

      expect(find.byType(Stack), findsWidgets);
      expect(findPositionedFill(), findsOneWidget);

      await _settle(tester);

      // Once settled, the gate returns the destination directly - no
      // intro overlay left behind.
      expect(findPositionedFill(), findsNothing);
      expect(find.byType(SignIn), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the destination does not change once time passes',
        (tester) async {
      _reduceMotion(tester);
      await boot(tester, loggedIn: false);
      await _settle(tester);

      // The old splash navigated away after 3 seconds. Waiting here, well
      // past the intro's own fixed beat, must not move the tree anywhere.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SignIn), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

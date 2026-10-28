import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/features/errors/error_utility_screen.dart';

/// Swastu breathes in an endless idle loop, so a screen showing it never
/// "settles". Turning on the platform's reduce-motion setting (which
/// Swastu honours) lets pumpAndSettle finish, and covers that path too.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  group('ErrorUtilityScreen', () {
    testWidgets('renders each kind with its title and default badge',
        (WidgetTester tester) async {
      _reduceMotion(tester);
      const cases = {
        ErrorUtilityKind.notFound: 'Not Found',
        ErrorUtilityKind.noInternet: 'No Internet',
        ErrorUtilityKind.internalError: 'Internal Error',
        ErrorUtilityKind.maintenance: 'Maintenance',
        ErrorUtilityKind.notAllowed: 'Not Allowed',
      };

      for (final entry in cases.entries) {
        await tester.pumpWidget(
          MaterialApp(home: ErrorUtilityScreen(kind: entry.key)),
        );
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Take Me Home'), findsOneWidget);
      }
    });

    testWidgets('invokes onAction instead of the default navigation',
        (WidgetTester tester) async {
      _reduceMotion(tester);
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorUtilityScreen(
            kind: ErrorUtilityKind.noInternet,
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Take Me Home'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('honors a custom badge label override',
        (WidgetTester tester) async {
      _reduceMotion(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorUtilityScreen(
            kind: ErrorUtilityKind.maintenance,
            badgeLabel: 'Come back in 8h 12m',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Come back in 8h 12m'), findsOneWidget);
    });
  });
}

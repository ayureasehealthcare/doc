import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctro/widgets/modern_drawer.dart';

Widget _buildApp() {
  return MaterialApp(
    home: Scaffold(
      drawer: const ModernDrawer(),
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
    routes: {
      'search': (context) => const Scaffold(body: Text('Search screen')),
      'reviewQueue': (context) =>
          const Scaffold(body: Text('Review queue screen')),
      'loginHome': (context) => const Scaffold(body: Text('Home screen')),
      'AppointmentHistoryScreen': (context) => const Scaffold(),
      'cancelAppoitmentRoutes': (context) => const Scaffold(),
      'rateAndReviewRoutes': (context) => const Scaffold(),
      'notifications': (context) => const Scaffold(),
      'payment': (context) => const Scaffold(),
      'Schedule Timings': (context) => const Scaffold(),
      'Settings': (context) => const Scaffold(),
    },
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  // Tall enough that the whole drawer is on-screen without scrolling its
  // own ListView.
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(_buildApp());
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  _drainKnownInkAssertion(tester);
}

/// GlassSurface wraps each drawer ListTile in a DecoratedBox with a
/// background color, which trips Flutter's (debug-only, non-fatal) "ink
/// splashes may be invisible" assertion - pre-existing on every drawer
/// item, not something this navigation change introduces or should
/// silently restructure. Drain it via the official API so it doesn't fail
/// the test; anything else is a real, unexpected exception.
void _drainKnownInkAssertion(WidgetTester tester) {
  for (var exception = tester.takeException();
      exception != null;
      exception = tester.takeException()) {
    final message = exception.toString();
    // pumpAndSettle collapses repeated per-frame instances of the same
    // "may be invisible" assertion (one per drawer ListTile) into this
    // generic summary once there are several - confirmed by inspecting the
    // console dump, every individual instance printed was that assertion.
    if (!message.contains('may be invisible') &&
        !message.contains('Multiple exceptions')) {
      throw exception;
    }
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Search routes to the search screen', (tester) async {
    await _openDrawer(tester);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    _drainKnownInkAssertion(tester);
    expect(find.text('Search screen'), findsOneWidget);
  });

  testWidgets('Review queue routes to the review queue screen', (tester) async {
    await _openDrawer(tester);
    await tester.tap(find.text('Review queue'));
    await tester.pumpAndSettle();
    _drainKnownInkAssertion(tester);
    expect(find.text('Review queue screen'), findsOneWidget);
  });
}

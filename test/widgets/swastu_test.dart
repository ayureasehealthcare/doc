import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/widgets/swastu.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('every mood has its pose art bundled', () {
    for (final mood in SwastuMood.values) {
      expect(File(Swastu.assetFor(mood)).existsSync(), isTrue,
          reason: 'missing ${Swastu.assetFor(mood)}');
    }
    expect(File('assets/brand/swastu_wordmark.png').existsSync(), isTrue);
  });

  testWidgets('shows the pose for its mood, with a name tag when large',
      (tester) async {
    await tester.pumpWidget(_host(const Swastu(mood: SwastuMood.greeting)));

    final image = tester.widget<Image>(find.byType(Image).first);
    expect((image.image as AssetImage).assetName,
        'assets/swastu/swastu_greeting.png');
    expect(find.byType(SwastuNameTag), findsOneWidget);
    expect(find.bySemanticsLabel('Swastu'), findsWidgets);

    await tester.pumpWidget(_host(const Swastu(size: 40)));
    expect(find.byType(SwastuNameTag), findsNothing);
  });

  testWidgets('breathes by default, and stays still when asked to',
      (tester) async {
    await tester.pumpWidget(_host(const Swastu()));
    expect(tester.hasRunningAnimations, isTrue);

    // Reduced motion: no idle animation at all.
    await tester.pumpWidget(_host(const Swastu(), reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    // Calm-down moods are still even with motion allowed.
    await tester.pumpWidget(_host(const Swastu(mood: SwastuMood.concerned)));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('tapping calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      Swastu(mood: SwastuMood.concerned, onTap: () => taps++),
    ));
    await tester.tap(find.byType(Swastu));
    expect(taps, 1);
  });

  testWidgets('SwastuSays shows the line next to a small Swastu',
      (tester) async {
    await tester.pumpWidget(_host(
      const SizedBox(
        width: 360,
        child: SwastuSays('Nothing needs your review right now.',
            mood: SwastuMood.happy),
      ),
      reduceMotion: true,
    ));
    expect(find.text('Nothing needs your review right now.'), findsOneWidget);
    final avatar = tester.widget<Swastu>(find.byType(Swastu));
    expect(avatar.mood, SwastuMood.happy);
    expect(avatar.size, lessThan(100));
  });
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_button.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Measures the colour the label is actually painted with, not the colour
  // the button asks for: the bug was a Text style overriding the button's
  // white foreground with the theme's dark text colour.
  Future<Color> labelColor(WidgetTester tester, OslerButton button,
      {bool dark = false}) async {
    AyurezeTheme.updateThemeMode(dark);
    await tester.pumpWidget(MaterialApp(
      theme: dark ? AyurezeTheme.darkTheme() : AyurezeTheme.lightTheme(),
      home: Scaffold(body: Center(child: button)),
    ));
    // Material animates text-colour changes; re-pumping one tree with a
    // different button would otherwise read a colour mid-transition.
    await tester.pumpAndSettle();
    final paragraph =
        tester.renderObject<RenderParagraph>(find.text(button.text));
    return paragraph.text.style!.color!;
  }

  tearDown(() => AyurezeTheme.updateThemeMode(false));

  testWidgets('every button style clears WCAG AA in light and dark mode',
      (tester) async {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      final primary = await labelColor(
          tester, OslerButton(text: 'Primary', onPressed: () {}),
          dark: dark);
      expect(primary, Colors.white, reason: '$mode primary');
      expect(_contrast(primary, AyurezeTheme.healingGreenFill),
          greaterThanOrEqualTo(4.5),
          reason: '$mode primary');

      final secondary = await labelColor(
          tester,
          OslerButton(
              text: 'Secondary',
              style: OslerButtonStyle.secondary,
              onPressed: () {}),
          dark: dark);
      expect(_contrast(secondary, AyurezeTheme.healingGreen10),
          greaterThanOrEqualTo(4.5),
          reason: '$mode secondary');

      for (final style in [OslerButtonStyle.outline, OslerButtonStyle.ghost]) {
        final color = await labelColor(tester,
            OslerButton(text: style.name, style: style, onPressed: () {}),
            dark: dark);
        // Transparent buttons sit on the page, so check against it.
        expect(_contrast(color, AyurezeTheme.canvas), greaterThanOrEqualTo(4.5),
            reason: '$mode ${style.name}');
      }

      final destructive = await labelColor(
          tester,
          OslerButton(
              text: 'Cancel',
              customColor: AyurezeTheme.remoteRedFill,
              onPressed: () {}),
          dark: dark);
      expect(_contrast(destructive, AyurezeTheme.remoteRedFill),
          greaterThanOrEqualTo(4.5),
          reason: '$mode destructive');
    }
  });

  testWidgets('a custom fill gets whichever ink contrasts more',
      (tester) async {
    final onDark = await labelColor(
        tester,
        OslerButton(
            text: 'Dark fill',
            customColor: AyurezeTheme.healingGreen100,
            onPressed: () {}));
    expect(onDark, Colors.white);

    final onPale = await labelColor(
        tester,
        OslerButton(
            text: 'Pale fill',
            customColor: AyurezeTheme.sunshineYellow10,
            onPressed: () {}));
    expect(onPale, AyurezeTheme.healingGreen100);
  });

  testWidgets('loading keeps the brand fill so the spinner stays legible',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AyurezeTheme.lightTheme(),
      home: Scaffold(
        body: Center(
          child: OslerButton(text: 'Save', isLoading: true, onPressed: () {}),
        ),
      ),
    ));

    final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator));
    expect(spinner.color, Colors.white);

    final fill = tester
        .widget<Material>(find.descendant(
            of: find.byType(ElevatedButton), matching: find.byType(Material)))
        .color;
    expect(fill, AyurezeTheme.healingGreenFill);
  });
}

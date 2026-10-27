import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/widgets/astra_fill_display.dart';
import 'package:doctro/widgets/content_origin_badge.dart';

const _badge = ContentOriginBadge(origin: ContentOrigin.astraSuggestion);

void main() {
  testWidgets('intake header gives the origin badge its full width',
      (tester) async {
    // Found by running the mock flow on a 390px phone: inside the title
    // column, next to the severity pill, the badge had too little room and
    // was clipped under the pill. How that shows depends on font metrics
    // (overflow on a device, squeezing with the test font), so assert the
    // font-independent fact: the badge is laid out at its natural width.
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Center(child: _badge))));
    final naturalWidth = tester.getSize(find.byType(ContentOriginBadge)).width;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: AstraFillDisplayWidget(
            patientId: 'p1',
            preloadedData: {
              'chief_complaint': 'Dry cough',
              'severity_score': 5,
              'timestamp': '2026-10-17T09:30:00Z',
            },
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ContentOriginBadge), findsOneWidget);
    expect(tester.getSize(find.byType(ContentOriginBadge)).width,
        moreOrLessEquals(naturalWidth));
    expect(find.text('Severity: 5/10'), findsOneWidget);

    // The severity pill sits on the badge line below the title, not beside
    // it: beside it, Inter's wider glyphs squeezed the title to three lines.
    final title = tester.getRect(find.text('Astra AI Health Intake'));
    final pill = tester.getRect(find.byType(SeverityPill));
    expect(pill.top, greaterThanOrEqualTo(title.bottom));
  });

  test('every severity band clears AA as a tint pair', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final score in [1, 3, 4, 6, 7, 10, '5', 'n/a']) {
      final (bg, fg) = SeverityPill.colorsFor(score);
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$score');
    }
  });
}

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
  });
}

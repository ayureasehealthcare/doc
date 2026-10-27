import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/features/prescription/astra/prescription_screen.dart';
import 'package:doctro/widgets/content_origin_badge.dart';

void main() {
  testWidgets('PrescriptionScreen builds correctly and catches map type error',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PrescriptionScreen(
          patientId: '123',
          patientName: 'Test Patient',
          patientPhone: '1234567890',
          doctorId: 'DOC1',
          astraFillData: const {
            'extracted_symptoms': ['fever', 'cough'],
          },
        ),
      ),
    ));

    expect(find.text('Prescription'), findsOneWidget);
    expect(find.text('Test Patient'), findsOneWidget);

    // Diagnosis was pre-filled by Astra from the intake, so both the intake
    // summary and the diagnosis field are labelled as Astra's.
    Finder badge(ContentOrigin origin) => find.byWidgetPredicate(
        (w) => w is ContentOriginBadge && w.origin == origin);
    expect(badge(ContentOrigin.astraSuggestion), findsNWidgets(2));
    expect(badge(ContentOrigin.doctorApproved), findsNothing);

    // Once the doctor edits it, the diagnosis is theirs.
    await tester.enterText(
        find.widgetWithText(TextField, 'Diagnosis'), 'Viral bronchitis');
    await tester.pump();
    expect(badge(ContentOrigin.astraSuggestion), findsOneWidget);
    expect(badge(ContentOrigin.doctorApproved), findsOneWidget);

    // Cleared: nothing to label.
    await tester.enterText(find.widgetWithText(TextField, 'Diagnosis'), '');
    await tester.pump();
    expect(badge(ContentOrigin.doctorApproved), findsNothing);
    expect(badge(ContentOrigin.astraSuggestion), findsOneWidget);
  });
}

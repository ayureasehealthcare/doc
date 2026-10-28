import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/features/prescription/astra/prescription_payload.dart';
import 'package:doctro/features/prescription/pending_prescriptions_screen.dart';
import 'package:doctro/models/pending_prescription.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

PendingPrescription _rx(String id, String patient, {String? doctor}) =>
    PendingPrescription(
      id: id,
      patientName: patient,
      doctorId: doctor,
      diagnosis: 'Dry cough',
      medicines: const [
        PendingMedicine(
            name: 'Sitopaladi Churna',
            dosage: '3 g',
            frequency: 'twice_daily',
            durationDays: 7),
      ],
    );

Future<void> _pump(WidgetTester tester, Widget screen) async {
  // Swastu's idle loop never settles unless motion is reduced.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'doctorId': 'doc-1'});
    await SharedPreferenceHelper.initWithPreferences(
        await SharedPreferences.getInstance());
  });

  group('PendingPrescription.listFrom', () {
    test('reads a wrapped list, skipping records with no id', () {
      final items = PendingPrescription.listFrom({
        'prescriptions': [
          {
            'prescription_id': 'rx-1',
            'patient_name': 'Asha',
            'diagnosis': 'Cough',
            'medicines': [
              {'name': 'Tulsi', 'dosage': '5 ml', 'duration_days': 5},
            ],
            'created_at': '2026-10-28T09:00:00Z',
          },
          {'patient_name': 'No id'},
        ],
      });

      expect(items, hasLength(1));
      expect(items.single.id, 'rx-1');
      expect(items.single.medicines.single.summary, '5 ml · 5 days');
      expect(items.single.createdAt, isNotNull);
    });

    test('reads a bare list and an unexpected body as empty', () {
      expect(
          PendingPrescription.listFrom([
            {'id': 7, 'patient_name': 'Ravi'}
          ]).single.id,
          '7');
      expect(PendingPrescription.listFrom('oops'), isEmpty);
    });
  });

  test('dosage text prefers the dosage keys, else lists short values', () {
    expect(PrescriptionPayload.dosageText({'suggested_dosage': '3 g twice'}),
        '3 g twice');
    expect(PrescriptionPayload.dosageText({'dose': '5 ml', 'per_day': 2}),
        'dose: 5 ml\nper day: 2');
    expect(PrescriptionPayload.dosageText({}), 'No suggestion returned.');
  });

  testWidgets('lists my pending prescriptions, not another doctor\'s',
      (tester) async {
    await _pump(
      tester,
      PendingPrescriptionsScreen(
        loader: () async => [
          _rx('rx-1', 'Asha Rao', doctor: 'doc-1'),
          _rx('rx-2', 'Ravi Kumar'),
          _rx('rx-3', 'Someone Else', doctor: 'doc-9'),
        ],
      ),
    );

    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Someone Else'), findsNothing);
    expect(find.textContaining('3 g · twice daily · 7 days'), findsNWidgets(2));
  });

  testWidgets('approving removes it; a failed approve keeps it',
      (tester) async {
    final approved = <String>[];
    await _pump(
      tester,
      PendingPrescriptionsScreen(
        loader: () async => [_rx('rx-1', 'Asha Rao'), _rx('bad', 'Ravi')],
        onApprove: (rx) async {
          if (rx.id == 'bad') throw AstraApiException('Already sent', 409);
          approved.add(rx.id);
        },
      ),
    );

    await tester.tap(find.text('Approve & send').first);
    await tester.pumpAndSettle();
    expect(approved, ['rx-1']);
    expect(find.text('Asha Rao'), findsNothing);

    await tester.tap(find.text('Approve & send'));
    await tester.pumpAndSettle();
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('Already sent'), findsOneWidget);
  });

  testWidgets('rejecting asks for a reason and sends it', (tester) async {
    String? sentReason;
    await _pump(
      tester,
      PendingPrescriptionsScreen(
        loader: () async => [_rx('rx-1', 'Asha Rao')],
        onReject: (rx, reason) async => sentReason = reason,
      ),
    );

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Wrong patient');
    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(sentReason, 'Wrong patient');
    expect(find.text('Asha Rao'), findsNothing);
    expect(find.text('Nothing to approve'), findsOneWidget);
  });

  testWidgets('a load failure shows the server\'s message with Retry',
      (tester) async {
    await _pump(
      tester,
      PendingPrescriptionsScreen(
        loader: () async => throw AstraApiException('Doctor only', 403),
      ),
    );

    expect(find.text("Couldn't load prescriptions"), findsOneWidget);
    expect(find.text('Doctor only'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

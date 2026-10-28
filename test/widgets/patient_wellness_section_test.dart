import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/models/patient_wellness.dart';
import 'package:doctro/models/sharing_consent.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/widgets/patient_wellness_section.dart';
import 'package:doctro/widgets/sharing_consent_guard.dart';

Widget _host(WellnessLoader loader,
        {SharingConsent consent = SharingConsent.full}) =>
    MaterialApp(
      home: Scaffold(
        body: SharingConsentScope(
          consent: consent,
          child: SingleChildScrollView(
            child: PatientWellnessSection(patientId: '42', loader: loader),
          ),
        ),
      ),
    );

void main() {
  test('the wellness endpoint is gated off until astra ships it', () async {
    // Guard against flipping the flag without wiring the real endpoint:
    // while it is off, the service must not touch the network.
    expect(AstraApiService.wellnessEndpointLive, isFalse);
    expect(await AstraApiService().getPatientWellness('42'), isNull);
  });

  testWidgets('shows "not available yet" when the service returns null',
      (tester) async {
    await tester.pumpWidget(_host((_) async => null));
    await tester.pump();

    expect(find.text('Wellness'), findsOneWidget);
    expect(find.text('Patient-reported'), findsOneWidget);
    expect(find.textContaining('Not a clinical measurement'), findsOneWidget);
    expect(find.text('Not available yet'), findsOneWidget);
  });

  testWidgets('treats a throwing loader as not available', (tester) async {
    await tester.pumpWidget(_host((_) async => throw Exception('boom')));
    await tester.pump();
    expect(find.text('Not available yet'), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing is logged', (tester) async {
    await tester.pumpWidget(_host((_) async => const PatientWellness()));
    await tester.pump();
    expect(find.text('No wellness entries'), findsOneWidget);
  });

  testWidgets('lists recent entries and only active goals', (tester) async {
    String? requestedId;
    await tester.pumpWidget(_host((id) async {
      requestedId = id;
      return PatientWellness(
        entries: [
          for (var day = 20; day >= 11; day--)
            WellnessEntry(
              dateKey: '2026-10-$day',
              sleepHours: 7,
              movementMinutes: 20,
              mood: 4,
            ),
        ],
        goals: const [
          WellnessGoal(id: '1', title: 'Sleep 7+ hours'),
          WellnessGoal(id: '2', title: 'Walk daily', achieved: true),
        ],
      );
    }));
    await tester.pump();

    expect(requestedId, '42');
    // 10 entries supplied, default cap is the most recent 7.
    expect(find.textContaining('Sleep 7h'), findsNWidgets(7));
    expect(find.textContaining('Mood Good'), findsNWidgets(7));
    expect(find.text('Tue 20 Oct'), findsOneWidget);
    expect(find.text('Tue 13 Oct'), findsNothing);
    expect(find.text('Active goals'), findsOneWidget);
    expect(find.text('Sleep 7+ hours'), findsOneWidget);
    expect(find.text('Walk daily'), findsNothing);
  });

  testWidgets('withholds the log unless consent is full, without fetching',
      (tester) async {
    for (final consent in [SharingConsent.limited, SharingConsent.unknown]) {
      var calls = 0;
      await tester.pumpWidget(_host((_) async {
        calls++;
        return const PatientWellness();
      }, consent: consent));
      await tester.pump();

      expect(calls, 0, reason: '$consent must not fetch');
      expect(find.text('Not shared with you'), findsOneWidget);
      expect(find.text('Patient-reported'), findsOneWidget);
    }
  });

  testWidgets('fetches once consent upgrades to full', (tester) async {
    var calls = 0;
    Future<PatientWellness?> loader(String _) async {
      calls++;
      return const PatientWellness();
    }

    await tester.pumpWidget(_host(loader, consent: SharingConsent.unknown));
    await tester.pump();
    expect(calls, 0);

    await tester.pumpWidget(_host(loader));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('No wellness entries'), findsOneWidget);
  });
}

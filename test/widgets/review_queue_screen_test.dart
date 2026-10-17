import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/features/autopilot/review_queue_screen.dart';
import 'package:doctro/models/autopilot_action.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/widgets/content_origin_badge.dart';

final _actions = [
  AutopilotAction(
    id: 'a1',
    kind: AutopilotActionKind.careGap,
    title: 'No check-in for 5 days',
    detail: 'Patient has missed their daily symptom check-ins.',
    patientName: 'Asha Rao',
    createdAt: DateTime(2026, 10, 15, 9, 30),
    requiresSignOff: true,
  ),
  const AutopilotAction(
    id: 'a2',
    kind: AutopilotActionKind.followUp,
    title: 'Suggest a 2-week follow-up',
  ),
];

Widget _host({
  PendingActionsLoader? loader,
  AutopilotActionResolver? onAcknowledge,
  AutopilotActionResolver? onDismiss,
  String? doctorId = 'doc-1',
}) =>
    MaterialApp(
      home: ReviewQueueScreen(
        doctorId: doctorId,
        loader: loader ?? (_) async => _actions,
        onAcknowledge: onAcknowledge ?? (_) async => true,
        onDismiss: onDismiss ?? (_) async => true,
      ),
    );

void main() {
  test('the service stubs return nothing and resolve nothing', () async {
    final api = AstraApiService();
    expect(await api.getPendingAutopilotActions('doc-1'), isEmpty);
    expect(await api.acknowledgeAutopilotAction('a1'), isFalse);
    expect(await api.dismissAutopilotAction('a1'), isFalse);
  });

  testWidgets('loads for the doctor, then shows the empty state',
      (tester) async {
    final completer = Completer<List<AutopilotAction>>();
    String? askedFor;
    await tester.pumpWidget(_host(loader: (id) {
      askedFor = id;
      return completer.future;
    }));

    expect(find.text('Loading review queue…'), findsOneWidget);
    expect(askedFor, 'doc-1');

    completer.complete(const []);
    await tester.pump();
    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets('lists each action labelled as an Astra suggestion',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(find.text('No check-in for 5 days'), findsOneWidget);
    expect(find.text('Care gap'), findsOneWidget);
    expect(find.text('Needs sign-off'), findsOneWidget);
    expect(find.textContaining('Asha Rao'), findsOneWidget);
    expect(find.text('Suggest a 2-week follow-up'), findsOneWidget);
    expect(find.text('Suggested follow-up'), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is ContentOriginBadge &&
            w.origin == ContentOrigin.astraSuggestion),
        findsNWidgets(2));
  });

  testWidgets('acknowledge and dismiss remove the item on success',
      (tester) async {
    final acknowledged = <String>[];
    final dismissed = <String>[];
    await tester.pumpWidget(_host(
      onAcknowledge: (id) async {
        acknowledged.add(id);
        return true;
      },
      onDismiss: (id) async {
        dismissed.add(id);
        return true;
      },
    ));
    await tester.pump();

    await tester.tap(find.text('Acknowledge').first);
    await tester.pump();
    expect(acknowledged, ['a1']);
    expect(find.text('No check-in for 5 days'), findsNothing);
    expect(find.text('Acknowledged'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    expect(dismissed, ['a2']);
    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets('a failed update keeps the item and says so', (tester) async {
    await tester.pumpWidget(_host(onAcknowledge: (_) async => false));
    await tester.pump();

    await tester.tap(find.text('Acknowledge').first);
    await tester.pump();
    expect(find.text('No check-in for 5 days'), findsOneWidget);
    expect(find.textContaining('Couldn\'t update'), findsOneWidget);

    // A throwing resolver is the same failure, not a crash.
    await tester.pumpWidget(_host(onDismiss: (_) async => throw 'boom'));
    await tester.pump();
    await tester.tap(find.text('Dismiss').first);
    await tester.pump();
    expect(find.text('No check-in for 5 days'), findsOneWidget);
  });

  testWidgets('buttons are disabled while a request is in flight',
      (tester) async {
    final pending = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(_host(onAcknowledge: (_) {
      calls++;
      return pending.future;
    }));
    await tester.pump();

    await tester.tap(find.text('Acknowledge').first);
    await tester.pump();
    await tester.tap(find.text('Dismiss').first, warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    pending.complete(true);
    await tester.pump();
    expect(find.text('No check-in for 5 days'), findsNothing);
  });

  testWidgets('load failure offers a retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(_host(loader: (_) async {
      attempts++;
      if (attempts == 1) throw Exception('offline');
      return const [];
    }));
    await tester.pump();
    expect(find.text('Couldn\'t load the review queue'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets('no signed-in doctor is an error, not an empty queue',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(
      doctorId: '',
      loader: (_) async {
        calls++;
        return const [];
      },
    ));
    await tester.pump();
    expect(calls, 0);
    expect(find.text('Couldn\'t load the review queue'), findsOneWidget);
  });
}

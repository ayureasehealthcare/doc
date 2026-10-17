import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/models/sharing_consent.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/widgets/sharing_consent_guard.dart';

const _limited = SharingConsentBanner.limitedTitle;

/// Records the consent the guard publishes to its subtree.
class _ScopeProbe extends StatelessWidget {
  final void Function(SharingConsent) onBuild;
  const _ScopeProbe(this.onBuild);

  @override
  Widget build(BuildContext context) {
    onBuild(SharingConsentScope.of(context));
    return const Text('record body');
  }
}

Widget _host({
  required String? patientId,
  required SharingConsentLoader loader,
  void Function(SharingConsent)? onScope,
  String? doctorId = 'doc-1',
}) =>
    MaterialApp(
      home: Scaffold(
        body: SharingConsentGuard(
          patientId: patientId,
          doctorId: doctorId,
          loader: loader,
          child: _ScopeProbe(onScope ?? (_) {}),
        ),
      ),
    );

void main() {
  group('SharingConsent.fromJson', () {
    test('maps share_full_record, defaulting to unknown', () {
      expect(SharingConsent.fromJson({'share_full_record': true}),
          SharingConsent.full);
      expect(SharingConsent.fromJson({'share_full_record': false}),
          SharingConsent.limited);
      expect(
          SharingConsent.fromJson({
            'data': {'share_full_record': true}
          }),
          SharingConsent.full);
      expect(SharingConsent.fromJson({}), SharingConsent.unknown);
      expect(SharingConsent.fromJson({'share_full_record': 'yes'}),
          SharingConsent.unknown);
    });
  });

  test('the service stub never reports full access', () async {
    expect(await AstraApiService().getSharingConsent('doc-1', 'pat-1'),
        SharingConsent.unknown);
  });

  testWidgets('shows a checking banner, then nothing once consent is full',
      (tester) async {
    final completer = Completer<SharingConsent>();
    final seen = <SharingConsent>[];
    String? askedDoctor, askedPatient;

    await tester.pumpWidget(_host(
      patientId: 'pat-1',
      loader: (d, p) {
        askedDoctor = d;
        askedPatient = p;
        return completer.future;
      },
      onScope: seen.add,
    ));

    // While loading the record is visible but flagged, and descendants
    // are told "unknown" rather than "full".
    expect(find.text('record body'), findsOneWidget);
    expect(find.textContaining('Checking what the patient'), findsOneWidget);
    expect(seen.last, SharingConsent.unknown);
    expect(askedDoctor, 'doc-1');
    expect(askedPatient, 'pat-1');

    completer.complete(SharingConsent.full);
    await tester.pump();

    expect(find.textContaining('Checking what the patient'), findsNothing);
    expect(find.text(_limited), findsNothing);
    expect(find.text('record body'), findsOneWidget);
    expect(seen.last, SharingConsent.full);
  });

  testWidgets('limited consent shows the banner and keeps the screen',
      (tester) async {
    await tester.pumpWidget(_host(
      patientId: 'pat-1',
      loader: (_, __) async => SharingConsent.limited,
    ));
    await tester.pump();

    expect(find.text(_limited), findsOneWidget);
    expect(
        find.textContaining('haven\'t turned on full-record'), findsOneWidget);
    expect(find.text('record body'), findsOneWidget);
  });

  testWidgets('unknown and failed lookups are treated as limited',
      (tester) async {
    await tester.pumpWidget(_host(
      patientId: 'pat-1',
      loader: (_, __) async => SharingConsent.unknown,
    ));
    await tester.pump();
    expect(find.text(_limited), findsOneWidget);
    expect(find.textContaining('couldn\'t be confirmed'), findsOneWidget);

    var seen = SharingConsent.full;
    await tester.pumpWidget(_host(
      patientId: 'pat-2',
      loader: (_, __) async => throw Exception('network'),
      onScope: (c) => seen = c,
    ));
    await tester.pump();
    expect(find.text(_limited), findsOneWidget);
    expect(seen, SharingConsent.unknown);
  });

  testWidgets('missing ids never call the loader and stay limited',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(
      patientId: null,
      loader: (_, __) async {
        calls++;
        return SharingConsent.full;
      },
    ));
    await tester.pump();
    expect(calls, 0);
    expect(find.text(_limited), findsOneWidget);

    await tester.pumpWidget(_host(
      patientId: 'pat-1',
      doctorId: '',
      loader: (_, __) async {
        calls++;
        return SharingConsent.full;
      },
    ));
    await tester.pump();
    expect(calls, 0);
    expect(find.text(_limited), findsOneWidget);
  });

  testWidgets('a stale answer for a previous patient is discarded',
      (tester) async {
    final first = Completer<SharingConsent>();
    final second = Completer<SharingConsent>();
    final pending = {'pat-1': first, 'pat-2': second};
    Future<SharingConsent> loader(String _, String p) => pending[p]!.future;

    await tester.pumpWidget(_host(patientId: 'pat-1', loader: loader));
    await tester.pumpWidget(_host(patientId: 'pat-2', loader: loader));

    second.complete(SharingConsent.limited);
    await tester.pump();
    first.complete(SharingConsent.full); // late answer for pat-1
    await tester.pump();

    expect(find.text(_limited), findsOneWidget);
  });

  testWidgets('with no guard above, scope reads unknown', (tester) async {
    SharingConsent? seen;
    await tester.pumpWidget(MaterialApp(home: _ScopeProbe((c) => seen = c)));
    expect(seen, SharingConsent.unknown);
  });
}

import 'package:doctro/services/doctor_id_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the first candidate astra knows, skipping blanks and N_A',
      () async {
    final asked = <String>[];
    final id = await DoctorIdResolver.resolve(
      [null, '', 'N_A', 'firebase-uid', 'firebase-uid', 'DOC-2026-AB12'],
      (id) async {
        asked.add(id);
        return id == 'DOC-2026-AB12';
      },
    );

    expect(id, 'DOC-2026-AB12');
    // Each distinct id is checked once.
    expect(asked, ['firebase-uid', 'DOC-2026-AB12']);
  });

  test('null when astra knows none of them', () async {
    expect(
        await DoctorIdResolver.resolve(['a', 'b'], (_) async => false), isNull);
  });

  test('a network error propagates instead of reading as not found', () {
    expect(
      DoctorIdResolver.resolve(['a'], (_) async => throw Exception('offline')),
      throwsException,
    );
  });
}

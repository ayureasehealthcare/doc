import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/models/patient_wellness.dart';

void main() {
  test('parses the patient app keys and sorts entries newest first', () {
    final wellness = PatientWellness.fromJson({
      'entries': [
        {'date_key': '2026-10-10', 'sleep_hours': 6, 'mood': 2},
        {
          'date_key': '2026-10-12',
          'sleep_hours': 7.5,
          'movement_minutes': 30,
          'relaxation_minutes': 15,
          'mood': 5,
          'note': 'Felt good',
        },
      ],
      'goals': [
        {'id': 'g1', 'title': 'Sleep 7+ hours', 'achieved': false},
        {'id': 'g2', 'title': 'Walk daily', 'achieved': true},
      ],
    });

    expect(
        wellness.entries.map((e) => e.dateKey), ['2026-10-12', '2026-10-10']);
    final latest = wellness.entries.first;
    expect(latest.sleepHours, 7.5);
    expect(latest.movementMinutes, 30);
    expect(latest.relaxationMinutes, 15);
    expect(latest.moodLabel, 'Great');
    expect(latest.note, 'Felt good');
    expect(wellness.entries.last.sleepHours, 6.0);
    expect(wellness.activeGoals.map((g) => g.title), ['Sleep 7+ hours']);
  });

  test('unwraps a data envelope', () {
    final wellness = PatientWellness.fromJson({
      'success': true,
      'data': {
        'entries': [
          {'date_key': '2026-10-12', 'mood': 3}
        ],
      },
    });
    expect(wellness.entries.single.moodLabel, 'Okay');
    expect(wellness.goals, isEmpty);
  });

  test('skips malformed items instead of throwing', () {
    final wellness = PatientWellness.fromJson({
      'entries': [
        'not a map',
        {'sleep_hours': 8}, // no date_key
        {'date_key': '2026-10-12', 'mood': 9}, // out-of-range mood
      ],
      'goals': [
        {'id': 'x'}, // no title
      ],
    });
    expect(wellness.entries.single.moodLabel, isNull);
    expect(wellness.goals, isEmpty);
  });

  test('missing lists produce an empty result', () {
    expect(PatientWellness.fromJson({}).isEmpty, isTrue);
    expect(PatientWellness.fromJson({'entries': 'oops'}).isEmpty, isTrue);
  });
}

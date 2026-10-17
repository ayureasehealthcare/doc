/// Patient-reported wellness self-tracking (sleep, movement, relaxation,
/// mood) plus the patient's own goals, as logged in the AyurEze patient
/// app. This is NOT clinical measurement - nothing here is verified,
/// device-captured or entered by a clinician.
///
/// Field names mirror the patient app's local JSON
/// (`WellnessEntry.toJson` / `WellnessGoal.toJson` in
/// ayureasehealthcare/Patientapp), which is the only concrete shape that
/// exists today. The server response for
/// GET /api/companion/wellness/{patient_id} is UNCONFIRMED: the endpoint
/// does not exist yet, so re-check these keys against the real astra
/// contract when it lands.
class PatientWellness {
  /// Newest first.
  final List<WellnessEntry> entries;
  final List<WellnessGoal> goals;

  const PatientWellness({this.entries = const [], this.goals = const []});

  bool get isEmpty => entries.isEmpty && goals.isEmpty;

  /// Goals the patient hasn't marked achieved.
  List<WellnessGoal> get activeGoals =>
      goals.where((g) => !g.achieved).toList();

  /// Accepts `{entries, goals}` either at the top level or nested under
  /// `data`. Malformed items are skipped rather than failing the whole
  /// section.
  factory PatientWellness.fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final entries = _mapList(body['entries'], WellnessEntry.tryParse)
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    final goals = _mapList(body['goals'], WellnessGoal.tryParse);
    return PatientWellness(entries: entries, goals: goals);
  }

  static List<T> _mapList<T>(
      dynamic raw, T? Function(Map<String, dynamic>) parse) {
    if (raw is! List) return [];
    final result = <T>[];
    for (final item in raw) {
      if (item is Map) {
        final parsed = parse(Map<String, dynamic>.from(item));
        if (parsed != null) result.add(parsed);
      }
    }
    return result;
  }
}

/// One calendar day of the patient's wellness log.
class WellnessEntry {
  final String dateKey; // yyyy-MM-dd
  final double? sleepHours;
  final int? movementMinutes;
  final int? relaxationMinutes;
  final int? mood; // 1 (low) - 5 (great)
  final String? note;

  const WellnessEntry({
    required this.dateKey,
    this.sleepHours,
    this.movementMinutes,
    this.relaxationMinutes,
    this.mood,
    this.note,
  });

  /// Same labels the patient picks from in the patient app, so the doctor
  /// reads the scale the patient actually used.
  static const moodLabels = ['', 'Low', 'Rough', 'Okay', 'Good', 'Great'];

  String? get moodLabel =>
      (mood != null && mood! >= 1 && mood! <= 5) ? moodLabels[mood!] : null;

  static WellnessEntry? tryParse(Map<String, dynamic> json) {
    final dateKey = json['date_key'];
    if (dateKey is! String || dateKey.isEmpty) return null;
    return WellnessEntry(
      dateKey: dateKey,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      movementMinutes: (json['movement_minutes'] as num?)?.toInt(),
      relaxationMinutes: (json['relaxation_minutes'] as num?)?.toInt(),
      mood: (json['mood'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }
}

/// A goal the patient set for themselves, e.g. "Sleep 7+ hours".
class WellnessGoal {
  final String id;
  final String title;
  final bool achieved;

  const WellnessGoal({
    required this.id,
    required this.title,
    this.achieved = false,
  });

  static WellnessGoal? tryParse(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! String || title.isEmpty) return null;
    return WellnessGoal(
      id: json['id']?.toString() ?? title,
      title: title,
      achieved: json['achieved'] == true,
    );
  }
}

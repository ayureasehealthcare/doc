/// A prescription waiting in astra's review queue
/// (`GET api/v1/api/prescriptions/queue/pending`).
///
/// astra's OpenAPI documents no response schema for the queue, so this reads
/// the record defensively: the request it was created from
/// (`CreatePrescriptionRequest`) names the likely keys, and ids may come as
/// `prescription_id` or `id`.
class PendingPrescription {
  final String id;
  final String patientName;
  final String? patientPhone;
  final String? patientId;
  final String? doctorId;
  final String diagnosis;
  final List<PendingMedicine> medicines;
  final DateTime? createdAt;

  const PendingPrescription({
    required this.id,
    required this.patientName,
    this.patientPhone,
    this.patientId,
    this.doctorId,
    required this.diagnosis,
    this.medicines = const [],
    this.createdAt,
  });

  static String? _text(Map json, List<String> keys) {
    for (final k in keys) {
      final v = json[k]?.toString().trim();
      if (v != null && v.isNotEmpty && v != 'null') return v;
    }
    return null;
  }

  /// Null when the record has no id, since it can't be approved or rejected.
  static PendingPrescription? fromJson(Map json) {
    final id = _text(json, ['prescription_id', 'id', '_id']);
    if (id == null) return null;
    final rawMeds = json['medicines'] ?? json['prescriptions'];
    return PendingPrescription(
      id: id,
      patientName: _text(json, ['patient_name', 'patient']) ?? 'Patient',
      patientPhone: _text(json, ['patient_phone', 'phone']),
      patientId: _text(json, ['patient_id']),
      doctorId: _text(json, ['doctor_id']),
      diagnosis: _text(json, ['diagnosis']) ?? '',
      medicines: [
        if (rawMeds is List)
          for (final m in rawMeds)
            if (m is Map) PendingMedicine.fromJson(m),
      ],
      createdAt:
          DateTime.tryParse(_text(json, ['created_at', 'createdAt']) ?? ''),
    );
  }

  /// Reads the queue response: a bare list, or a list under
  /// `prescriptions` / `pending` / `data` / `items`.
  static List<PendingPrescription> listFrom(dynamic body) {
    dynamic list = body;
    if (body is Map) {
      list = body['prescriptions'] ??
          body['pending'] ??
          body['data'] ??
          body['items'] ??
          const [];
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(PendingPrescription.fromJson)
        .whereType<PendingPrescription>()
        .toList();
  }
}

class PendingMedicine {
  final String name;
  final String? dosage;
  final String? frequency;
  final int? durationDays;

  const PendingMedicine({
    required this.name,
    this.dosage,
    this.frequency,
    this.durationDays,
  });

  factory PendingMedicine.fromJson(Map json) => PendingMedicine(
        name: PendingPrescription._text(
                json, ['name', 'medicine_name', 'medicine']) ??
            'Medicine',
        dosage: PendingPrescription._text(json, ['dosage', 'dose']),
        frequency: PendingPrescription._text(json, ['frequency', 'schedule']),
        durationDays: int.tryParse(
            PendingPrescription._text(json, ['duration_days', 'duration']) ??
                ''),
      );

  /// "1 tablet · twice daily · 5 days", from whichever parts are known.
  String get summary => [
        if (dosage != null) dosage!,
        if (frequency != null) frequency!.replaceAll('_', ' '),
        if (durationDays != null) '$durationDays days',
      ].join(' · ');
}

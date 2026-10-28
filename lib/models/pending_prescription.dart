/// A prescription waiting in astra's review queue
/// (`GET api/v1/api/prescriptions/queue/pending`).
///
/// The OpenAPI documents no response schema. Seen live (2026-10-28):
/// `{success, count, queue: [{id (uuid), prescription_id ("RXXX-…"),
/// patient_id, doctor_id, diagnosis, status, prescribed_at,
/// prescribed_medicines: [{medicine_name, dose, schedule, timing, duration,
/// quantity, shopify_variant_id, …}]}]}`. The record has no patient name or
/// phone; [withPatient] adds them from the patient's profile. Other likely
/// keys are still read in case the shape changes.
class PendingPrescription {
  final String id;
  final String? patientName;
  final String? patientPhone;
  final String? patientId;
  final String? doctorId;
  final String diagnosis;
  final List<PendingMedicine> medicines;
  final DateTime? createdAt;

  const PendingPrescription({
    required this.id,
    this.patientName,
    this.patientPhone,
    this.patientId,
    this.doctorId,
    required this.diagnosis,
    this.medicines = const [],
    this.createdAt,
  });

  /// Name to show and to send with an approval (astra requires one).
  String get displayName => patientName ?? 'Patient';

  /// Medicines with a store variant: the ones that can go in the patient's
  /// Shopify cart.
  int get linkedCount => medicines.where((m) => m.linked).length;

  PendingPrescription withPatient({String? name, String? phone}) =>
      PendingPrescription(
        id: id,
        patientName: patientName ?? name,
        patientPhone: patientPhone ?? phone,
        patientId: patientId,
        doctorId: doctorId,
        diagnosis: diagnosis,
        medicines: medicines,
        createdAt: createdAt,
      );

  static String? _text(Map json, List<String> keys) {
    for (final k in keys) {
      final v = json[k]?.toString().trim();
      if (v != null && v.isNotEmpty && v != 'null') return v;
    }
    return null;
  }

  /// Null when the record has no id, since it can't be approved or rejected.
  /// The approve/reject path takes `prescription_id` (RXXX-…), not the row
  /// uuid in `id`.
  static PendingPrescription? fromJson(Map json) {
    final id = _text(json, ['prescription_id', 'id', '_id']);
    if (id == null) return null;
    final rawMeds = json['prescribed_medicines'] ??
        json['medicines'] ??
        json['prescriptions'];
    return PendingPrescription(
      id: id,
      patientName: _text(json, ['patient_name']),
      patientPhone: _text(json, ['patient_phone']),
      patientId: _text(json, ['patient_id']),
      doctorId: _text(json, ['doctor_id']),
      diagnosis: _text(json, ['diagnosis']) ?? '',
      medicines: [
        if (rawMeds is List)
          for (final m in rawMeds)
            if (m is Map) PendingMedicine.fromJson(m),
      ],
      createdAt: DateTime.tryParse(
          _text(json, ['prescribed_at', 'created_at', 'createdAt']) ?? ''),
    );
  }

  /// Reads the queue response: `queue` (live), or a bare list, or a list
  /// under `prescriptions` / `pending` / `data` / `items`.
  static List<PendingPrescription> listFrom(dynamic body) {
    dynamic list = body;
    if (body is Map) {
      list = body['queue'] ??
          body['prescriptions'] ??
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

  /// Has a Shopify variant, so it can go in the patient's cart.
  final bool linked;

  const PendingMedicine({
    required this.name,
    this.dosage,
    this.frequency,
    this.durationDays,
    this.linked = false,
  });

  factory PendingMedicine.fromJson(Map json) {
    String? t(List<String> k) => PendingPrescription._text(json, k);
    // Stored as text ("5 days") or a number.
    final duration = t(['duration_days', 'duration']);
    return PendingMedicine(
      name: t(['medicine_name', 'name', 'medicine']) ?? 'Medicine',
      dosage: t(['dose', 'dosage']),
      frequency: t(['schedule', 'frequency']),
      durationDays: duration == null
          ? null
          : int.tryParse(RegExp(r'\d+').stringMatch(duration) ?? ''),
      linked: t(['shopify_variant_id']) != null,
    );
  }

  /// "1 tablet · twice daily · 5 days", from whichever parts are known.
  String get summary => [
        if (dosage != null) dosage!,
        if (frequency != null) frequency!.replaceAll('_', ' '),
        if (durationDays != null) '$durationDays days',
      ].join(' · ');
}

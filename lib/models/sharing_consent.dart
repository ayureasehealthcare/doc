/// What a patient has agreed to share with a specific doctor.
///
/// Mirrors the patient app's per-doctor toggle (`DoctorSharingConsent`,
/// `share_full_record`), which today is stored only on the patient's
/// device. Only [full] grants access beyond the current consultation;
/// [unknown] must be treated exactly like [limited] - this app never
/// assumes full access it can't confirm.
enum SharingConsent {
  /// The patient turned on full-record sharing for this doctor.
  full,

  /// The patient explicitly limited sharing for this doctor.
  limited,

  /// No answer: not yet fetched, the endpoint isn't live, the field was
  /// absent, or the request failed.
  unknown;

  bool get isFull => this == SharingConsent.full;

  /// Reads `share_full_record` (the patient app's key) from either the top
  /// level or a `data` envelope. Anything other than a real boolean is
  /// [unknown]. The server shape is UNCONFIRMED - no consent endpoint
  /// exists in astra yet.
  static SharingConsent fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map ? json['data'] as Map : json;
    final value = body['share_full_record'];
    if (value == true) return SharingConsent.full;
    if (value == false) return SharingConsent.limited;
    return SharingConsent.unknown;
  }
}

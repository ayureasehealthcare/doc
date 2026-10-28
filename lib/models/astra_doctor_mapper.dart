/// Field mapping between the app's doctor profile/sign-up screens and
/// astra's doctor routes (`api/v1/api/doctors/...`, see [AstraApiService]).
///
/// Request shapes come from astra's live OpenAPI (Oct 2026):
/// - `RegisterDoctorRequest` (POST register): name (required), email, phone,
///   specialization, qualifications [str], experience_years int,
///   consultation_fee number, languages [str], location, available_days,
///   available_times, profile_image, bio.
/// - `UpdateDoctorRequest` (PUT {id}): name, phone, specialization,
///   consultation_fee, available_days, available_times, bio. Nothing else
///   can be saved after registration.
///
/// The GET {id} and register *response* bodies are NOT documented (the spec
/// says only "Successful Response" with an empty schema). [AstraDoctor] and
/// [AstraDoctorMapper.doctorIdFrom] therefore read them defensively: they
/// accept the record at the top level or under a `doctor` / `data` wrapper,
/// try several likely key names per field, and leave a field null rather
/// than guess when none match. Check these against a real response before
/// relying on any one key.
library;

/// A doctor record read from astra. Every field is optional because the
/// response shape is unconfirmed (see the library doc).
class AstraDoctor {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? specialization;
  final List<String> qualifications;
  final int? experienceYears;
  final num? consultationFee;
  final List<String> languages;
  final String? bio;
  final String? profileImage;
  final String? gender;
  final String? dob;
  final List<String> availableDays;

  /// Uploaded medical-certificate link, if the record carries one.
  final String? certificateUrl;

  /// Legacy "patients can video-call me" toggle. Not in any astra schema;
  /// read only in case the record happens to carry it.
  final int? patientVCall;

  const AstraDoctor({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.specialization,
    this.qualifications = const [],
    this.experienceYears,
    this.consultationFee,
    this.languages = const [],
    this.bio,
    this.profileImage,
    this.gender,
    this.dob,
    this.availableDays = const [],
    this.certificateUrl,
    this.patientVCall,
  });

  /// Parses a GET `doctors/{id}` body. Unconfirmed shape: see library doc.
  factory AstraDoctor.fromResponse(dynamic body) {
    final m = AstraDoctorMapper.unwrap(body);
    return AstraDoctor(
      id: AstraDoctorMapper._pickString(
          m, const ['doctor_id', 'id', '_id', 'uid', 'unique_id']),
      name: AstraDoctorMapper._pickString(
          m, const ['name', 'full_name', 'doctor_name']),
      email: AstraDoctorMapper._pickString(m, const ['email']),
      phone: AstraDoctorMapper._pickString(
          m, const ['phone', 'phone_number', 'mobile']),
      specialization: AstraDoctorMapper._pickString(
          m, const ['specialization', 'speciality', 'specialty']),
      qualifications: AstraDoctorMapper._pickList(
          m, const ['qualifications', 'qualification']),
      experienceYears: AstraDoctorMapper.parseYears(
          m['experience_years'] ?? m['experience']),
      consultationFee: AstraDoctorMapper.parseFee(
          m['consultation_fee'] ?? m['fee'] ?? m['fees']),
      languages:
          AstraDoctorMapper._pickList(m, const ['languages', 'language']),
      bio: AstraDoctorMapper._pickString(
          m, const ['bio', 'description', 'desc', 'about']),
      profileImage: AstraDoctorMapper._pickString(m, const [
        'profile_image',
        'photo_url',
        'image',
        'image_url',
        'avatar_url',
      ]),
      gender: AstraDoctorMapper._pickString(m, const ['gender']),
      dob: AstraDoctorMapper._pickString(m, const ['dob', 'date_of_birth']),
      availableDays: AstraDoctorMapper._pickList(m, const ['available_days']),
      certificateUrl: AstraDoctorMapper._pickString(
          m, const ['certificate_url', 'certificate']),
      patientVCall: m['patient_vcall'] is bool
          ? (m['patient_vcall'] as bool ? 1 : 0)
          : AstraDoctorMapper.parseYears(m['patient_vcall']),
    );
  }

  /// [consultationFee] as form text: "800", "799.5", or "" when unknown.
  String get feeText => AstraDoctorMapper.formatNumber(consultationFee);

  /// [experienceYears] as form text, or "" when unknown.
  String get experienceText => experienceYears?.toString() ?? '';
}

class AstraDoctorMapper {
  AstraDoctorMapper._();

  /// Keys astra may wrap the record in. Unconfirmed: see library doc.
  static const _wrappers = ['doctor', 'data'];

  /// Returns the doctor record from [body], unwrapping `{"doctor": {...}}`,
  /// `{"data": {...}}` and `{"data": {"doctor": {...}}}`. A body that is not
  /// a map gives an empty map.
  static Map<String, dynamic> unwrap(dynamic body) {
    if (body is! Map) return const {};
    Map current = body;
    for (var depth = 0; depth < 2; depth++) {
      Map? inner;
      for (final key in _wrappers) {
        if (current[key] is Map) {
          inner = current[key] as Map;
          break;
        }
      }
      if (inner == null) break;
      current = inner;
    }
    return Map<String, dynamic>.from(current);
  }

  /// The new doctor's id from a register (or GET) response, or null if no
  /// likely key is present. Checks the top level first, then the unwrapped
  /// record. Unconfirmed shape: see library doc.
  static String? doctorIdFrom(dynamic body) {
    if (body is Map) {
      final top = _pickString(body, const ['doctor_id']);
      if (top != null) return top;
    }
    return _pickString(
        unwrap(body), const ['doctor_id', 'id', '_id', 'uid', 'unique_id']);
  }

  /// A session token in a register response, or null. The spec documents
  /// none, so sign-up assumes there usually isn't one and sends the doctor
  /// to sign in; this only lets a token through if astra does return one.
  static String? sessionTokenFrom(dynamic body) {
    const keys = ['session_token', 'token', 'access_token'];
    if (body is Map) {
      final top = _pickString(body, keys);
      if (top != null) return top;
    }
    return _pickString(unwrap(body), keys);
  }

  /// Body for POST `doctors/register` (`RegisterDoctorRequest`). Free-text
  /// form values are converted here: [qualifications] and [languages] are
  /// comma-separated, [experience] and [fee] are parsed for their number.
  /// Empty or unparseable values are left out so the server's defaults
  /// apply.
  static Map<String, dynamic> registerBody({
    required String name,
    String? email,
    String? phone,
    String? specialization,
    String? qualifications,
    String? experience,
    String? fee,
    String? languages,
    String? bio,
    String? profileImage,
  }) {
    final body = <String, dynamic>{'name': name.trim()};
    void putText(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) body[key] = v;
    }

    putText('email', email);
    putText('phone', phone);
    putText('specialization', specialization);
    final quals = splitList(qualifications);
    if (quals.isNotEmpty) body['qualifications'] = quals;
    final years = parseYears(experience);
    if (years != null) body['experience_years'] = years;
    final parsedFee = parseFee(fee);
    if (parsedFee != null) body['consultation_fee'] = parsedFee;
    final langs = splitList(languages);
    if (langs.isNotEmpty) body['languages'] = langs;
    putText('bio', bio);
    putText('profile_image', profileImage);
    return body;
  }

  /// Body for PUT `doctors/{id}` (`UpdateDoctorRequest`) - only the fields
  /// that route accepts. [name], [phone] and [specialization] are left out
  /// when blank (a blank would wipe them); [bio] is sent as-is when given,
  /// so a doctor can clear it. [fee] is parsed for its number.
  static Map<String, dynamic> updateBody({
    String? name,
    String? phone,
    String? specialization,
    String? fee,
    String? bio,
  }) {
    final body = <String, dynamic>{};
    void putText(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) body[key] = v;
    }

    putText('name', name);
    putText('phone', phone);
    putText('specialization', specialization);
    final parsedFee = parseFee(fee);
    if (parsedFee != null) body['consultation_fee'] = parsedFee;
    if (bio != null) body['bio'] = bio.trim();
    return body;
  }

  /// Labels from [after] whose value differs from [before]. Screens use this
  /// to tell the doctor which edits astra can't store yet, rather than
  /// reporting them as saved.
  static List<String> changedFields(
      Map<String, String> before, Map<String, String> after) {
    return [
      for (final entry in after.entries)
        if ((before[entry.key] ?? '').trim() != entry.value.trim()) entry.key,
    ];
  }

  /// The message shown when [unsaved] (from [changedFields]) is not empty.
  static String unsavedMessage(List<String> unsaved) =>
      "Saved. These can't be stored yet, so your changes to them were not "
      'saved: ${unsaved.join(', ')}.';

  /// [phone] with [dialCode] in front ("+91", "9876543210" ->
  /// "+919876543210"), unless it already starts with "+" or there is no
  /// code. Null when [phone] is blank.
  static String? withDialCode(String? dialCode, String? phone) {
    final p = phone?.trim() ?? '';
    if (p.isEmpty) return null;
    final code = dialCode?.trim() ?? '';
    if (code.isEmpty || p.startsWith('+')) return p;
    return '$code$p';
  }

  /// "BAMS, MD Ayurveda" -> ["BAMS", "MD Ayurveda"].
  static List<String> splitList(String? text) => (text ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// First whole number in [value] ("10", "10 years", 10, 10.0), else null.
  static int? parseYears(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value == null) return null;
    final match = RegExp(r'\d+').firstMatch(value.toString());
    return match == null ? null : int.parse(match.group(0)!);
  }

  /// A fee as a number from 800, "800", "₹800.00" or "1,200", else null.
  static num? parseFee(dynamic value) {
    if (value is num) return value;
    if (value == null) return null;
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final parsed = num.tryParse(cleaned);
    if (parsed == null) return null;
    return parsed == parsed.roundToDouble() ? parsed.round() : parsed;
  }

  /// 800 -> "800", 800.0 -> "800", 799.5 -> "799.5", null -> "".
  static String formatNumber(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  static String? _pickString(Map m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v == null || v is Map || v is List) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static List<String> _pickList(Map m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v is List) {
        final list = v
            .where((e) => e != null)
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      } else if (v is String) {
        final list = splitList(v);
        if (list.isNotEmpty) return list;
      }
    }
    return const [];
  }
}

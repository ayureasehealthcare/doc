class EducationCertificate {
  String? _certificate;

  String? _certificateYear;

  get certificate => _certificate;

  set certificate(value) {
    _certificate = value;
  }

  get certificateYear => _certificateYear;

  set certificateYear(value) {
    _certificateYear = value;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['certificate'] = certificate;
    data['certificate_year'] = _certificateYear;
    return data;
  }
}

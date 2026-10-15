class Setting {
  bool? success;
  Data? data;
  String? msg;

  Setting({this.success, this.data, this.msg});

  Setting.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['msg'] = msg;
    return data;
  }
}

class Data {
  int? id;
  String? businessName;
  String? email;
  String? phone;
  String? companyWhiteLogo;
  String? companyLogo;
  String? companyFavicon;
  String? currencySymbol;
  String? currencyCode;
  String? color;
  String? websiteColor;
  int? cod;
  int? stripe;
  int? paypal;
  int? razor;
  int? flutterwave;
  int? paystack;
  String? timezone;
  int? defaultCommission;
  int? pharamacyCommission;
  String? defaultBaseOn;
  String? mapKey;
  int? verification;
  int? usingMail;
  int? usingMsg;
  String? cancelReason;
  int? radius;
  String? clinicContent;
  String? doctorContent;
  String? footerContent;
  String? doctorMail;
  String? patientMail;
  String? patientNotification;
  String? doctorNotification;
  String? patientAppId;
  String? patientAuthKey;
  String? patientApiKey;
  String? doctorAppId;
  String? licenseCode;
  String? clientName;
  int? licenseVerify;
  String? createdAt;
  String? agoraAppId;
  String? updatedAt;
  String? companyWhite;
  String? logo;
  String? favicon;

  Data(
      {this.id,
      this.businessName,
      this.email,
      this.phone,
      this.companyWhiteLogo,
      this.companyLogo,
      this.companyFavicon,
      this.currencySymbol,
      this.currencyCode,
      this.color,
      this.websiteColor,
      this.cod,
      this.stripe,
      this.paypal,
      this.razor,
      this.flutterwave,
      this.paystack,
      this.timezone,
      this.defaultCommission,
      this.pharamacyCommission,
      this.defaultBaseOn,
      this.mapKey,
      this.verification,
      this.usingMail,
      this.usingMsg,
      this.cancelReason,
      this.radius,
      this.clinicContent,
      this.doctorContent,
      this.footerContent,
      this.doctorMail,
      this.patientMail,
      this.patientNotification,
      this.doctorNotification,
      this.patientAppId,
      this.patientAuthKey,
      this.patientApiKey,
      this.doctorAppId,
      this.licenseCode,
      this.clientName,
      this.licenseVerify,
      this.createdAt,
      this.updatedAt,
      this.agoraAppId,
      this.companyWhite,
      this.logo,
      this.favicon});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    businessName = json['business_name'];
    email = json['email'];
    phone = json['phone'];
    companyWhiteLogo = json['company_white_logo'];
    companyLogo = json['company_logo'];
    companyFavicon = json['company_favicon'];
    currencySymbol = json['currency_symbol'];
    currencyCode = json['currency_code'];
    color = json['color'];
    websiteColor = json['website_color'];
    cod = json['cod'];
    stripe = json['stripe'];
    paypal = json['paypal'];
    razor = json['razor'];
    flutterwave = json['flutterwave'];
    paystack = json['paystack'];
    timezone = json['timezone'];
    defaultCommission = json['default_commission'];
    pharamacyCommission = json['pharamacy_commission'];
    defaultBaseOn = json['default_base_on'];
    mapKey = json['map_key'];
    verification = json['verification'];
    usingMail = json['using_mail'];
    usingMsg = json['using_msg'];
    cancelReason = json['cancel_reason'];
    radius = json['radius'];
    clinicContent = json['clinic_content'];
    doctorContent = json['doctor_content'];
    footerContent = json['footer_content'];
    doctorMail = json['doctor_mail'];
    patientMail = json['patient_mail'];
    patientNotification = json['patient_notification'];
    doctorNotification = json['doctor_notification'];
    patientAppId = json['patient_app_id'];
    patientAuthKey = json['patient_auth_key'];
    patientApiKey = json['patient_api_key'];
    doctorAppId = json['doctor_app_id'];
    licenseCode = json['license_code'];
    clientName = json['client_name'];
    licenseVerify = json['license_verify'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    agoraAppId = json['agora_app_id'];
    companyWhite = json['companyWhite'];
    logo = json['logo'];
    favicon = json['favicon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business_name'] = businessName;
    data['email'] = email;
    data['phone'] = phone;
    data['company_white_logo'] = companyWhiteLogo;
    data['company_logo'] = companyLogo;
    data['company_favicon'] = companyFavicon;
    data['currency_symbol'] = currencySymbol;
    data['currency_symbol'] = currencyCode;
    data['color'] = color;
    data['website_color'] = websiteColor;
    data['cod'] = cod;
    data['stripe'] = stripe;
    data['paypal'] = paypal;
    data['razor'] = razor;
    data['flutterwave'] = flutterwave;
    data['paystack'] = paystack;
    data['timezone'] = timezone;
    data['default_commission'] = defaultCommission;
    data['pharamacy_commission'] = pharamacyCommission;
    data['default_base_on'] = defaultBaseOn;
    data['map_key'] = mapKey;
    data['verification'] = verification;
    data['using_mail'] = usingMail;
    data['using_msg'] = usingMsg;
    data['cancel_reason'] = cancelReason;
    data['radius'] = radius;
    data['clinic_content'] = clinicContent;
    data['doctor_content'] = doctorContent;
    data['footer_content'] = footerContent;
    data['doctor_mail'] = doctorMail;
    data['patient_mail'] = patientMail;
    data['patient_notification'] = patientNotification;
    data['doctor_notification'] = doctorNotification;
    data['patient_app_id'] = patientAppId;
    data['patient_auth_key'] = patientAuthKey;
    data['patient_api_key'] = patientApiKey;
    data['doctor_app_id'] = doctorAppId;
    data['license_code'] = licenseCode;
    data['client_name'] = clientName;
    data['license_verify'] = licenseVerify;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['agora_app_id'] = agoraAppId;
    data['companyWhite'] = companyWhite;
    data['logo'] = logo;
    data['favicon'] = favicon;
    return data;
  }
}

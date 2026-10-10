class AppointmentDetails {
  bool? success;
  Data? data;
  String? msg;

  AppointmentDetails({this.success, this.data, this.msg});

  AppointmentDetails.fromJson(Map<String, dynamic> json) {
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
  String? appointmentId;
  int? userId;
  int? doctorId;
  String? amount;
  String? paymentType;
  String? appointmentFor;
  String? appointmentType;
  String? patientName;
  int? age;
  List<String>? reportImage;
  String? drugEffect;
  String? patientAddress;
  String? phoneNo;
  String? date;
  String? time;
  int? paymentStatus;
  String? appointmentStatus;
  String? illnessInformation;
  String? note;
  String? pdf;
  int? rate;
  int? review;
  User? user;
  int? isInsured;
  String? policyInsurerName;
  String? policyNumber;
  // Stitched onto the appointment by the patient app at booking time (see
  // astra_consultation_link.dart in the patient repo) - not returned by
  // the backend until the Laravel link_appointment_astra_case route is
  // live, so this is null for any appointment booked before that.
  String? astraCaseId;

  Data({
    this.id,
    this.appointmentId,
    this.userId,
    this.doctorId,
    this.amount,
    this.paymentType,
    this.appointmentFor,
    this.appointmentType,
    this.patientName,
    this.age,
    this.reportImage,
    this.drugEffect,
    this.patientAddress,
    this.phoneNo,
    this.date,
    this.time,
    this.paymentStatus,
    this.appointmentStatus,
    this.illnessInformation,
    this.note,
    this.pdf,
    this.rate,
    this.review,
    this.user,
    this.isInsured,
    this.policyInsurerName,
    this.policyNumber,
    this.astraCaseId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    appointmentId = json['appointment_id'];
    userId = json['user_id'];
    doctorId = json['doctor_id'];
    amount = json['amount'];
    paymentType = json['payment_type'];
    appointmentFor = json['appointment_for'];
    appointmentType = json['appointment_type'];
    patientName = json['patient_name'];
    age = json['age'];
    reportImage = json['report_image'].cast<String>();
    drugEffect = json['drug_effect'];
    patientAddress = json['patient_address'];
    phoneNo = json['phone_no'];
    date = json['date'];
    time = json['time'];
    paymentStatus = json['payment_status'];
    appointmentStatus = json['appointment_status'];
    illnessInformation = json['illness_information'];
    note = json['note'];
    pdf = json['pdf'];
    rate = json['rate'];
    review = json['review'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    isInsured = json['is_insured'];
    policyInsurerName = json['policy_insurer_name'];
    policyNumber = json['policy_number'];
    astraCaseId = json['astra_case_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['appointment_id'] = appointmentId;
    data['user_id'] = userId;
    data['doctor_id'] = doctorId;
    data['amount'] = amount;
    data['payment_type'] = paymentType;
    data['appointment_for'] = appointmentFor;
    data['appointment_type'] = appointmentType;
    data['patient_name'] = patientName;
    data['age'] = age;
    data['report_image'] = reportImage;
    data['drug_effect'] = drugEffect;
    data['patient_address'] = patientAddress;
    data['phone_no'] = phoneNo;
    data['date'] = date;
    data['time'] = time;
    data['payment_status'] = paymentStatus;
    data['appointment_status'] = appointmentStatus;
    data['illness_information'] = illnessInformation;
    data['note'] = note;
    data['pdf'] = pdf;
    data['rate'] = rate;
    data['review'] = review;
    data['is_insured'] = isInsured;
    data['policy_insurer_name'] = policyInsurerName;
    data['policy_number'] = policyNumber;
    data['astra_case_id'] = astraCaseId;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? image;
  String? fullImage;

  User({this.id, this.image, this.fullImage});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['image'] = image;
    data['fullImage'] = fullImage;
    return data;
  }
}

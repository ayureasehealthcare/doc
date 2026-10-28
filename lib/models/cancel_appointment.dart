class CancelAppointment {
  bool? success;
  List<AppointmentCancel>? data;

  CancelAppointment({this.success, this.data});

  CancelAppointment.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(AppointmentCancel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AppointmentCancel {
  int? id;
  String? date;
  String? time;
  int? userId;
  String? patientAddress;
  String? patientName;
  int? age;
  int? amount;
  User? user;

  AppointmentCancel(
      {this.id,
      this.date,
      this.time,
      this.userId,
      this.patientAddress,
      this.patientName,
      this.age,
      this.amount,
      this.user});

  AppointmentCancel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    date = json['date'];
    time = json['time'];
    userId = json['user_id'];
    patientAddress = json['patient_address'];
    patientName = json['patient_name'];
    age = json['age'];
    amount = json['amount'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['date'] = date;
    data['time'] = time;
    data['user_id'] = userId;
    data['patient_address'] = patientAddress;
    data['patient_name'] = patientName;
    data['age'] = age;
    data['amount'] = amount;
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

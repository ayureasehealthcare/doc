class Treatment {
  bool? success;
  List<TreatmentData>? data;
  String? msg;

  Treatment({this.success, this.data, this.msg});

  Treatment.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(TreatmentData.fromJson(v));
      });
    }
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['msg'] = msg;
    return data;
  }
}

class TreatmentData {
  int? id;
  String? name;
  String? fullImage;

  TreatmentData({this.id, this.name, this.fullImage});

  TreatmentData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['fullImage'] = fullImage;
    return data;
  }
}

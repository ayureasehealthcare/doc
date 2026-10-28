class UpdateProfile {
  bool? success;
  String? msg;

  UpdateProfile({this.success, this.msg});

  UpdateProfile.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['msg'] = msg;
    return data;
  }
}

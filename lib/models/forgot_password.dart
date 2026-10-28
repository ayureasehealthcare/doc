class ForgotPassword {
  bool? success;
  String? msg;

  ForgotPassword({this.success, this.msg});

  ForgotPassword.fromJson(Map<String, dynamic> json) {
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

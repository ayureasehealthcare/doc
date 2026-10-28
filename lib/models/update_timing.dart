class UpdateTiming {
  bool? success;
  String? msg;

  UpdateTiming({this.success, this.msg});

  UpdateTiming.fromJson(Map<String, dynamic> json) {
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

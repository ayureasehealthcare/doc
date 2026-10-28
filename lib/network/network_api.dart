import 'package:dio/dio.dart';
import 'package:doctro/models/CancelAppointment.dart';
import 'package:doctro/models/DoctorStatusChange.dart';
import 'package:doctro/models/Notification.dart';
import 'package:doctro/models/ResentOtp.dart';
import 'package:doctro/models/Treatment.dart';
import 'package:doctro/models/UpdateProfile.dart';
import 'package:doctro/models/UpdateTiming.dart';
import 'package:doctro/models/appointment_details.dart';
import 'package:doctro/models/appointment_history.dart';
import 'package:doctro/models/categories.dart';
import 'package:doctro/models/expertise.dart';
import 'package:doctro/models/hospital.dart';
import 'package:doctro/models/otp_verify.dart';
import 'package:doctro/models/payment.dart';
import 'package:doctro/models/review.dart';
import 'package:doctro/models/setting.dart';
import 'package:doctro/models/today_appointment.dart';
import 'package:doctro/models/update_profile_image.dart';
import 'package:doctro/models/video_call_history_add_model.dart';
import 'package:doctro/models/video_call_history_show_model.dart';
import 'package:doctro/models/working_hours.dart';
import 'package:doctro/network/apis.dart';
import 'package:retrofit/retrofit.dart';

part 'network_api.g.dart';

@RestApi(baseUrl: Apis.baseUrl)
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @GET(Apis.appointment)
  Future<TodayAppointment> todayAppointments();

  @GET(Apis.appointment_details)
  Future<AppointmentDetails> appointmentDetails(@Path() int? id);

  @GET(Apis.appointment_history)
  Future<AppointmentHistory> appointmentHistoryScreenRequest();

  @GET(Apis.working_hours)
  Future<Workinghours> workinghours();

  @GET(Apis.hospitals)
  Future<Hospitals> hospitalRequest();

  @GET(Apis.review)
  Future<Review> reviewRequest();

  @GET(Apis.payment)
  Future<Payment> paymentRequest();

  @POST(Apis.check_otp)
  Future<OtpVerify> otpVerifyRequest(@Body() body);

  @GET(Apis.treatment)
  Future<Treatment> treatmentRequest();

  @GET(Apis.categories)
  Future<Categories> categoryRequest(@Path() int? id);

  @GET(Apis.expertise)
  Future<Expertise> expertiseRequest(@Path() int? id);

  @GET(Apis.setting)
  Future<Setting> settingRequest();

  @POST(Apis.update_image)
  Future<ImageUpload> uploadImage(@Body() body);

  @POST(Apis.status_change)
  Future<DoctorStatusChange> doctorStatusChangeRequest(@Body() body);

  @GET(Apis.cancel_appointment)
  Future<CancelAppointment> cancelAppointmentRequest();

  @POST(Apis.update_time)
  Future<UpdateTiming> updateTimingRequest(@Body() body);

  @GET(Apis.notification)
  Future<Notifications> notifications();

  @GET(Apis.resend_otp)
  Future<ResentOtp> resentOtpRequest(@Path() int? id);

  @POST(Apis.videoCallAddHistory)
  Future<VideoCallHistoryAddModel> videoCallHistoryAddRequest(@Body() body);

  @GET(Apis.videoCallShowHistory)
  Future<VideoCallHistoryShowModel> videoCallHistoryShowRequest();

  @POST(Apis.updatePatientVcall)
  Future<UpdateProfile> updatePatientVcallRequest(@Body() body);
}

class Apis {
  /// BASE URL
  /// After you have entered/edited your base url, run the command:
  /// dart run build_runner build --delete-conflicting-outputs
  /// to generate the api_services.g.dart file
  /// Every time you change the base url, you need to run the above command
  static const String baseUrl = 'https://astra.ayureze.in/api/v1/';
  static const String astraBaseUrl = 'https://astra.ayureze.in/';

  static const String appointment = "doctor_appointment";
  static const String appointment_details = "appointment_details/{id}";
  static const String appointment_history = "appointment_history";
  static const String working_hours = "working_hours";
  static const String hospitals = "hospitals";
  static const String review = "doctor_review";
  static const String payment = "payment";
  static const String check_otp = "check_otp";
  static const String treatment = "treatment";
  static const String categories = "categories/{id}";
  static const String expertise = "expertise/{id}";
  static const String setting = "setting";
  static const String update_image = "doctor_update_image";
  static const String status_change = "status_change";
  static const String cancel_appointment = "cancel_appointment";
  static const String update_time = "update_time";
  static const String notification = "notification";
  static const String resend_otp = "resendOtp/{id}";
  static const String videoCallAddHistory = "add_call_history";
  // Worked on 2026-10-13; 404s on astra as of 2026-10-28, with no
  // replacement in its OpenAPI. Reported to the backend.
  static const String videoCallShowHistory = "video/history";
  static const String updatePatientVcall = "updatePatientVcall";

  // Authentication
  static const String astra_session = "api/v1/auth/session";
  static const String astra_user_info = "api/v1/auth/user";
  static const String astra_logout = "api/v1/auth/logout";

  // Patient Management
  static const String astra_search_patients =
      "api/v1/patients/search/{search_term}";
  static const String astra_verify_patient =
      "api/v1/patients/verify/{patient_code}";
  static const String astra_patient_profile =
      "api/v1/patients/profile/{patient_id}";

  // Prescriptions
  static const String astra_create_prescription =
      "api/v1/api/prescriptions/create";
  static const String astra_get_prescription =
      "api/v1/api/prescriptions/{prescription_id}";
  static const String astra_update_prescription =
      "api/v1/api/prescriptions/{prescription_id}";
  static const String astra_patient_prescriptions =
      "api/v1/api/prescriptions/patient/{patient_id}";

  // Smart Auto-Cart (Shopify)
  static const String astra_shopify_sync = "api/v1/shopify/sync";

  // Astra Brain AI
  static const String astra_brain_chat = "api/v1/brain/chat";

  // Companion Case (journey/progress tied to a consultation - note this
  // is under /api/companion, not /api/v1 like the routes above)
  static const String astra_companion_case = "api/companion/case/{case_id}";

  // NOT LIVE YET - TODO(astra-backend). Path taken from the feature brief
  // ("something like GET /api/companion/wellness/{patient_id}"); it is not
  // in the astra repo or confirmed against the live OpenAPI spec. Gated off
  // by AstraApiService.wellnessEndpointLive until it is.
  static const String astra_companion_wellness =
      "api/companion/wellness/{patient_id}";
}

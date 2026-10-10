class Apis {
  /// BASE URL
  /// After you have entered/edited your base url, run the command:
  /// dart run build_runner build --delete-conflicting-outputs
  /// to generate the api_services.g.dart file
  /// Every time you change the base url, you need to run the above command
  static const String baseUrl = 'https://astra.ayureze.in/api/v1/';
  static const String astraBaseUrl = 'https://astra.ayureze.in/';

  static const String login = "doctor_login";
  static const String register = "doctor_register";
  static const String appointment = "doctor_appointment";
  static const String appointment_details = "appointment_details/{id}";
  static const String appointment_history = "appointment_history";
  static const String working_hours = "working_hours";
  static const String hospitals = "hospitals";
  static const String doctor_profile = "doctor_profile";
  static const String review = "doctor_review";
  static const String payment = "payment";
  static const String check_otp = "check_otp";
  static const String update_doctor = "update_doctor";
  static const String treatment = "treatment";
  static const String categories = "categories/{id}";
  static const String expertise = "expertise/{id}";
  static const String addPrescription = "add_prescription";
  static const String setting = "setting";
  static const String update_image = "doctor_update_image";
  static const String status_change = "status_change";
  static const String cancel_appointment = "cancel_appointment";
  static const String finance_detail = "finance_details";
  static const String update_time = "update_time";
  static const String change_password = "doctor_change_password";
  static const String forgot_password = "forgot_password";
  static const String notification = "notification";
  static const String all_medicines = "allMedicines";
  static const String resend_otp = "resendOtp/{id}";
  static const String videoCallAddHistory = "add_call_history";
  static const String videoCallShowHistory = "video_call_history";
  static const String generateDoctorAgoraToken = "generateDoctorAgoraToken";
  static const String updatePatientVcall = "updatePatientVcall";

  // ============================================================
  // ASTRA AI HEALTHCARE ENDPOINTS
  // Base URL: https://astra.ayureze.in
  // ============================================================

  // Authentication
  static const String astra_login = "api/v1/auth/login";
  static const String astra_session = "api/v1/auth/session";
  static const String astra_user_info = "api/v1/auth/user";
  static const String astra_logout = "api/v1/auth/logout";

  // Doctor Management
  static const String astra_register_doctor = "api/v1/api/doctors/register";
  static const String astra_doctor_profile = "api/v1/api/doctors/{id}";
  static const String astra_update_doctor = "api/v1/api/doctors/{id}";
  static const String astra_nearby_doctors = "api/v1/api/doctors/nearby/search";
  static const String astra_doctor_stats =
      "api/v1/api/doctors/{id}/dashboard-stats";
  static const String astra_doctor_withdraw =
      "api/v1/api/doctors/{id}/withdraw";

  // Patient Management
  static const String astra_register_patient = "api/v1/patients/register";
  static const String astra_search_patients =
      "api/v1/patients/search/{search_term}";
  static const String astra_verify_patient =
      "api/v1/patients/verify/{patient_code}";
  static const String astra_patient_profile =
      "api/v1/patients/profile/{patient_id}";
  static const String astra_create_consultation =
      "api/v1/patients/consultation";

  // Prescriptions
  static const String astra_create_prescription =
      "api/v1/api/prescriptions/create";
  static const String astra_get_prescription =
      "api/v1/api/prescriptions/{prescription_id}";
  static const String astra_update_prescription =
      "api/v1/api/prescriptions/{prescription_id}";
  static const String astra_patient_prescriptions =
      "api/v1/api/prescriptions/patient/{patient_id}";
  static const String astra_process_prescription =
      "api/v1/api/prescriptions/{prescription_id}/process";
  static const String astra_prescription_summary =
      "api/v1/api/prescriptions/{prescription_id}/summary";
  static const String astra_pending_prescriptions =
      "api/v1/api/prescriptions/queue/pending";

  // Catchy Prescriptions
  static const String astra_catchy_from_upload =
      "api/v1/prescriptions/catchy-from-upload";
  static const String astra_catchy_from_data =
      "api/v1/prescriptions/catchy-from-data";
  static const String astra_auto_generate_catchy =
      "api/v1/prescriptions/auto-generate-catchy";

  // Unified Prescription Workflow (Magic Button)
  static const String astra_execute_workflow =
      "api/v1/prescription-workflow/execute";
  static const String astra_workflow_status =
      "api/v1/prescription-workflow/status/{prescription_id}";

  // Smart Auto-Cart (Shopify)
  static const String astra_ai_shop_assist = "api/v1/shopify/ai-shop-assist";
  static const String astra_create_draft_order = "api/v1/shopify/draft-order";
  static const String astra_product_search =
      "api/v1/shopify/products/search/{medicine_name}";
  static const String astra_available_medicines =
      "api/v1/shopify/products/available";
  static const String astra_shopify_sync = "api/v1/shopify/sync";
  static const String astra_draft_order_status =
      "api/v1/shopify/draft-order/{draft_order_id}";
  static const String astra_validate_prescription =
      "api/v1/shopify/validate-prescription";
  static const String astra_order_details =
      "api/v1/shopify/order-details/{draft_order_id}";

  // Astra Brain AI
  static const String astra_brain_chat = "api/v1/brain/chat";
  static const String astra_brain_doctor_summary =
      "api/v1/brain/doctor-summary";
  static const String astra_brain_analyze_safety =
      "api/v1/brain/analyze-safety";
  static const String astra_brain_extract_schedule =
      "api/v1/brain/extract-schedule";
  static const String astra_brain_profile_analysis =
      "api/v1/brain/profile-analysis";
  static const String astra_brain_generate_wellness =
      "api/v1/brain/generate-wellness";
  static const String astra_brain_health = "api/v1/brain/health";

  // Astra Fill (Voice & Text Processing)
  static const String astra_fill_process_voice =
      "api/v1/astra-fill/process-voice";
  static const String astra_fill_process_text =
      "api/v1/astra-fill/process-text";
  static const String astra_fill_confirm = "api/v1/astra-fill/confirm";

  // Documents
  static const String astra_upload_document = "api/v1/documents/upload";
  static const String astra_patient_documents =
      "api/v1/documents/patient/{patient_id}";
  static const String astra_download_document =
      "api/v1/documents/download/{document_id}";
  static const String astra_share_link =
      "api/v1/documents/share-link/{document_id}";
  static const String astra_share_whatsapp =
      "api/v1/documents/share-whatsapp/{document_id}";
  static const String astra_delete_document = "api/v1/documents/{document_id}";

  // Orders
  static const String astra_save_prescription_record =
      "api/v1/orders/prescription/save";
  static const String astra_update_order_status =
      "api/v1/orders/prescription/status";
  static const String astra_patient_orders =
      "api/v1/orders/patient/{patient_id}";
  static const String astra_order_prescription =
      "api/v1/orders/prescription/{prescription_id}";
  static const String astra_orders_by_status = "api/v1/orders/status/{status}";

  // Notifications
  static const String astra_store_fcm_token =
      "api/v1/notifications/store-fcm-token";
  static const String astra_remove_fcm_token =
      "api/v1/notifications/remove-fcm-token/{patient_id}";
  static const String astra_notification_status =
      "api/v1/notifications/service-status";

  // Medicine Reminders
  static const String astra_create_reminders =
      "api/v1/medicine-reminders/create-from-prescription";

  // Translation
  static const String astra_translate = "api/v1/api/translate/";
  static const String astra_supported_languages =
      "api/v1/api/translate/languages";
  static const String astra_auto_translate =
      "api/v1/api/translate/auto-translate";

  // AI Agent
  static const String astra_ai_agent_ask = "api/v1/api/ai-agent/ask";
  static const String astra_ai_agent_status = "api/v1/api/ai-agent/status";

  // Treatment Centers
  static const String astra_nearby_centers =
      "api/v1/api/treatment-centers/nearby/search";

  // Health Checks
  static const String astra_health = "health";
  static const String astra_health_ready = "health/ready";

  // Companion Case (journey/progress tied to a consultation - note this
  // is under /api/companion, not /api/v1 like the routes above)
  static const String astra_companion_case = "api/companion/case/{case_id}";
}

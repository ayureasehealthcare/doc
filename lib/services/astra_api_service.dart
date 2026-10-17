import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import 'package:doctro/models/patient_wellness.dart';
import 'package:doctro/models/sharing_consent.dart';
import 'package:doctro/network/apis.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';

/// Astra AI Healthcare API Service
///
/// This service connects the Doctor App to the Astra AI Backend
/// Includes essential endpoints for:
/// - Authentication
/// - Patient Management
/// - Prescriptions & Auto-Cart
/// - AI Chat & Brain
/// - Documents
/// - Notifications
class AstraApiService {
  static final AstraApiService _instance = AstraApiService._internal();
  late Dio _dio;

  /// Your Astra AI Backend Base URL
  final String baseUrl = Apis.astraBaseUrl;

  factory AstraApiService() {
    return _instance;
  }

  AstraApiService._internal() {
    // Ensure baseUrl always ends with a slash to prevent construction errors
    String sanitizedBaseUrl = baseUrl;
    if (!sanitizedBaseUrl.endsWith('/')) {
      sanitizedBaseUrl += '/';
    }

    _dio = Dio(BaseOptions(
      baseUrl: sanitizedBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 90),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Prefer the Astra-issued session token (from /auth/login) once we
        // have one: most Astra endpoints (e.g. /auth/user) validate that
        // token specifically and reject a raw Firebase ID token, even
        // though a Firebase user stays signed in for the whole session.
        final String appToken =
            SharedPreferenceHelper.getString(Preferences.auth_token);
        if (appToken.isNotEmpty && appToken != 'N_A') {
          options.headers['Authorization'] = 'Bearer $appToken';
        } else {
          // No Astra session token yet (e.g. the /auth/login exchange call
          // itself) - fall back to the Firebase ID token. Guarded: accessing
          // FirebaseAuth.instance throws synchronously if Firebase hasn't
          // been initialized (e.g. StartupGate's own widget tests, which
          // boot the dashboard shell directly without Firebase.initializeApp()
          // to avoid platform channels) - an uncaught throw here inside this
          // async onRequest callback never properly rejects the request, so
          // the call just hangs instead of failing, which previously showed
          // up as a `pumpAndSettle` timeout rather than a clean error.
          try {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              String? token = await user.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (_) {
            // No Firebase session available - proceed unauthenticated and
            // let the server reject with 401 rather than hanging here.
          }
        }
        // Set default content type for JSON requests
        if (options.headers['Content-Type'] == null) {
          options.headers['Content-Type'] = 'application/json';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        return handler.next(error);
      },
    ));
  }

  // ============================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================

  /// Login with Firebase token
  Future<Map<String, dynamic>> login() async {
    try {
      final response = await _dio.get(Apis.astra_login);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a session for the authenticated user
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Apis.astra_session, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user info
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get(Apis.astra_user_info);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _dio.post(Apis.astra_logout);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // DOCTOR MANAGEMENT ENDPOINTS
  // ============================================================

  /// Register a new doctor
  Future<Map<String, dynamic>> registerDoctor(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/api/doctors/register', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a dynamic Agora RTC video token for a consultation with [toId]
  /// (the other party's user id). Hits the live `/video/generate-token`
  /// route - confirmed against the deployed backend; the previous
  /// `/video/token` (GET, channel/uid/role query params) 404s, it was
  /// never mounted in the backend's main.py.
  Future<Map<String, dynamic>> generateVideoToken({
    required String toId,
    int uid = 0,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/video/generate-token',
        data: {'to_id': toId, 'uid': uid},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the Agora App ID needed to initialize the RTC engine, before a
  /// token can be requested. NOT secret - the App Certificate (used to
  /// sign tokens) is what must stay server-side. Requires the backend to
  /// expose `GET /api/v1/video/config`; see the app's video-calling notes.
  Future<Map<String, dynamic>> getVideoConfig() async {
    try {
      final response = await _dio.get('/api/v1/video/config');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get doctor profile by ID
  Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    try {
      final response = await _dio.get('/api/v1/api/doctors/$doctorId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update doctor profile
  Future<Map<String, dynamic>> updateDoctorProfile(
      String doctorId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('/api/v1/api/doctors/$doctorId', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Search nearby doctors
  Future<List<dynamic>> searchNearbyDoctors({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? specialization,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/api/doctors/nearby/search',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          if (radiusKm != null) 'radius_km': radiusKm,
          if (specialization != null) 'specialization': specialization,
        },
      );
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get doctor dashboard stats
  Future<Map<String, dynamic>> getDashboardStats(String doctorId) async {
    try {
      final response =
          await _dio.get('/api/v1/api/doctors/$doctorId/dashboard-stats');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Doctor's own appointments. Confirmed live 2026-10-13 against the real
  /// backend: `/api/v1/appointments/my` previously 403'd for a doctor
  /// token ("Insufficient role") because it only accepted patient/admin
  /// roles and filtered by patient_id; both were fixed server-side to
  /// accept a doctor token and filter by doctor_id instead. Returns
  /// `{"appointments": [...]}`, each item a raw `consultations` row
  /// (consultation_id, patient_id, doctor_id, doctor_name,
  /// appointment_date, consultation_type, status, payment_status,
  /// created_at) - no patient name, no today/tomorrow/upcoming split;
  /// callers bucket by appointment_date themselves.
  Future<Map<String, dynamic>> getMyAppointments() async {
    try {
      final response = await _dio.get('/api/v1/appointments/my');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Request withdrawal. `amount` is a query parameter on this endpoint,
  /// not a body field - confirmed against the live backend, which returns
  /// a 422 "amount: Field required" validation error if it's sent in the
  /// JSON body instead.
  Future<Map<String, dynamic>> requestWithdraw(
      String doctorId, num amount, Map<String, dynamic> payoutDetails) async {
    try {
      final response = await _dio.post(
        '/api/v1/api/doctors/$doctorId/withdraw',
        queryParameters: {'amount': amount},
        data: {'payout_details': payoutDetails},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // PATIENT MANAGEMENT ENDPOINTS
  // ============================================================

  /// Register a new patient
  Future<Map<String, dynamic>> registerPatient(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/v1/patients/register', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Search patients by name, phone, or ID
  Future<List<dynamic>> searchPatients(String searchTerm) async {
    try {
      final String path =
          Apis.astra_search_patients.replaceFirst('{search_term}', searchTerm);
      final response = await _dio.get(path);
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Verify patient by code
  Future<Map<String, dynamic>> verifyPatientCode(String patientCode) async {
    try {
      final String path =
          Apis.astra_verify_patient.replaceFirst('{patient_code}', patientCode);
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get patient profile
  Future<Map<String, dynamic>> getPatientProfile(String patientId) async {
    try {
      final String path =
          Apis.astra_patient_profile.replaceFirst('{patient_id}', patientId);
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      return {};
    }
  }

  /// Create consultation record
  Future<Map<String, dynamic>> createConsultation(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(Apis.astra_create_consultation, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // PRESCRIPTION ENDPOINTS
  // ============================================================

  /// Create a new prescription
  Future<Map<String, dynamic>> createPrescription(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(Apis.astra_create_prescription, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get prescription by ID
  Future<Map<String, dynamic>> getPrescription(String prescriptionId) async {
    try {
      final String path = Apis.astra_get_prescription
          .replaceFirst('{prescription_id}', prescriptionId);
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update prescription
  Future<Map<String, dynamic>> updatePrescription(
      String prescriptionId, Map<String, dynamic> data) async {
    try {
      final String path = Apis.astra_update_prescription
          .replaceFirst('{prescription_id}', prescriptionId);
      final response = await _dio.put(path, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all prescriptions for a patient
  Future<List<dynamic>> getPatientPrescriptions(String patientId) async {
    try {
      final String path = Apis.astra_patient_prescriptions
          .replaceFirst('{patient_id}', patientId);
      final response = await _dio.get(path);
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Process prescription (triggers automation)
  Future<Map<String, dynamic>> processPrescription(
      String prescriptionId) async {
    try {
      final response =
          await _dio.post('/api/v1/api/prescriptions/$prescriptionId/process');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get prescription summary
  Future<Map<String, dynamic>> getPrescriptionSummary(
      String prescriptionId) async {
    try {
      final response =
          await _dio.get('/api/v1/api/prescriptions/$prescriptionId/summary');
      return response.data;
    } catch (e) {
      return {};
    }
  }

  /// Get pending prescription queue
  Future<List<dynamic>> getPendingPrescriptionQueue() async {
    try {
      final response =
          await _dio.get('/api/v1/api/prescriptions/queue/pending');
      return response.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // CATCHY PRESCRIPTIONS (AI-Generated Prescriptions)
  // ============================================================

  /// Generate catchy prescription from uploaded image
  Future<Map<String, dynamic>> generateCatchyFromUpload(File imageFile) async {
    try {
      String fileName = p.basename(imageFile.path);
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '/api/v1/prescriptions/catchy-from-upload',
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate catchy prescription from data
  Future<Map<String, dynamic>> generateCatchyFromData(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/prescriptions/catchy-from-data', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Auto-generate catchy prescription
  Future<Map<String, dynamic>> autoGenerateCatchyPrescription(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio
          .post('/api/v1/prescriptions/auto-generate-catchy', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // UNIFIED PRESCRIPTION WORKFLOW
  // ============================================================

  /// Execute unified prescription workflow (Save, PDF, WhatsApp, Cart, Reminders)
  Future<Map<String, dynamic>> executePrescriptionWorkflow(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Apis.astra_execute_workflow, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Check workflow status
  Future<Map<String, dynamic>> checkWorkflowStatus(
      String prescriptionId) async {
    try {
      final String path = Apis.astra_workflow_status
          .replaceFirst('{prescription_id}', prescriptionId);
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // SMART AUTO-CART (Shopify Integration)
  // ============================================================

  /// Sync Shopify products (Force sync from Shopify to Astra DB)
  Future<Map<String, dynamic>> syncShopifyProducts() async {
    try {
      final response = await _dio.post(Apis.astra_shopify_sync);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Check Shopify sync status
  Future<Map<String, dynamic>> getShopifyStatus() async {
    try {
      final response = await _dio.get('/api/v1/shopify/status');
      return response.data;
    } catch (e) {
      return {'error': e.toString(), 'connected': false};
    }
  }

  /// Test Shopify connection
  Future<Map<String, dynamic>> testShopifyConnection() async {
    try {
      final response = await _dio.get('/api/v1/shopify/test-connection');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// AI Shop Assist - Smart medicine recommendations
  Future<Map<String, dynamic>> aiShopAssist(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/shopify/ai-shop-assist', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create prescription draft order
  Future<Map<String, dynamic>> createDraftOrder(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/shopify/draft-order', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Search medicine products
  Future<List<dynamic>> searchMedicineProducts(String medicineName) async {
    try {
      final response =
          await _dio.get('/api/v1/shopify/products/search/$medicineName');
      return _extractProducts(response.data);
    } catch (e) {
      return [];
    }
  }

  /// Get available medicines
  Future<List<dynamic>> getAvailableMedicines() async {
    try {
      final response = await _dio.get('/api/v1/shopify/products/available');
      final products = _extractProducts(response.data);
      if (products.isNotEmpty) return products;

      // Fallback 1: generic products endpoint
      final fallbackResponse = await _dio.get('/api/v1/shopify/products');
      final fallbackProducts = _extractProducts(fallbackResponse.data);
      if (fallbackProducts.isNotEmpty) return fallbackProducts;

      // Fallback 2: explicit all-products endpoint
      final allResponse = await _dio.get('/api/v1/shopify/products/all');
      return _extractProducts(allResponse.data);
    } catch (e) {
      try {
        final allResponse = await _dio.get('/api/v1/shopify/products/all');
        return _extractProducts(allResponse.data);
      } catch (_) {
        return [];
      }
    }
  }

  /// Get ALL Shopify products (for debugging)
  Future<Map<String, dynamic>> getAllShopifyProducts() async {
    try {
      final response = await _dio.get('/api/v1/shopify/products/all');
      List products = _extractProducts(response.data);
      return {'success': true, 'products': products, 'count': products.length};
    } catch (e) {
      try {
        final response = await _dio.get('/api/v1/shopify/products');
        List products = _extractProducts(response.data);
        return {
          'success': true,
          'products': products,
          'count': products.length
        };
      } catch (e2) {
        return {'success': false, 'error': e2.toString()};
      }
    }
  }

  /// Get Shopify store info
  Future<Map<String, dynamic>> getShopifyStoreInfo() async {
    try {
      final response = await _dio.get('/api/v1/shopify/store-info');
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get draft order status
  Future<Map<String, dynamic>> getDraftOrderStatus(String draftOrderId) async {
    try {
      final response =
          await _dio.get('/api/v1/shopify/draft-order/$draftOrderId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Validate prescription only (without creating order)
  Future<Map<String, dynamic>> validatePrescription(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/shopify/validate-prescription', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // ASTRA BRAIN AI ENDPOINTS
  // ============================================================

  /// General AI Chat with Astra Brain
  /// Supports session_id and history for memory
  Future<Map<String, dynamic>> brainChat(Map<String, dynamic> data) async {
    try {
      // Ensure role is doctor
      if (data['user_metadata'] == null) {
        data['user_metadata'] = {'role': 'doctor'};
      } else if (data['user_metadata'] is Map &&
          data['user_metadata']['role'] == null) {
        data['user_metadata']['role'] = 'doctor';
      }

      final response = await _dio.post(Apis.astra_brain_chat, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// AI-powered doctor summary generation
  Future<Map<String, dynamic>> generateDoctorSummary(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/brain/doctor-summary', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Analyze medication safety
  Future<Map<String, dynamic>> analyzeSafety(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/brain/analyze-safety', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Extract medication schedule from text
  Future<Map<String, dynamic>> extractSchedule(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/brain/extract-schedule', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Patient profile analysis
  Future<Map<String, dynamic>> profileAnalysis(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/brain/profile-analysis', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate wellness recommendations
  Future<Map<String, dynamic>> generateWellness(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/brain/generate-wellness', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get order details
  Future<Map<String, dynamic>> getOrderDetails(String draftOrderId) async {
    try {
      final response =
          await _dio.get('/api/v1/shopify/order-details/$draftOrderId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // ASTRA FILL (Voice & Text Processing)
  // ============================================================

  /// Process voice for prescription extraction
  Future<Map<String, dynamic>> processVoice(File audioFile, String userId,
      {String languageCode = "en-IN"}) async {
    try {
      String fileName = p.basename(audioFile.path);
      FormData formData = FormData.fromMap({
        "audio": await MultipartFile.fromFile(
          audioFile.path,
          filename: fileName,
          contentType: MediaType('audio', 'wav'),
        ),
        "user_id": userId,
        "language_code": languageCode,
      });

      final response = await _dio.post(
        '/api/v1/astra-fill/process-voice',
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Process text for prescription extraction
  Future<Map<String, dynamic>> processText(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/astra-fill/process-text', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Confirm extraction data
  Future<Map<String, dynamic>> confirmExtraction(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/astra-fill/confirm', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the latest Astra Fill record for a patient
  Future<Map<String, dynamic>> getLatestAstraFill(String patientId) async {
    try {
      final response = await _dio.get('/api/v1/astra-fill/latest/$patientId');
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }

  // ============================================================
  // DOCUMENT MANAGEMENT
  // ============================================================

  /// Upload a document (prescription image, lab report, etc.)
  Future<Map<String, dynamic>> uploadDocument(
      File file, String patientId, String documentType) async {
    try {
      String fileName = p.basename(file.path);
      String ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      String mimeType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
        "patient_id": patientId,
        "document_type": documentType,
      });

      final response = await _dio.post(
        '/api/v1/documents/upload',
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// List patient documents
  Future<List<dynamic>> listPatientDocuments(String patientId) async {
    try {
      final response = await _dio.get('/api/v1/documents/patient/$patientId');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get document download URL
  Future<String> getDocumentDownloadUrl(String documentId) async {
    try {
      final response = await _dio.get('/api/v1/documents/download/$documentId');
      return response.data['url'] ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Generate shareable link for document
  Future<String> generateShareLink(String documentId) async {
    try {
      final response =
          await _dio.get('/api/v1/documents/share-link/$documentId');
      return response.data['share_link'] ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Share document via WhatsApp
  Future<Map<String, dynamic>> shareDocumentViaWhatsApp(
      String documentId) async {
    try {
      final response =
          await _dio.post('/api/v1/documents/share-whatsapp/$documentId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _dio.delete('/api/v1/documents/$documentId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // ORDER MANAGEMENT
  // ============================================================

  /// Save prescription record to orders
  Future<Map<String, dynamic>> savePrescriptionRecord(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/orders/prescription/save', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch('/api/v1/orders/prescription/status', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get patient order history
  Future<List<dynamic>> getPatientOrderHistory(String patientId) async {
    try {
      final response = await _dio.get('/api/v1/orders/patient/$patientId');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get prescription details from orders
  Future<Map<String, dynamic>> getOrderPrescriptionDetails(
      String prescriptionId) async {
    try {
      final response =
          await _dio.get('/api/v1/orders/prescription/$prescriptionId');
      return response.data;
    } catch (e) {
      return {};
    }
  }

  /// Get orders by status
  Future<List<dynamic>> getOrdersByStatus(String status) async {
    try {
      final response = await _dio.get('/api/v1/orders/status/$status');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // PUSH NOTIFICATIONS
  // ============================================================

  /// Store FCM token for push notifications
  Future<Map<String, dynamic>> storeFcmToken(
      String token, String userId) async {
    try {
      final response =
          await _dio.post('/api/v1/notifications/store-fcm-token', data: {
        'token': token,
        'user_id': userId,
        'user_type': 'doctor',
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove FCM token
  Future<void> removeFcmToken(String patientId) async {
    try {
      await _dio.delete('/api/v1/notifications/remove-fcm-token/$patientId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get notification service status
  Future<Map<String, dynamic>> getNotificationServiceStatus() async {
    try {
      final response = await _dio.get('/api/v1/notifications/service-status');
      return response.data;
    } catch (e) {
      return {'status': 'unknown'};
    }
  }

  // ============================================================
  // MEDICINE REMINDERS
  // ============================================================

  /// Create reminders from prescription
  Future<Map<String, dynamic>> createRemindersFromPrescription(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
          '/api/v1/medicine-reminders/create-from-prescription',
          data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // TRANSLATION SERVICES
  // ============================================================

  /// Translate text
  Future<Map<String, dynamic>> translateText(String text, String targetLanguage,
      {String? sourceLanguage}) async {
    try {
      final response = await _dio.post('/api/v1/api/translate/', data: {
        'text': text,
        'target_language': targetLanguage,
        if (sourceLanguage != null) 'source_language': sourceLanguage,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get supported languages
  Future<List<dynamic>> getSupportedLanguages() async {
    try {
      final response = await _dio.get('/api/v1/api/translate/languages');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Auto-translate (detect source language)
  Future<Map<String, dynamic>> autoTranslate(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/api/translate/auto-translate', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // TREATMENT CENTERS
  // ============================================================

  /// Search nearby treatment centers
  Future<List<dynamic>> searchNearbyTreatmentCenters({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? centerType,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/api/treatment-centers/nearby/search',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          if (radiusKm != null) 'radius_km': radiusKm,
          if (centerType != null) 'center_type': centerType,
        },
      );
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // AI AGENT
  // ============================================================

  /// Ask AI Agent a question
  Future<Map<String, dynamic>> askAiAgent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/v1/api/ai-agent/ask', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get AI Agent status
  Future<Map<String, dynamic>> getAiAgentStatus() async {
    try {
      final response = await _dio.get('/api/v1/api/ai-agent/status');
      return response.data;
    } catch (e) {
      return {'status': 'offline'};
    }
  }

  // ============================================================
  // HEALTH CHECK ENDPOINTS
  // ============================================================

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if API is ready
  Future<bool> checkReady() async {
    try {
      final response = await _dio.get('/health/ready');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check Astra Brain health
  Future<Map<String, dynamic>> checkBrainHealth() async {
    try {
      final response = await _dio.get('/api/v1/brain/health');
      return response.data;
    } catch (e) {
      return {'status': 'offline'};
    }
  }

  // ============================================================
  // PRESCRIPTION PDF
  // ============================================================

  /// Send prescription PDF manually
  Future<Map<String, dynamic>> sendPrescriptionPdf(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/v1/prescription-pdf/send', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // COMPANION CASE
  // ============================================================

  /// Get the Astra companion case tied to a consultation - the AI
  /// companion's journey/progress for a patient's treatment, created at
  /// booking time by the patient app (astra_case_id on the Laravel
  /// appointment) and bound to this doctor from the moment of creation.
  ///
  /// GET /api/companion/case/{case_id} is unauthenticated at the route
  /// level (no Depends() auth, just rate limiting) - it's keyed by the
  /// case id itself, not a bearer token - so this intentionally bypasses
  /// the normal Firebase/app-token interceptor rather than risk a 401 on
  /// a route that was never gated that way.
  ///
  /// Returns the raw `case` object (id, journey_id, user_id, doctor_id,
  /// diagnosis, status, progress_percentage, adherence_score,
  /// treatment_duration_days, created_at, updated_at, ...) or null if the
  /// case doesn't exist (404) or the request otherwise fails - this is a
  /// best-effort companion panel, never a reason to block the appointment
  /// detail screen from rendering.
  Future<Map<String, dynamic>?> getCompanionCase(String caseId) async {
    try {
      final path = Apis.astra_companion_case
          .replaceAll('{case_id}', Uri.encodeComponent(caseId));
      final response = await Dio(BaseOptions(baseUrl: baseUrl)).get(path);
      final data = response.data;
      if (data is Map && data['success'] == true && data['case'] is Map) {
        return Map<String, dynamic>.from(data['case']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // COMPANION: PATIENT WELLNESS (endpoint not live yet)
  // ============================================================

  /// TODO(astra-backend): flip to true once
  /// GET /api/companion/wellness/{patient_id} exists in astra, after
  /// checking its response against [PatientWellness.fromJson].
  static const bool wellnessEndpointLive = false;

  /// The patient's self-reported wellness log and goals, or null when it
  /// isn't available (endpoint not live, 404, or any other failure) - the
  /// caller shows a "not available yet" state, never fabricated data.
  ///
  /// Uses the authenticated client, unlike [getCompanionCase]: this is the
  /// patient's own tracking data, so it should not be readable by id alone.
  Future<PatientWellness?> getPatientWellness(String patientId) async {
    if (!wellnessEndpointLive) return null;
    try {
      final path = Apis.astra_companion_wellness
          .replaceAll('{patient_id}', Uri.encodeComponent(patientId));
      final response = await _dio.get(path);
      final data = response.data;
      if (data is Map) {
        return PatientWellness.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // COMPANION: DOCTOR-SHARING CONSENT (no endpoint yet)
  // ============================================================

  /// Whether [patientId] has shared their full record with [doctorId].
  ///
  /// TODO(astra-backend): STUB. No consent endpoint exists in astra (the
  /// patient app stores the toggle on-device only), and no route has been
  /// agreed, so this deliberately makes no request and has no path
  /// constant. It always returns [SharingConsent.unknown], which every
  /// caller treats as limited sharing. Once the companion astra work adds
  /// the route, call it here and parse with [SharingConsent.fromJson];
  /// keep failures mapping to unknown, never to full.
  Future<SharingConsent> getSharingConsent(
      String doctorId, String patientId) async {
    return SharingConsent.unknown;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Handle and format errors
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      String message = 'Network error occurred';

      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (error.response?.statusCode == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (error.response?.statusCode == 404) {
          message = 'Resource not found.';
        } else if (error.response?.statusCode == 500) {
          message = 'Server error. Please try again later.';
        }
      } else if (error.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        message = 'Request timeout. Please try again.';
      } else if (error.type == DioExceptionType.connectionError) {
        message =
            'Unable to reach Astra server. Check internet/VPN or try again in a moment.';
      }

      return AstraApiException(message, error.response?.statusCode);
    }
    return Exception('An unexpected error occurred: $error');
  }

  /// Extract products list from various response structures
  List<dynamic> _extractProducts(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      final dynamic direct = data['products'] ??
          data['recommendations'] ??
          data['medicines'] ??
          data['items'];
      if (direct is List) return direct;

      final dynamic nestedData = data['data'];
      if (nestedData is List) return nestedData;
      if (nestedData is Map) {
        final dynamic nestedProducts = nestedData['products'] ??
            nestedData['items'] ??
            nestedData['medicines'];
        if (nestedProducts is List) return nestedProducts;
      }

      return [];
    }
    return [];
  }
}

/// Custom exception for Astra API errors
class AstraApiException implements Exception {
  final String message;
  final int? statusCode;

  AstraApiException(this.message, this.statusCode);

  @override
  String toString() => 'AstraApiException: $message (Status: $statusCode)';
}

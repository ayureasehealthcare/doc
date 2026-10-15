import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/astra/utils/astra_config.dart';
import 'package:doctro/core/astra/utils/astra_logger.dart';
import 'package:doctro/core/astra/utils/astra_exception.dart';

/// Astra Service
///
/// Enhanced service for communicating with Astra AI Backend.
/// Provides streaming support, retry logic, and comprehensive error handling.
class AstraService {
  static final AstraService _instance = AstraService._internal();
  late Dio _dio;

  /// Base URL for Astra API (includes the /api/v1/ prefix every endpoint
  /// below is actually served under - AstraConfig.baseUrl alone 404s).
  final String baseUrl = AstraConfig.apiBaseUrl;

  factory AstraService() => _instance;

  AstraService._internal() {
    _initDio();
  }

  void _initDio() {
    // Ensure baseUrl always ends with a slash
    String sanitizedBaseUrl = baseUrl;
    if (!sanitizedBaseUrl.endsWith('/')) {
      sanitizedBaseUrl += '/';
    }

    _dio = Dio(BaseOptions(
      baseUrl: sanitizedBaseUrl,
      connectTimeout: Duration(seconds: AstraConfig.connectTimeoutSeconds),
      receiveTimeout: Duration(seconds: AstraConfig.receiveTimeoutSeconds),
    ));

    // Add interceptors for auth and logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  // ============================================================
  // REQUEST INTERCEPTOR
  // ============================================================

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final startTime = DateTime.now();

    // Prefer the Astra-issued session token (from /auth/login) once we have
    // one: most Astra endpoints validate that token specifically and reject
    // a raw Firebase ID token, even though a Firebase user stays signed in
    // for the whole session (see the identical pattern in astra_api_service.dart).
    final String appToken =
        SharedPreferenceHelper.getString(Preferences.auth_token);
    if (appToken.isNotEmpty && appToken != 'N_A') {
      options.headers['Authorization'] = 'Bearer $appToken';
    } else {
      // No Astra session token yet - fall back to the Firebase ID token.
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await user.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    // Set default content type
    if (options.headers['Content-Type'] == null) {
      options.headers['Content-Type'] = 'application/json';
    }

    // Log request
    AstraLogger.logRequest(
      options.method,
      '${options.baseUrl}${options.path}',
      headers: options.headers,
    );

    // Store start time for duration calculation
    options.extra['_startTime'] = startTime;

    return handler.next(options);
  }

  // ============================================================
  // RESPONSE INTERCEPTOR
  // ============================================================

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['_startTime'] as DateTime?;
    final duration =
        startTime != null ? DateTime.now().difference(startTime) : null;

    AstraLogger.logResponse(
      '${response.requestOptions.baseUrl}${response.requestOptions.path}',
      response.statusCode ?? 0,
      duration: duration,
    );

    return handler.next(response);
  }

  // ============================================================
  // ERROR INTERCEPTOR
  // ============================================================

  Future<void> _onError(
      DioException error, ErrorInterceptorHandler handler) async {
    AstraLogger.logApiError(
      '${error.requestOptions.baseUrl}${error.requestOptions.path}',
      error,
      statusCode: error.response?.statusCode,
    );

    return handler.next(error);
  }

  bool _isConnectionLevelError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final String text = (error.message ?? '').toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('timed out');
  }

  // ============================================================
  // CHAT METHODS
  // ============================================================

  /// Chat with Astra Brain
  Future<Map<String, dynamic>> chat(Map<String, dynamic> data) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.brainChat,
        data: data,
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Stream chat with Astra Brain
  Stream<ChatStreamEvent> streamChat(Map<String, dynamic> data) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        AstraConfig.brainChat,
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        // Process complete events
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final rawLine in lines) {
          if (rawLine.trim().isEmpty) continue;

          // Strip a leading SSE "data: " prefix if present, so a JSON
          // payload the backend sends this way (e.g. {"error": "..."})
          // still gets decoded as JSON below rather than treated as
          // literal text.
          final line = rawLine.startsWith('data:')
              ? rawLine.substring(5).trim()
              : rawLine;
          if (line.isEmpty) continue;

          // Try to parse as JSON
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            if (json['error'] != null) {
              yield ChatStreamEvent.error(json['error'].toString());
            } else {
              yield ChatStreamEvent.data(json);
            }
          } catch (e) {
            // Not JSON - progress/plain text chunk.
            yield ChatStreamEvent.data({'text': line});
          }
        }
      }

      yield ChatStreamEvent.done();
    } on DioException catch (e) {
      yield ChatStreamEvent.error(_formatError(e));
    } catch (e, st) {
      yield ChatStreamEvent.error(e.toString());
      AstraLogger.e('Stream chat error', error: e, stackTrace: st);
    }
  }

  // ============================================================
  // PRESCRIPTION METHODS
  // ============================================================

  /// Create a prescription
  Future<Map<String, dynamic>> createPrescription(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.prescriptionCreate,
        data: data,
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get prescription by ID
  Future<Map<String, dynamic>> getPrescription(String prescriptionId) async {
    try {
      final url = AstraConfig.prescriptionGet
          .replaceAll('{id}', Uri.encodeComponent(prescriptionId));
      final response = await _getWithRetry(url);
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get prescriptions for a patient
  Future<List<dynamic>> getPatientPrescriptions(String patientId) async {
    try {
      final url = AstraConfig.prescriptionPatient.replaceAll(
        '{patient_id}',
        Uri.encodeComponent(patientId),
      );
      final response = await _getWithRetry(url);
      return _parseList(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Execute prescription workflow
  Future<Map<String, dynamic>> executeWorkflow(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.prescriptionWorkflow,
        data: data,
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // PATIENT METHODS
  // ============================================================

  /// Search patients
  Future<List<dynamic>> searchPatients(String searchTerm) async {
    try {
      final url = AstraConfig.patientSearch
          .replaceAll('{term}', Uri.encodeComponent(searchTerm));
      final response = await _getWithRetry(url);
      return _parseList(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get patient profile
  Future<Map<String, dynamic>> getPatientProfile(String patientId) async {
    try {
      final url = AstraConfig.patientProfile
          .replaceAll('{id}', Uri.encodeComponent(patientId));
      final response = await _getWithRetry(url);
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // ASTRA FILL METHODS
  // ============================================================

  /// Process voice input
  Future<Map<String, dynamic>> processVoice(
    File audioFile,
    String userId, {
    String languageCode = 'en-IN',
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'user_id': userId,
        'language_code': languageCode,
      });

      final response = await _dio.post(
        AstraConfig.astraFillProcessVoice,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: Duration(seconds: AstraConfig.streamTimeoutSeconds),
          receiveTimeout: Duration(seconds: AstraConfig.streamTimeoutSeconds),
        ),
      );

      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Process text input
  Future<Map<String, dynamic>> processText(Map<String, dynamic> data) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.astraFillProcessText,
        data: data,
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get latest Astra Fill for patient
  Future<Map<String, dynamic>> getLatestAstraFill(String patientId) async {
    try {
      final response = await _getWithRetry(
        'astra-fill/patient/$patientId/latest',
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // MEDICINE/HEALTH METHODS
  // ============================================================

  /// Analyze medication safety
  Future<Map<String, dynamic>> analyzeSafety(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.brainAnalyzeSafety,
        data: data,
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Extract medication schedule from text
  Future<Map<String, dynamic>> extractSchedule(String text) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.brainExtractSchedule,
        data: {'text': text},
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate doctor summary
  Future<Map<String, dynamic>> generateDoctorSummary(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _postWithRetry(
        AstraConfig.brainDoctorSummary,
        data: data,
      );
      return _parseResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // HEALTH CHECK METHODS
  // ============================================================

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(AstraConfig.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if API is ready
  Future<bool> checkReady() async {
    try {
      final response = await _dio.get(AstraConfig.healthReady);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check Brain health
  Future<Map<String, dynamic>> checkBrainHealth() async {
    try {
      final response = await _getWithRetry(AstraConfig.brainHealth);
      return _parseResponse(response);
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<Response<dynamic>> _postWithRetry(
    String path, {
    dynamic data,
    int retryCount = 0,
  }) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      if (retryCount < AstraConfig.maxRetries && _isRetryableError(e)) {
        await Future.delayed(
          Duration(milliseconds: AstraConfig.retryDelayMs * (retryCount + 1)),
        );
        return _postWithRetry(path, data: data, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _getWithRetry(
    String path, {
    int retryCount = 0,
  }) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      if (retryCount < AstraConfig.maxRetries && _isRetryableError(e)) {
        await Future.delayed(
          Duration(milliseconds: AstraConfig.retryDelayMs * (retryCount + 1)),
        );
        return _getWithRetry(path, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  bool _isRetryableError(DioException error) {
    // Retry on connection errors and 5xx server errors
    if (_isConnectionLevelError(error)) return true;
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> _parseResponse(dynamic response) {
    dynamic data = response;
    if (data is Response) data = data.data;
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      // brain/chat replies as SSE ("data: {...}" per chunk, blank-line
      // separated) even for this plain, non-streaming POST, and/or with a
      // Content-Type that stops Dio auto-decoding JSON, leaving `data` as a
      // raw string - decode it manually rather than silently losing the
      // whole body. There can be one chunk (e.g. a single error) or many
      // (a real answer streamed one token at a time), so every "data:"
      // line's content/text field is collected and concatenated; an error
      // chunk short-circuits immediately.
      final text = data.trim();
      if (text.isEmpty) return {};
      // Anchored to the start, not a substring check: a plain JSON body
      // can legitimately contain the text "data:" inside a field value
      // (e.g. {"response": "Patient data: within normal range."}), which
      // would otherwise misroute a normal reply into the SSE branch below,
      // find no line actually starting with "data:", and silently return
      // an empty map instead of falling through to the plain-JSON decode.
      if (text.startsWith('data:')) {
        final buffer = StringBuffer();
        for (final rawLine in text.split('\n')) {
          final line = rawLine.trim();
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload.isEmpty) continue;
          try {
            final json = jsonDecode(payload);
            if (json is Map<String, dynamic>) {
              if (json['error'] != null) {
                return {'error': json['error']};
              }
              buffer.write(
                json['content']?.toString() ?? json['text']?.toString() ?? '',
              );
            }
          } catch (_) {
            // Not JSON - ignore this chunk.
          }
        }
        if (buffer.isNotEmpty) return {'response': buffer.toString()};
        return {};
      }
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Not JSON - fall through to empty map below.
      }
    }
    return {};
  }

  /// Parse a response that is expected to be a JSON list.
  /// Accepts a raw list, a [Response] whose data is a list, or a map that
  /// wraps the list under common keys (data/results/items).
  List<dynamic> _parseList(dynamic response) {
    dynamic data = response;
    if (response is Response) {
      data = response.data;
    }
    if (data is List) return List<dynamic>.from(data);
    if (data is Map) {
      for (final key in ['data', 'results', 'items', 'prescriptions']) {
        if (data[key] is List) {
          return List<dynamic>.from(data[key]);
        }
      }
    }
    return [];
  }

  AstraException _handleError(dynamic error) {
    if (error is DioException) {
      String message = 'Network error occurred';

      if (error.response != null) {
        final data = error.response?.data;

        // Try to extract error message from response
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        } else if (error.response?.statusCode == 401) {
          message = 'Unauthorized. Please login again.';
          return AstraAuthException.sessionExpired();
        } else if (error.response?.statusCode == 403) {
          message = 'Access forbidden.';
        } else if (error.response?.statusCode == 404) {
          message = 'Resource not found.';
        } else if (error.response?.statusCode == 422) {
          message = 'Validation error. Please check input.';
        } else if (error.response?.statusCode == 500) {
          message = 'Server error. Please try again later.';
        }
      } else if (error.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        message = 'Request timeout. Please try again.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'Unable to reach Astra server. Check internet/VPN.';
      }

      return AstraApiException(
        message,
        statusCode: error.response?.statusCode,
        originalError: error,
      );
    }

    if (error is AstraException) {
      return error;
    }

    return AstraException(
      error.toString(),
      originalError: error,
    );
  }

  String _formatError(DioException error) {
    if (error.response?.data is Map) {
      final detail = error.response?.data['detail'];
      if (detail != null) return detail.toString();
    }
    return error.message ?? 'Unknown error';
  }
}

// ============================================================
// STREAM EVENT CLASS
// ============================================================

/// Event types for chat streaming
class ChatStreamEvent {
  final ChatStreamEventType type;
  final dynamic data;
  final String? error;

  ChatStreamEvent._({
    required this.type,
    this.data,
    this.error,
  });

  factory ChatStreamEvent.data(Map<String, dynamic> json) {
    return ChatStreamEvent._(type: ChatStreamEventType.data, data: json);
  }

  factory ChatStreamEvent.done() {
    return ChatStreamEvent._(type: ChatStreamEventType.done);
  }

  factory ChatStreamEvent.error(String message) {
    return ChatStreamEvent._(type: ChatStreamEventType.error, error: message);
  }

  factory ChatStreamEvent.progress(double progress) {
    return ChatStreamEvent._(
      type: ChatStreamEventType.progress,
      data: progress,
    );
  }
}

enum ChatStreamEventType {
  data,
  progress,
  done,
  error,
}

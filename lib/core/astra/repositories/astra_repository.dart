import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctro/core/astra/models/conversation_model.dart';
import 'package:doctro/core/astra/services/astra_service.dart';
import 'package:doctro/core/astra/utils/astra_config.dart';
import 'package:doctro/core/astra/utils/astra_logger.dart';
import 'package:doctro/core/astra/utils/astra_exception.dart';

/// Astra Repository
///
/// Repository layer for Astra AI operations.
/// Handles caching, offline queue, and data transformation.
class AstraRepository {
  static final AstraRepository _instance = AstraRepository._internal();

  final AstraService _service = AstraService();

  Box<dynamic>? _cacheBox;
  Box<dynamic>? _conversationBox;
  Box<dynamic>? _offlineQueueBox;

  bool _initialized = false;

  factory AstraRepository() => _instance;

  AstraRepository._internal();

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      _cacheBox = await Hive.openBox(AstraConfig.offlineBoxName);
      _conversationBox = await Hive.openBox(AstraConfig.conversationBoxName);
      _offlineQueueBox = await Hive.openBox('astra_offline_queue');

      _initialized = true;
      AstraLogger.i('AstraRepository initialized successfully');
    } catch (e, st) {
      AstraLogger.e('Failed to initialize AstraRepository',
          error: e, stackTrace: st);
      // Continue without caching if initialization fails
      _initialized = true; // Prevent repeated init attempts
    }
  }

  // ============================================================
  // CHAT METHODS
  // ============================================================

  /// Send a chat message to Astra Brain
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String userId,
    String? sessionId,
    ConversationContext? context,
  }) async {
    try {
      final data = {
        'q': message,
        'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
        if (context != null) 'user_metadata': context.toMetadata(),
      };

      final response = await _service.chat(data);

      // Cache successful response
      if (AstraConfig.enableCaching && _cacheBox != null) {
        await _cacheMessage(userId, message, response);
      }

      return response;
    } catch (e) {
      // If offline and caching enabled, return cached response
      if (AstraConfig.enableOfflineQueue && e is AstraNetworkException) {
        final cached = await _getCachedResponse(userId, message);
        if (cached != null) {
          AstraLogger.w('Using cached response due to network error');
          return cached;
        }

        // Queue for later
        await _queueOfflineMessage(
          userId: userId,
          message: message,
          context: context,
        );
        throw AstraNetworkException(
          'Message queued for when connection is restored',
          isConnectionError: true,
        );
      }
      rethrow;
    }
  }

  /// Stream chat response
  Stream<ChatStreamEvent> streamMessage({
    required String message,
    required String userId,
    String? sessionId,
    ConversationContext? context,
  }) {
    final data = {
      'q': message,
      'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (context != null) 'user_metadata': context.toMetadata(),
    };

    return _service.streamChat(data);
  }

  // ============================================================
  // PRESCRIPTION METHODS
  // ============================================================

  /// Create a prescription
  Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required String doctorId,
    required List<Map<String, dynamic>> medicines,
    String? diagnosis,
    String? notes,
  }) async {
    final data = {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'medicines': medicines,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (notes != null) 'notes': notes,
    };

    return _service.createPrescription(data);
  }

  /// Get prescriptions for a patient
  Future<List<dynamic>> getPatientPrescriptions(String patientId) async {
    return _service.getPatientPrescriptions(patientId);
  }

  /// Execute prescription workflow
  Future<Map<String, dynamic>> executeWorkflow({
    required String prescriptionId,
    required String action,
  }) async {
    return _service.executeWorkflow({
      'prescription_id': prescriptionId,
      'action': action,
    });
  }

  // ============================================================
  // PATIENT METHODS
  // ============================================================

  /// Search patients
  Future<List<dynamic>> searchPatients(String searchTerm) async {
    return _service.searchPatients(searchTerm);
  }

  /// Get patient profile with Astra Fill data
  Future<Map<String, dynamic>> getPatientProfile(String patientId) async {
    return _service.getPatientProfile(patientId);
  }

  // ============================================================
  // MEDICINE METHODS
  // ============================================================

  /// Analyze medication safety
  Future<Map<String, dynamic>> analyzeMedicationSafety(
    List<String> medicineNames,
  ) async {
    // SafetyRequest in astra's OpenAPI takes one free-text field.
    return _service.analyzeSafety({
      'text': 'Medicines: ${medicineNames.join(', ')}',
    });
  }

  /// Extract medication schedule from text
  Future<Map<String, dynamic>> extractMedicationSchedule(String text) async {
    return _service.extractSchedule(text);
  }

  /// Generate doctor summary
  Future<Map<String, dynamic>> generateDoctorSummary({
    required String patientId,
    String? chiefComplaint,
    String? symptoms,
    String? vitalSigns,
  }) async {
    // SummaryRequest in astra's OpenAPI takes one free-text `notes` field;
    // the structured keys sent before were rejected.
    return _service.generateDoctorSummary({
      'notes': [
        'Patient ID: $patientId',
        if (chiefComplaint != null) 'Chief complaint: $chiefComplaint',
        if (symptoms != null) 'Symptoms: $symptoms',
        if (vitalSigns != null) 'Vital signs: $vitalSigns',
      ].join('\n'),
    });
  }

  // ============================================================
  // ASTRA FILL METHODS
  // ============================================================

  /// Process voice input
  Future<Map<String, dynamic>> processVoice(
    dynamic audioFile,
    String userId, {
    String languageCode = 'en-IN',
  }) async {
    return _service.processVoice(
      audioFile,
      userId,
      languageCode: languageCode,
    );
  }

  /// Process text input
  Future<Map<String, dynamic>> processText({
    required String text,
    String? patientId,
  }) async {
    return _service.processText({
      'text': text,
      if (patientId != null) 'patient_id': patientId,
    });
  }

  /// Get latest Astra Fill for patient
  Future<Map<String, dynamic>> getLatestAstraFill(String patientId) async {
    return _service.getLatestAstraFill(patientId);
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

  /// Check if Astra Brain is healthy
  Future<bool> isBrainHealthy() async {
    try {
      final health = await _service.checkBrainHealth();
      return health['status'] == 'online' || health['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  /// Check if API is accessible
  Future<bool> isApiAccessible() async {
    return _service.checkHealth();
  }

  // ============================================================
  // CONVERSATION HISTORY
  // ============================================================

  /// Save conversation message
  Future<void> saveMessage(String userId, AstraMessage message) async {
    if (_conversationBox == null || !AstraConfig.enableCaching) return;

    try {
      final key = 'conversation_$userId';
      final List<dynamic> messages =
          jsonDecode(_conversationBox!.get(key, defaultValue: '[]') as String);

      messages.add(message.toJson());

      // Limit history size
      if (messages.length > AstraConfig.maxLocalHistoryMessages) {
        messages.removeAt(0);
      }

      await _conversationBox!.put(key, jsonEncode(messages));
    } catch (e, st) {
      AstraLogger.e('Failed to save message', error: e, stackTrace: st);
    }
  }

  /// Get conversation history with pagination support
  Future<List<AstraMessage>> getConversationHistory(
    String userId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    if (_conversationBox == null) return [];

    try {
      final key = 'conversation_$userId';
      final String? data = _conversationBox!.get(key) as String?;

      if (data == null || data.isEmpty) return [];

      final List<dynamic> messages = jsonDecode(data);
      var allMessages = messages
          .map((m) => AstraMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      // Sort by createdAt descending (newest first)
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Find pagination starting point
      if (beforeMessageId != null) {
        final index = allMessages.indexWhere((m) => m.id == beforeMessageId);
        if (index > 0) {
          allMessages = allMessages.sublist(index + 1);
        }
      }

      // Apply limit
      if (limit > 0 && allMessages.length > limit) {
        allMessages = allMessages.sublist(0, limit);
      }

      // Return in chronological order for display
      return allMessages.reversed.toList();
    } catch (e, st) {
      AstraLogger.e('Failed to get conversation history',
          error: e, stackTrace: st);
      return [];
    }
  }

  /// Clear conversation history
  Future<void> clearConversationHistory(String userId) async {
    if (_conversationBox == null) return;

    try {
      final key = 'conversation_$userId';
      await _conversationBox!.delete(key);
    } catch (e, st) {
      AstraLogger.e('Failed to clear conversation history',
          error: e, stackTrace: st);
    }
  }

  // ============================================================
  // CONTEXT PREFETCHING
  // ============================================================

  /// Prefetch context for faster responses
  Future<void> prefetchContext({
    required String patientId,
    String? recentSymptoms,
  }) async {
    if (_cacheBox == null) return;

    try {
      final key = 'context_$patientId';
      final data = {
        'patientId': patientId,
        'symptoms': recentSymptoms,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _cacheBox!.put(key, jsonEncode(data));
      AstraLogger.d('Context prefetched for: $patientId');
    } catch (e, st) {
      AstraLogger.e('Failed to prefetch context', error: e, stackTrace: st);
    }
  }

  /// Get cached context
  Map<String, dynamic>? getCachedContext(String patientId) {
    if (_cacheBox == null) return null;

    try {
      final key = 'context_$patientId';
      final String? data = _cacheBox!.get(key) as String?;
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore cache read errors
    }
    return null;
  }

  // ============================================================
  // CACHING
  // ============================================================

  Future<void> _cacheMessage(
    String userId,
    String message,
    Map<String, dynamic> response,
  ) async {
    if (_cacheBox == null) return;

    try {
      final key = _generateCacheKey(userId, message);
      final data = {
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _cacheBox!.put(key, jsonEncode(data));
    } catch (e, st) {
      AstraLogger.e('Failed to cache message', error: e, stackTrace: st);
    }
  }

  Future<Map<String, dynamic>?> _getCachedResponse(
    String userId,
    String message,
  ) async {
    if (_cacheBox == null) return null;

    try {
      final key = _generateCacheKey(userId, message);
      final String? data = _cacheBox!.get(key) as String?;

      if (data == null) return null;

      final Map<String, dynamic> cached = jsonDecode(data);
      final timestamp = DateTime.parse(cached['timestamp']);

      // Check if cache is still valid (1 hour)
      if (DateTime.now().difference(timestamp).inHours > 1) {
        await _cacheBox!.delete(key);
        return null;
      }

      return cached['response'] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  String _generateCacheKey(String userId, String message) {
    // Simple hash for cache key
    final hash = message.hashCode.abs().toString();
    return '${userId}_$hash';
  }

  // ============================================================
  // OFFLINE QUEUE
  // ============================================================

  Future<void> _queueOfflineMessage({
    required String userId,
    required String message,
    ConversationContext? context,
  }) async {
    if (_offlineQueueBox == null || !AstraConfig.enableOfflineQueue) return;

    try {
      final queue = _getOfflineQueue();

      // Check queue size limit
      if (queue.length >= AstraConfig.maxOfflineQueueSize) {
        queue.removeAt(0); // Remove oldest
      }

      queue.add({
        'user_id': userId,
        'message': message,
        'context': context?.toMetadata(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _offlineQueueBox!.put('queue', jsonEncode(queue));
    } catch (e, st) {
      AstraLogger.e('Failed to queue offline message',
          error: e, stackTrace: st);
    }
  }

  List<dynamic> _getOfflineQueue() {
    try {
      final String? data = _offlineQueueBox!.get('queue') as String?;
      if (data == null || data.isEmpty) return [];
      return jsonDecode(data) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  /// Get and clear offline queue
  Future<List<Map<String, dynamic>>> flushOfflineQueue() async {
    if (_offlineQueueBox == null) return [];

    try {
      final queue = _getOfflineQueue()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      await _offlineQueueBox!.delete('queue');

      return queue;
    } catch (e, st) {
      AstraLogger.e('Failed to flush offline queue', error: e, stackTrace: st);
      return [];
    }
  }

  /// Get offline queue size
  Future<int> getOfflineQueueSize() async {
    return _getOfflineQueue().length;
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cacheBox?.clear();
      await _conversationBox?.clear();
      await _offlineQueueBox?.clear();
      AstraLogger.i('Astra cache cleared');
    } catch (e, st) {
      AstraLogger.e('Failed to clear cache', error: e, stackTrace: st);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _cacheBox?.close();
    await _conversationBox?.close();
    await _offlineQueueBox?.close();
    _initialized = false;
  }
}

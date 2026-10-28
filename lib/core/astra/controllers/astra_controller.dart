import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/astra/models/conversation_model.dart';
import 'package:doctro/core/astra/actions/action_models.dart';
import 'package:doctro/core/astra/actions/action_dispatcher.dart';
import 'package:doctro/core/astra/repositories/astra_repository.dart';
import 'package:doctro/core/astra/services/astra_service.dart';
import 'package:doctro/core/astra/utils/astra_logger.dart';
import 'package:doctro/core/astra/utils/astra_exception.dart';

/// Astra Controller
///
/// Provider-based controller for managing Astra AI conversations.
/// Handles message sending, streaming, action dispatching, and state management.
class AstraController extends ChangeNotifier {
  static final AstraController _instance = AstraController._internal();

  final AstraRepository _repository = AstraRepository();
  final ActionDispatcher _actionDispatcher = ActionDispatcher.instance;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isStreaming = false;
  bool _isBrainHealthy = false;

  String? _currentUserId;
  String? _sessionId;
  String? _currentPatientId;
  ConversationContext? _currentContext;

  List<AstraMessage> _messages = [];
  List<AstraNavigationAction> _pendingActions = [];
  AstraMessage? _streamingMessage;

  String? _errorMessage;

  StreamSubscription<ChatStreamEvent>? _streamSubscription;

  factory AstraController() => _instance;

  AstraController._internal();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  bool get isBrainHealthy => _isBrainHealthy;

  String? get currentUserId => _currentUserId;
  String? get sessionId => _sessionId;
  String? get currentPatientId => _currentPatientId;
  ConversationContext? get currentContext => _currentContext;

  List<AstraMessage> get messages => List.unmodifiable(_messages);
  List<AstraNavigationAction> get pendingActions =>
      List.unmodifiable(_pendingActions);
  AstraMessage? get streamingMessage => _streamingMessage;

  String? get errorMessage => _errorMessage;

  /// Get doctor ID from preferences. `Preferences.userId` is a stale key -
  /// nothing in the app ever writes it; the login flow sets
  /// `Preferences.doctorId`, which is what DoctorContext.fromPreferences()
  /// also prefers.
  String get doctorId {
    return SharedPreferenceHelper.getStringOrNull(Preferences.doctorId) ??
        SharedPreferenceHelper.getString(Preferences.userId);
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the controller
  Future<void> initialize({
    String? patientId,
    String? patientName,
    String? appointmentId,
  }) async {
    if (_initialized) return;

    try {
      AstraLogger.i('Initializing AstraController');

      // Initialize repository
      await _repository.initialize();

      // Set current user
      _currentUserId = doctorId.isNotEmpty ? doctorId : null;

      // Set context if patient is provided
      if (patientId != null) {
        _currentPatientId = patientId;
        _currentContext = ConversationContext(
          patientId: patientId,
          patientName: patientName,
          appointmentId: appointmentId,
          doctorId: _currentUserId,
          screenContext: 'patient_details',
        );
      }

      // Load conversation history
      if (_currentUserId != null) {
        _messages = await _repository.getConversationHistory(_currentUserId!);
      }

      // Check brain health
      await _checkBrainHealth();

      _initialized = true;
      notifyListeners();

      AstraLogger.i('AstraController initialized successfully');
    } catch (e, st) {
      AstraLogger.e('Failed to initialize AstraController',
          error: e, stackTrace: st);
      _errorMessage = 'Failed to initialize: $e';
      _initialized = true; // Prevent retry loops
      notifyListeners();
    }
  }

  /// Set patient context
  void setPatientContext({
    required String patientId,
    String? patientName,
    String? appointmentId,
    String? prescriptionId,
    String? screenContext,
  }) {
    _currentPatientId = patientId;
    _currentContext = ConversationContext(
      patientId: patientId,
      patientName: patientName,
      appointmentId: appointmentId,
      prescriptionId: prescriptionId,
      screenContext: screenContext,
      doctorId: _currentUserId,
    );
    notifyListeners();
  }

  /// Clear patient context
  void clearPatientContext() {
    _currentPatientId = null;
    _currentContext = null;
    notifyListeners();
  }

  // ============================================================
  // BRAIN HEALTH CHECK
  // ============================================================

  Future<void> _checkBrainHealth() async {
    try {
      _isBrainHealthy = await _repository.isBrainHealthy();
      AstraLogger.d('Brain health: $_isBrainHealthy');
    } catch (e) {
      _isBrainHealthy = false;
      AstraLogger.w('Brain health check failed: $e');
    }
  }

  /// Refresh brain health status
  Future<void> refreshBrainHealth() async {
    await _checkBrainHealth();
    notifyListeners();
  }

  // ============================================================
  // MESSAGE HANDLING
  // ============================================================

  /// Send a message to Astra Brain
  Future<void> sendMessage(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.trim().isEmpty) return;

    // Check if user ID is available
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _currentUserId = doctorId;
    }

    if (_currentUserId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create user message
      final userMessage = AstraMessage.user(content: text);
      _messages.add(userMessage);

      // Save to history
      await _repository.saveMessage(_currentUserId!, userMessage);
      notifyListeners();

      // Send to Astra
      final response = await _repository.sendMessage(
        message: text,
        userId: _currentUserId!,
        sessionId: _sessionId,
        context: _currentContext,
      );

      // A 200 response can still carry a backend-side failure (e.g. the AI
      // engine itself is degraded) as {"error": "..."} rather than an HTTP
      // error status - without this check it silently became a blank
      // assistant bubble, since none of _parseAssistantResponse's expected
      // content keys are present.
      if (response['error'] != null) {
        throw AstraException(response['error'].toString());
      }

      // Parse and add assistant response
      final assistantMessage = _parseAssistantResponse(response);
      _messages.add(assistantMessage);

      // Save to history
      await _repository.saveMessage(_currentUserId!, assistantMessage);

      // Extract and store pending actions
      _pendingActions = _actionDispatcher.extractActions(response);

      // Check brain health after successful request
      await _checkBrainHealth();

      _isLoading = false;
      notifyListeners();
    } on AstraNetworkException catch (e) {
      _handleNetworkError(e, text);
    } on AstraException catch (e) {
      _handleError(e);
    } catch (e, st) {
      AstraLogger.e('Send message failed', error: e, stackTrace: st);
      _handleError(AstraException('Failed to send message: $e'));
    }
  }

  /// Send message with streaming response
  Future<void> sendMessageStreaming(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.trim().isEmpty) return;

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _currentUserId = doctorId;
    }

    if (_currentUserId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      _isStreaming = true;
      _errorMessage = null;
      notifyListeners();

      // Create and add user message
      final userMessage = AstraMessage.user(content: text);
      _messages.add(userMessage);
      await _repository.saveMessage(_currentUserId!, userMessage);

      // Create streaming message placeholder
      _streamingMessage = AstraMessage.streaming(content: '');
      _messages.add(_streamingMessage!);
      notifyListeners();

      // Stream response
      String fullResponse = '';
      List<AstraNavigationAction> actions = [];

      await for (final event in _repository.streamMessage(
        message: text,
        userId: _currentUserId!,
        sessionId: _sessionId,
        context: _currentContext,
      )) {
        switch (event.type) {
          case ChatStreamEventType.data:
            final data = event.data as Map<String, dynamic>;
            final textChunk =
                data['text']?.toString() ?? data['content']?.toString() ?? '';
            fullResponse += textChunk;

            // Update streaming message
            _streamingMessage = AstraMessage.streaming(
              content: fullResponse,
              progress: _estimateProgress(fullResponse),
            );

            // Find any actions in the stream
            final newActions = _actionDispatcher.extractActions(data);
            if (newActions.isNotEmpty) {
              actions.addAll(newActions);
            }

            notifyListeners();
            break;

          case ChatStreamEventType.progress:
            _streamingMessage = AstraMessage.streaming(
              content: fullResponse,
              progress: event.data as double,
            );
            notifyListeners();
            break;

          case ChatStreamEventType.done:
            // Finalize the streaming message
            _messages.remove(_streamingMessage);

            final assistantMessage = AstraMessage.assistant(
              content: fullResponse,
              action: actions.isNotEmpty ? actions.first : null,
            );
            _messages.add(assistantMessage);
            await _repository.saveMessage(_currentUserId!, assistantMessage);

            _pendingActions = actions;
            _streamingMessage = null;
            break;

          case ChatStreamEventType.error:
            _messages.remove(_streamingMessage);
            _messages.add(AstraMessage.system(
              content: 'Error: ${event.error}',
              isError: true,
            ));
            _streamingMessage = null;
            _errorMessage = event.error;
            break;
        }
      }

      await _checkBrainHealth();
      _isStreaming = false;
      notifyListeners();
    } on AstraNetworkException catch (e) {
      _handleNetworkError(e, text);
    } on AstraException catch (e) {
      _handleError(e);
    } catch (e, st) {
      AstraLogger.e('Streaming message failed', error: e, stackTrace: st);
      _handleError(AstraException('Failed to stream message: $e'));
    }
  }

  /// Cancel ongoing stream
  void cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    if (_streamingMessage != null) {
      _messages.remove(_streamingMessage);
      _streamingMessage = null;
    }

    _isStreaming = false;
    notifyListeners();
  }

  // ============================================================
  // ACTION HANDLING
  // ============================================================

  /// Execute pending action
  Future<ActionResult> executeAction(AstraNavigationAction action) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _actionDispatcher.dispatch(action);

      // Remove from pending if successful
      if (result.success) {
        _pendingActions.remove(action);
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e, st) {
      AstraLogger.e('Execute action failed', error: e, stackTrace: st);
      _handleError(AstraException('Failed to execute action: $e'));
      return ActionResult.failure('Failed to execute action: $e');
    }
  }

  /// Execute all pending actions
  Future<void> executeAllPendingActions() async {
    for (final action in List.from(_pendingActions)) {
      await executeAction(action);
    }
  }

  /// Execute first high priority action
  Future<void> executeFirstHighPriorityAction() async {
    final highPriority = _pendingActions
        .where((a) =>
            a.priority == ActionPriority.high ||
            a.priority == ActionPriority.critical)
        .toList();

    if (highPriority.isNotEmpty) {
      await executeAction(highPriority.first);
    }
  }

  /// Clear pending actions
  void clearPendingActions() {
    _pendingActions.clear();
    notifyListeners();
  }

  // ============================================================
  // CONVERSATION MANAGEMENT
  // ============================================================

  /// Clear conversation history
  Future<void> clearConversation() async {
    try {
      if (_currentUserId != null) {
        await _repository.clearConversationHistory(_currentUserId!);
      }
      _messages.clear();
      _pendingActions.clear();
      _sessionId = null;
      notifyListeners();
      AstraLogger.i('Conversation cleared');
    } catch (e, st) {
      AstraLogger.e('Failed to clear conversation', error: e, stackTrace: st);
    }
  }

  /// Load conversation from history
  Future<void> loadConversation() async {
    if (_currentUserId == null) return;

    try {
      _messages = await _repository.getConversationHistory(_currentUserId!);
      notifyListeners();
    } catch (e, st) {
      AstraLogger.e('Failed to load conversation', error: e, stackTrace: st);
    }
  }

  // ============================================================
  // PRESCRIPTION HELPERS
  // ============================================================

  /// Generate prescription draft using AI
  Future<Map<String, dynamic>?> generatePrescriptionDraft({
    required String patientId,
    String? chiefComplaint,
    String? symptoms,
    String? vitalSigns,
  }) async {
    if (!_initialized) {
      await initialize(patientId: patientId);
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _repository.generateDoctorSummary(
        patientId: patientId,
        chiefComplaint: chiefComplaint,
        symptoms: symptoms,
        vitalSigns: vitalSigns,
      );

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e, st) {
      AstraLogger.e('Generate prescription draft failed',
          error: e, stackTrace: st);
      _handleError(AstraException('Failed to generate prescription: $e'));
      return null;
    }
  }

  /// Analyze medication safety
  Future<Map<String, dynamic>?> analyzeMedications(
      List<String> medicines) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _repository.analyzeMedicationSafety(medicines);

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e, st) {
      AstraLogger.e('Analyze medications failed', error: e, stackTrace: st);
      _handleError(AstraException('Failed to analyze medications: $e'));
      return null;
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  AstraMessage _parseAssistantResponse(Map<String, dynamic> response) {
    final content = response['response']?.toString() ??
        response['message']?.toString() ??
        response['text']?.toString() ??
        response['answer']?.toString() ??
        '';

    // Try to extract action from response
    AstraNavigationAction? action;
    if (response['action'] != null) {
      action = AstraNavigationAction.fromJson(
        response['action'] as Map<String, dynamic>,
      );
    }

    return AstraMessage.assistant(
      content: content,
      action: action,
      metadata: response,
    );
  }

  void _handleNetworkError(AstraNetworkException e, String originalMessage) {
    _isLoading = false;
    _isStreaming = false;

    if (e.isConnectionError) {
      _errorMessage = 'You are offline. Message has been queued.';
      _messages.add(AstraMessage.system(
        content:
            '📡 Offline: Your message has been saved and will be sent when you\'re back online.',
      ));
    } else {
      _errorMessage = e.message;
      _messages.add(AstraMessage.system(
        content: '⚠️ ${e.message}',
        isError: true,
      ));
    }

    notifyListeners();
  }

  void _handleError(AstraException e) {
    _isLoading = false;
    _isStreaming = false;
    _errorMessage = e.message;

    _messages.add(AstraMessage.system(
      content: '❌ ${e.message}',
      isError: true,
    ));

    notifyListeners();
  }

  double _estimateProgress(String content) {
    // Rough estimate based on typical response length
    const typicalLength = 500;
    if (content.length < typicalLength) {
      return content.length / typicalLength * 0.8;
    }
    return 0.8 + (content.length - typicalLength) / typicalLength * 0.2;
  }

  // ============================================================
  // LAZY LOADING & PAGINATION
  // ============================================================

  static const int _pageSize = 20;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMore => _isLoadingMore;

  /// Load older messages (pagination)
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _currentUserId == null) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final olderMessages = await _repository.getConversationHistory(
        _currentUserId!,
        limit: _pageSize,
        beforeMessageId: _messages.isNotEmpty ? _messages.first.id : null,
      );

      if (olderMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        _messages.insertAll(0, olderMessages);
      }
    } catch (e, st) {
      AstraLogger.e('Failed to load more messages', error: e, stackTrace: st);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Check if should load more (scroll position)
  bool shouldLoadMore(int firstVisibleIndex) {
    return firstVisibleIndex < 3 && _hasMoreMessages && !_isLoadingMore;
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  /// Trim old messages to manage memory (keep last 100)
  void trimMessageHistory({int keepLast = 100}) {
    if (_messages.length > keepLast) {
      final trimmed = _messages.sublist(_messages.length - keepLast);
      _messages.clear();
      _messages.addAll(trimmed);
      notifyListeners();
      AstraLogger.d('Trimmed message history to $keepLast messages');
    }
  }

  /// Preload context for faster responses
  Future<void> preloadContext({
    required String patientId,
    String? recentSymptoms,
  }) async {
    if (!_initialized) return;

    try {
      await _repository.prefetchContext(
        patientId: patientId,
        recentSymptoms: recentSymptoms,
      );
      AstraLogger.d('Context preloaded for patient: $patientId');
    } catch (e, st) {
      AstraLogger.e('Failed to preload context', error: e, stackTrace: st);
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    cancelStream();
    super.dispose();
  }
}

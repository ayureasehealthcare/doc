/// Astra Conversation Models
///
/// Models for managing conversations with Astra Brain.
library;

import 'package:doctro/core/astra/actions/action_models.dart';

/// Message role enumeration
enum MessageRole {
  /// Message sent by the user (doctor)
  user,

  /// Message received from Astra AI
  assistant,

  /// System message (info, errors, etc.)
  system,
}

/// Message status
enum MessageStatus {
  /// Message is being sent/streaming
  sending,

  /// Message sent successfully
  sent,

  /// Message delivery failed
  failed,

  /// Message received/streamed completely
  received,
}

/// Conversation message model
class AstraMessage {
  /// Unique message ID
  final String id;

  /// Message content/text
  final String content;

  /// Message role (user/assistant/system)
  final MessageRole role;

  /// Timestamp when message was created
  final DateTime createdAt;

  /// Message status
  final MessageStatus status;

  /// Associated action if any
  final AstraNavigationAction? action;

  /// Associated metadata
  final Map<String, dynamic>? metadata;

  /// Error message if status is failed
  final String? errorMessage;

  /// Streaming progress (0.0 to 1.0) during streaming
  final double? streamProgress;

  AstraMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.action,
    this.metadata,
    this.errorMessage,
    this.streamProgress,
  });

  /// Create a user message
  factory AstraMessage.user({
    required String content,
    String? id,
    Map<String, dynamic>? metadata,
  }) {
    return AstraMessage(
      id: id ?? _generateId(),
      content: content,
      role: MessageRole.user,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
      metadata: metadata,
    );
  }

  /// Create an assistant message
  factory AstraMessage.assistant({
    required String content,
    String? id,
    AstraNavigationAction? action,
    Map<String, dynamic>? metadata,
  }) {
    return AstraMessage(
      id: id ?? _generateId(),
      content: content,
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
      status: MessageStatus.received,
      action: action,
      metadata: metadata,
    );
  }

  /// Create a system message
  factory AstraMessage.system({
    required String content,
    String? id,
    bool isError = false,
  }) {
    return AstraMessage(
      id: id ?? _generateId(),
      content: content,
      role: MessageRole.system,
      createdAt: DateTime.now(),
      status: isError ? MessageStatus.failed : MessageStatus.received,
      errorMessage: isError ? content : null,
    );
  }

  /// Create a sending message (for streaming)
  factory AstraMessage.sending({
    required String content,
    String? id,
  }) {
    return AstraMessage(
      id: id ?? _generateId(),
      content: content,
      role: MessageRole.user,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  /// Create a streaming assistant message
  factory AstraMessage.streaming({
    required String content,
    String? id,
    double progress = 0.0,
  }) {
    return AstraMessage(
      id: id ?? _generateId(),
      content: content,
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      streamProgress: progress,
    );
  }

  /// Create a failed message
  factory AstraMessage.failed({
    required String content,
    required String errorMessage,
    required MessageRole role,
    String? id,
  }) {
    return AstraMessage(
      id: id ?? _generateId(),
      content: content,
      role: role,
      createdAt: DateTime.now(),
      status: MessageStatus.failed,
      errorMessage: errorMessage,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      if (action != null) 'action': action!.toJson(),
      if (metadata != null) 'metadata': metadata,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (streamProgress != null) 'streamProgress': streamProgress,
    };
  }

  /// Create from JSON
  factory AstraMessage.fromJson(Map<String, dynamic> json) {
    return AstraMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      action: json['action'] != null
          ? AstraNavigationAction.fromJson(
              json['action'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      streamProgress: (json['streamProgress'] as num?)?.toDouble(),
    );
  }

  /// Copy with updated values
  AstraMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? createdAt,
    MessageStatus? status,
    AstraNavigationAction? action,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    double? streamProgress,
  }) {
    return AstraMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      action: action ?? this.action,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
      streamProgress: streamProgress ?? this.streamProgress,
    );
  }

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  @override
  String toString() {
    return 'AstraMessage(id: $id, role: ${role.name}, status: ${status.name}, '
        'content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}

/// Conversation context
class ConversationContext {
  /// Patient ID if applicable
  final String? patientId;

  /// Patient name if applicable
  final String? patientName;

  /// Appointment ID if applicable
  final String? appointmentId;

  /// Prescription ID if applicable
  final String? prescriptionId;

  /// Current screen context
  final String? screenContext;

  /// Doctor ID
  final String? doctorId;

  ConversationContext({
    this.patientId,
    this.patientName,
    this.appointmentId,
    this.prescriptionId,
    this.screenContext,
    this.doctorId,
  });

  /// Convert to metadata map for API
  Map<String, dynamic> toMetadata() {
    return {
      if (patientId != null) 'patient_id': patientId,
      if (patientName != null) 'patient_name': patientName,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (screenContext != null) 'screen_context': screenContext,
      if (doctorId != null) 'doctor_id': doctorId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Copy with updated values
  ConversationContext copyWith({
    String? patientId,
    String? patientName,
    String? appointmentId,
    String? prescriptionId,
    String? screenContext,
    String? doctorId,
  }) {
    return ConversationContext(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      appointmentId: appointmentId ?? this.appointmentId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      screenContext: screenContext ?? this.screenContext,
      doctorId: doctorId ?? this.doctorId,
    );
  }
}

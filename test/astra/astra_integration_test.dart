import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/core/astra/actions/action_models.dart';
import 'package:doctro/core/astra/actions/actions.dart';
import 'package:doctro/core/astra/models/conversation_model.dart';
import 'package:doctro/core/astra/navigation/app_router.dart';
import 'package:doctro/core/astra/utils/astra_config.dart';

/// Integration tests for Astra Core module
/// These tests verify that different components work together correctly.

void main() {
  group('AstraConfig Integration', () {
    test('should provide all necessary configuration', () {
      // Verify all critical endpoints are defined
      expect(AstraConfig.apiBaseUrl.isNotEmpty, true);
      expect(AstraConfig.brainChat.isNotEmpty, true);
      expect(AstraConfig.prescriptionCreate.isNotEmpty, true);
    });
  });

  group('Conversation to Action Integration', () {
    test('should create action from message metadata', () {
      // Simulate extracting action from AI response
      final aiResponse = {
        'response':
            'I found patient John Doe. Would you like to view their details?',
        'action': {
          'type': 'openPatient',
          'params': {'id': '123', 'patient_name': 'John Doe'},
        },
      };

      final action = AstraNavigationAction.fromJson(
          aiResponse['action'] as Map<String, dynamic>);

      expect(action.type, AstraActionType.openPatient);
      expect(action.targetId, '123');
      expect(action.params?['patient_name'], 'John Doe');
    });

    test('should handle multiple actions in response', () {
      final response = {
        'response': 'I found some suggestions for this patient.',
        'actions': [
          {
            'type': 'openPrescription',
            'params': {'id': '456'}
          },
          {
            'type': 'openReminders',
            'params': {'patient_id': '123'}
          },
        ],
      };

      final dispatcher = ActionDispatcher.instance;
      final actions = dispatcher.extractActions(response);

      expect(actions.length, 2);
      expect(actions[0].type, AstraActionType.openPrescription);
      expect(actions[1].type, AstraActionType.openReminders);
    });
  });

  group('Deep Link Parsing', () {
    test('should parse ayureze:// URLs', () {
      final uri = AppRouter.parseDeepLink('ayureze://patient/123');

      expect(uri, isNotNull);
      // First segment is '123' (the path after 'patient/')
      expect(uri!.pathSegments, isNotEmpty);
    });

    test('should parse https://ayureze.in URLs', () {
      final uri =
          AppRouter.parseDeepLink('https://ayureze.in/prescription/456');

      expect(uri, isNotNull);
      expect(uri!.pathSegments, isNotEmpty);
    });

    test('should return null for invalid URLs', () {
      final uri = AppRouter.parseDeepLink('https://other.com/page');

      expect(uri, isNull);
    });

    test('should parse cart URL', () {
      final uri = AppRouter.parseDeepLink('ayureze://cart');

      // Cart URL should be parsed (may have empty path segments)
      expect(uri, isNotNull);
    });
  });

  group('Message Flow', () {
    test('should create complete message flow', () {
      // User sends message
      final userMessage = AstraMessage.user(content: 'Show me patient 123');

      expect(userMessage.role, MessageRole.user);
      expect(userMessage.status, MessageStatus.sent);

      // Assistant responds with action
      final assistantMessage = AstraMessage.assistant(
        content: 'Here is patient John Doe.',
        action: AstraNavigationAction(
          type: AstraActionType.openPatient,
          params: {'id': '123', 'patient_name': 'John Doe'},
        ),
      );

      expect(assistantMessage.role, MessageRole.assistant);
      expect(assistantMessage.action?.type, AstraActionType.openPatient);

      // Convert to JSON for storage/transmission
      final userJson = userMessage.toJson();
      final assistantJson = assistantMessage.toJson();

      expect(userJson['content'], 'Show me patient 123');
      expect(assistantJson['action']['type'], 'openPatient');

      // Restore from JSON
      final restoredUser = AstraMessage.fromJson(userJson);
      final restoredAssistant = AstraMessage.fromJson(assistantJson);

      expect(restoredUser.content, userMessage.content);
      expect(restoredAssistant.action?.type, AstraActionType.openPatient);
    });

    test('should handle streaming message flow', () {
      // Start streaming
      final streamingMsg = AstraMessage.streaming(content: 'Thinking');

      expect(streamingMsg.status, MessageStatus.sending);
      expect(streamingMsg.streamProgress, 0.0);

      // Update with progress
      final updatedMsg = streamingMsg.copyWith(
        content: 'Thinking about patient',
        streamProgress: 0.5,
      );

      expect(updatedMsg.content, 'Thinking about patient');
      expect(updatedMsg.streamProgress, 0.5);

      // Complete streaming
      final completedMsg = updatedMsg.copyWith(
        content: 'Thinking about patient data...',
        streamProgress: 1.0,
        status: MessageStatus.received,
      );

      expect(completedMsg.status, MessageStatus.received);
      expect(completedMsg.streamProgress, 1.0);
    });
  });

  group('Context Management', () {
    test('should maintain context through conversation', () {
      // Start with patient context
      final context = ConversationContext(
        patientId: '123',
        patientName: 'John Doe',
        appointmentId: '456',
        doctorId: 'doc1',
      );

      // Convert to metadata for API
      final metadata = context.toMetadata();

      expect(metadata['patient_id'], '123');
      expect(metadata['patient_name'], 'John Doe');
      expect(metadata['appointment_id'], '456');
      expect(metadata['doctor_id'], 'doc1');
      expect(metadata['timestamp'], isNotNull);

      // Update context
      final updatedContext = context.copyWith(
        prescriptionId: '789',
        screenContext: 'prescription',
      );

      expect(updatedContext.patientId, '123');
      expect(updatedContext.prescriptionId, '789');
      expect(updatedContext.screenContext, 'prescription');
    });
  });

  group('Priority Handling', () {
    test('should handle critical priority actions', () {
      final criticalAction = AstraNavigationAction(
        type: AstraActionType.openPrescription,
        priority: ActionPriority.critical,
        description: 'Urgent prescription needed',
      );

      expect(criticalAction.priority, ActionPriority.critical);
      expect(criticalAction.description, 'Urgent prescription needed');
    });

    test('should sort actions by priority', () {
      final actions = [
        AstraNavigationAction(
          type: AstraActionType.openPatient,
          priority: ActionPriority.normal,
        ),
        AstraNavigationAction(
          type: AstraActionType.openPrescription,
          priority: ActionPriority.high,
        ),
        AstraNavigationAction(
          type: AstraActionType.openNotifications,
          priority: ActionPriority.low,
        ),
      ];

      final dispatcher = ActionDispatcher.instance;
      final sorted = dispatcher.getHighestPriorityAction(actions);

      // High priority should come first
      expect(sorted?.type, AstraActionType.openPrescription);
    });
  });
}

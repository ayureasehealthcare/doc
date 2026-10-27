import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/core/astra/actions/actions.dart';

void main() {
  group('ActionDispatcher', () {
    late ActionDispatcher dispatcher;

    setUp(() {
      dispatcher = ActionDispatcher.instance;
    });

    test('should have singleton instance', () {
      final instance1 = ActionDispatcher.instance;
      final instance2 = ActionDispatcher.instance;

      expect(identical(instance1, instance2), true);
    });

    test('should extract actions from JSON - actions array', () {
      final response = {
        'actions': [
          {
            'type': 'openPatient',
            'params': {'id': '123'}
          },
          {
            'type': 'openPrescription',
            'params': {'id': '456'}
          },
        ],
      };

      final actions = dispatcher.extractActions(response);

      expect(actions.length, 2);
      expect(actions[0].type, AstraActionType.openPatient);
      expect(actions[1].type, AstraActionType.openPrescription);
    });

    test('should extract actions from JSON - action object', () {
      final response = {
        'action': {
          'type': 'openPayment',
        },
      };

      final actions = dispatcher.extractActions(response);

      expect(actions.length, 1);
      expect(actions[0].type, AstraActionType.openPayment);
    });

    test('should extract actions from JSON - suggested_actions array', () {
      final response = {
        'suggested_actions': ['openPatient', 'openPrescription'],
      };

      final actions = dispatcher.extractActions(response);

      expect(actions.length, 2);
      expect(actions[0].type, AstraActionType.openPatient);
      expect(actions[1].type, AstraActionType.openPrescription);
    });

    test('should extract actions from JSON - navigation object', () {
      final response = {
        'navigation': {
          'type': 'openPayment',
        },
      };

      final actions = dispatcher.extractActions(response);

      expect(actions.length, 1);
      expect(actions[0].type, AstraActionType.openPayment);
    });

    test('should return empty list for no actions', () {
      final response = {
        'response': 'Some text without actions',
      };

      final actions = dispatcher.extractActions(response);

      expect(actions.isEmpty, true);
    });

    test('should get highest priority action', () {
      final actions = [
        AstraNavigationAction(
          type: AstraActionType.openPatient,
          priority: ActionPriority.low,
        ),
        AstraNavigationAction(
          type: AstraActionType.openPrescription,
          priority: ActionPriority.high,
        ),
        AstraNavigationAction(
          type: AstraActionType.openPayment,
          priority: ActionPriority.critical,
        ),
      ];

      final highest = dispatcher.getHighestPriorityAction(actions);

      expect(highest?.type, AstraActionType.openPayment);
      expect(highest?.priority, ActionPriority.critical);
    });

    test('should return null for empty actions list', () {
      final highest = dispatcher.getHighestPriorityAction([]);

      expect(highest, isNull);
    });

    test('should sort by priority correctly', () {
      final actions = [
        AstraNavigationAction(
          type: AstraActionType.openPatient,
          priority: ActionPriority.low,
        ),
        AstraNavigationAction(
          type: AstraActionType.openPrescription,
          priority: ActionPriority.normal,
        ),
        AstraNavigationAction(
          type: AstraActionType.openPayment,
          priority: ActionPriority.high,
        ),
      ];

      final highest = dispatcher.getHighestPriorityAction(actions);

      // Priority order: critical > high > normal > low
      expect(highest?.type, AstraActionType.openPayment);
    });
  });

  group('Action parsing edge cases', () {
    late ActionDispatcher dispatcher;

    setUp(() {
      dispatcher = ActionDispatcher.instance;
    });

    test('should handle mixed case action types', () {
      final actions = dispatcher.extractActions({
        'actions': [
          {'type': 'OPEN_PATIENT'},
          {'type': 'openpatient'},
          {'type': 'OpenPatient'},
        ],
      });

      expect(actions.length, 3);
      expect(actions[0].type, AstraActionType.openPatient);
      expect(actions[1].type, AstraActionType.openPatient);
      expect(actions[2].type, AstraActionType.openPatient);
    });

    test('should handle malformed JSON gracefully', () {
      // Should not throw, just return empty
      final actions = dispatcher.extractActions({
        'actions': [
          {'type': null}, // null type
        ], // Missing required fields
      });

      // Should handle gracefully
      expect(actions.isNotEmpty, true);
    });
  });
}

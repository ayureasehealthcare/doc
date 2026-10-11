import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/core/astra/utils/astra_config.dart';

void main() {
  group('AstraConfig', () {
    test('should have correct base URL', () {
      expect(AstraConfig.baseUrl, 'https://astra.ayureze.in/');
    });

    test('should have correct API version', () {
      expect(AstraConfig.apiVersion, 'api/v1');
    });

    test('should build correct API base URL', () {
      expect(AstraConfig.apiBaseUrl, 'https://astra.ayureze.in/api/v1/');
    });

    test('should build correct endpoint URL', () {
      expect(
        AstraConfig.buildUrl('brain/chat'),
        'https://astra.ayureze.in/api/v1/brain/chat',
      );
    });

    test('should build URL with path parameters', () {
      expect(
        AstraConfig.buildUrlWithParams(
          'patients/{id}',
          {'id': '123'},
        ),
        'https://astra.ayureze.in/api/v1/patients/123',
      );
    });

    test('should have correct timeout values', () {
      expect(AstraConfig.connectTimeoutSeconds, 45);
      expect(AstraConfig.receiveTimeoutSeconds, 90);
      expect(AstraConfig.maxRetries, 3);
    });

    test('should have correct message limits', () {
      expect(AstraConfig.maxMessageLength, 4000);
      expect(AstraConfig.maxLocalHistoryMessages, 100);
      expect(AstraConfig.maxOfflineQueueSize, 50);
    });

    test('should have correct deep link scheme', () {
      expect(AstraConfig.deepLinkScheme, 'ayureze');
      expect(AstraConfig.deepLinkUri, 'ayureze://');
    });
  });
}

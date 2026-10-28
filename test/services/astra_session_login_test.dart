import 'package:doctro/services/astra_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a SessionResponse to the login shape sign-in reads', () {
    final login = AstraApiService.sessionToLogin({
      'session_token': 'sess-abc',
      'session_id': 's1',
      'expires_at': '2026-10-29T00:00:00Z',
      'user': {
        'id': 'doc-42',
        'email': 'asha@example.com',
        'name': 'Asha Rao',
        'picture': 'https://example.com/a.png',
      },
    });

    expect(login['success'], isTrue);
    expect(login['token'], 'sess-abc');
    expect(login['data']['id'], 'doc-42');
    expect(login['data']['name'], 'Asha Rao');
    expect(login['data']['email'], 'asha@example.com');
    expect(login['data']['image'], 'https://example.com/a.png');
  });

  test('a body without a session token is not a successful login', () {
    final login = AstraApiService.sessionToLogin({'detail': 'Invalid token'});
    expect(login['success'], isFalse);
    expect(login['data']['id'], '');
  });
}

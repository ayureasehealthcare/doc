import 'package:doctro/core/constants/common_function.dart';
import 'package:doctro/network/server_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _bad(int status, dynamic body) {
  final options = RequestOptions(path: 'setting');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PonnamKarthik/fluttertoast');
  final toasts = <String>[];

  setUp(() {
    toasts.clear();
    CommonFunction.resetToastDedupeForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'showToast') {
        toasts.add((call.arguments as Map)['msg'] as String);
      }
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a 404 from a dead route shows no toast and no Dio text', () {
    // Exactly what astra returns for GET api/v1/setting on every launch.
    final e = ServerError.withError(error: _bad(404, {'detail': 'Not Found'}));

    expect(toasts, isEmpty);
    expect(e.getErrorCode(), 404);
    expect(e.getErrorMessage(), isNot(contains('RequestOptions')));
    expect(e.getErrorMessage(), "This isn't available right now.");
  });

  test('a server error toasts a plain message, never Dio\'s paragraph', () {
    ServerError.withError(error: _bad(500, '<html>Bad gateway</html>'));

    expect(toasts, ['The server had a problem. Please try again shortly.']);
  });

  test('a FastAPI detail message is shown as is', () {
    ServerError.withError(
        error: _bad(400, {'detail': 'Prescription already submitted'}));

    expect(toasts, ['Prescription already submitted']);
  });

  test('non-network errors no longer throw a TypeError', () {
    final e = ServerError.withError(error: Exception('firebase said no'));
    expect(e.getErrorMessage(), 'Something went wrong. Please try again.');
    expect(toasts, isEmpty);
  });
}

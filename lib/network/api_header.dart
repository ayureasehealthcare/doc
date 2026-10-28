import 'package:dio/dio.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/navigator_key.dart';
import 'package:flutter/material.dart';
import 'package:doctro/core/config/env.dart';

import '../utils/logger.dart';

/// Force-navigate to the SignIn route using the app-wide navigator key.
/// Safe to call after `await` (does not rely on a widget BuildContext that
/// may have been disposed while the request was in flight).
void _forceLogoutToSignIn() {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushNamedAndRemoveUntil('SignIn', (route) => false);
}

class RetroApi {
  Future<Dio> dioData(BuildContext context) async {
    final dio = Dio();
    dio.options.headers["Accept"] =
        "application/json"; // config your dio headers globally
    // dio.options.headers["Authorization"] = "Bearer" +
    //     " " +
    //     SharedPreferenceHelper.getString(
    //         Preferences.auth_token); // config your dio headers globally
    dio.options.headers["Content-Type"] = "application/x-www-form-urlencoded";
    dio.options.followRedirects = false;
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);

    final token = SharedPreferenceHelper.getString(Preferences.auth_token);

    final isLoggedIn =
        SharedPreferenceHelper.getBoolean(Preferences.is_logged_in);

    if (token != 'N_A' && token.isNotEmpty) {
      dio.options.headers["Authorization"] = "Bearer $token";
    }
    dio.options.headers["Accept"] = "application/json";

    // Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          final requestOptions = e.requestOptions;

          if (e.response?.statusCode == 401 &&
              isLoggedIn &&
              !requestOptions.path.contains('refresh') &&
              !requestOptions.path.contains('register') &&
              !requestOptions.path.contains('login') &&
              !requestOptions.path.contains('setting')) {
            try {
              final refreshToken =
                  SharedPreferenceHelper.getString(Preferences.refresh_token);

              if (refreshToken == 'N_A' || refreshToken.isEmpty) {
                await SharedPreferenceHelper.clearPref();
                _forceLogoutToSignIn();
                return handler.reject(e);
              }

              final newToken = await refreshFirebaseToken(refreshToken);

              if (newToken != null) {
                // Retry request with new token
                final clonedRequest = await dio.request(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: Options(
                    method: requestOptions.method,
                    headers: {
                      ...requestOptions.headers,
                      'Authorization': 'Bearer $newToken',
                    },
                  ),
                );
                return handler.resolve(clonedRequest);
              } else {
                // Refresh failed, force logout
                await SharedPreferenceHelper.clearPref();
                _forceLogoutToSignIn();
                return handler.reject(e);
              }
            } catch (err) {
              logger.w('Token refresh error: $err');
              await SharedPreferenceHelper.clearPref();
              _forceLogoutToSignIn();
              return handler.reject(e);
            }
          }

          return handler.next(e);
        },
      ),
    );

    // Add Retry Interceptor
    dio.interceptors.add(RetryInterceptor(dio));

    return dio;
  }

  Future<String?> refreshFirebaseToken(String refreshToken) async {
    try {
      final String apiKey = Env.firebaseApiKey;
      if (apiKey.isEmpty) {
        return null;
      }
      final response = await Dio().post(
        'https://securetoken.googleapis.com/v1/token?key=$apiKey',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newIdToken = data['id_token'];
        final newRefreshToken = data['refresh_token'];
        final newExpiresIn = int.parse(data['expires_in']);

        // Save updated tokens
        await SharedPreferenceHelper.setString(
            Preferences.auth_token, newIdToken);
        await SharedPreferenceHelper.setString(
            Preferences.refresh_token, newRefreshToken);
        await SharedPreferenceHelper.setInt(
            Preferences.expiresIn, newExpiresIn);
        await SharedPreferenceHelper.setInt(
            'token_saved_at', DateTime.now().millisecondsSinceEpoch);

        return newIdToken;
      } else {
        return null;
      }
    } catch (e) {
      logger.e('Firebase token refresh failed: $e');
      return null;
    }
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor(this.dio,
      {this.maxRetries = 3, this.retryDelay = const Duration(seconds: 2)});

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) &&
        err.requestOptions.extra['retries'] != maxRetries) {
      final extra = err.requestOptions.extra;
      final retryCount = (extra['retries'] ?? 0) + 1;
      extra['retries'] = retryCount;

      logger.w(
          'Retrying request [${err.requestOptions.path}] - Attempt $retryCount/$maxRetries');

      await Future.delayed(retryDelay);
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(e is DioException ? e : err, handler);
      }
    }
    logger
        .e('API Request Failed [${err.requestOptions.path}] - ${err.message}');
    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

class RetroApi2 {
  Dio dioData2() {
    final dio = Dio();
    dio.options.headers["Accept"] = "application/json";
    dio.options.followRedirects = false;
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    dio.interceptors.add(RetryInterceptor(dio));
    return dio;
  }
}

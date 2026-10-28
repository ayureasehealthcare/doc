import 'package:doctro/core/constants/common_function.dart';
import 'package:dio/dio.dart' hide Headers;

class ServerError implements Exception {
  int? _errorCode;
  String _errorMessage = "";

  ServerError.withError({error}) {
    _handleError(error);
  }

  getErrorCode() {
    return _errorCode;
  }

  getErrorMessage() {
    return _errorMessage;
  }

  void _handleError(DioException error) {
    // A 404 or proxy error can come back as an HTML string, which can't be
    // indexed like JSON.
    final raw = error.response?.data;
    final Map? data = raw is Map ? raw : null;
    final int? status = error.response?.statusCode;
    String message = "";

    if (error.response?.statusCode == 401) {
      message = data?['msg']?.toString() ??
          data?['message']?.toString() ??
          "Unauthorized";
      if (message.toLowerCase().contains("unauthorized")) {
        message = "Session expired. Please log in again.";
      }
    } else if (data?['error'] != null) {
      message = '${data!['error']}';
    } else if (error.type == DioExceptionType.badResponse) {
      if (data?['msg'] != null) {
        message = data!['msg'].toString();
      } else if (data?['message'] != null) {
        message = data!['message'].toString();
      } else if (data?['detail'] is String && status != 404) {
        // FastAPI's error body. Its 404 detail is just "Not Found".
        message = data!['detail'] as String;
      }
    } else if (error.type == DioExceptionType.unknown) {
      message = data?['msg']?.toString() ?? "Unexpected error occurred";
    } else if (error.type == DioExceptionType.cancel) {
      message = 'Request was cancelled';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Connection failed. Please check internet connection';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout';
    } else if (error.type == DioExceptionType.badCertificate) {
      message = data?['msg']?.toString() ?? 'Bad certificate';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Receive timeout in connection';
    } else if (error.type == DioExceptionType.sendTimeout) {
      message = 'Receive timeout in send request';
    } else if (data?['errors'] is Map) {
      final errors = data!['errors'] as Map;
      for (final field in [
        'name',
        'phone',
        'phone_code',
        'password',
        'email',
        'description',
        'old_password',
        'password_confirmation',
      ]) {
        if (errors[field] != null) {
          message = errors[field][0].toString();
          break;
        }
      }
    }

    // Never fall back to Dio's own message: it is a paragraph meant for
    // developers ("This exception was thrown because the response has a
    // status code of 404 and RequestOptions.validateStatus...").
    if (message.isEmpty) message = friendlyMessageFor(status);

    _errorCode = status;
    _errorMessage = message;
    // A 404 here means a route the server doesn't serve (most legacy routes,
    // e.g. the settings call made on every launch). The user can't act on
    // it, so screens show their own error state instead of a toast.
    if (status != 404) CommonFunction.toastMessage(message);
  }

  static String friendlyMessageFor(int? status) {
    if (status == 404) return "This isn't available right now.";
    if (status == 403) return "You don't have access to this.";
    if (status != null && status >= 500) {
      return "The server had a problem. Please try again shortly.";
    }
    return "Something went wrong. Please try again.";
  }
}

import 'package:dio/dio.dart';

class ApiErrorModel implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  const ApiErrorModel({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  factory ApiErrorModel.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final payload = _asStringKeyMap(exception.response?.data);

    final message = _extractMessage(payload) ??
        exception.message ??
        'Unexpected network error. Please try again.';

    final code = payload?['code']?.toString();

    return ApiErrorModel(
      message: message,
      statusCode: statusCode,
      code: code,
      details: payload,
    );
  }

  static String? _extractMessage(Map<String, dynamic>? payload) {
    if (payload == null) return null;

    final direct = payload['message']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final error = payload['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    if (error is Map) {
      final mapped = error.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final nested = mapped['message']?.toString().trim();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '[$statusCode] $message';
  }
}

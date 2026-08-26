import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const String _retryCountKey = '__retry_count__';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetriable(err)) {
      return handler.next(err);
    }

    final requestOptions = err.requestOptions;
    final currentRetries = (requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (currentRetries >= maxRetries) {
      return handler.next(err);
    }

    requestOptions.extra[_retryCountKey] = currentRetries + 1;

    final delay = Duration(
      milliseconds: baseDelay.inMilliseconds * (currentRetries + 1),
    );
    await Future<void>.delayed(delay);

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isRetriable(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return false;
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode ?? 0;
      return statusCode >= 500;
    }

    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }
}

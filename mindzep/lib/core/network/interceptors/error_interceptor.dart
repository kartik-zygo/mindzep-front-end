import 'package:dio/dio.dart';

import '../api_error_model.dart';

class ErrorInterceptor extends Interceptor {
	@override
	void onError(DioException err, ErrorInterceptorHandler handler) {
		final apiError = ApiErrorModel.fromDioException(err);
		handler.next(err.copyWith(error: apiError, message: apiError.message));
	}
}

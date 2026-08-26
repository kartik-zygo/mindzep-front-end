import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import 'api_error_model.dart';
import 'api_response_parser.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'token_storage.dart';

typedef JsonParser<T> = T Function(dynamic json);

class DioClient {
	DioClient._(this._dio);

	final Dio _dio;

	factory DioClient({
		required TokenStorage tokenStorage,
		VoidCallback? onSessionExpired,
	}) {
		final baseOptions = BaseOptions(
			baseUrl: AppConfig.restBaseUrl,
			connectTimeout: const Duration(seconds: 20),
			sendTimeout: const Duration(seconds: 30),
			receiveTimeout: const Duration(seconds: 30),
			headers: const {
				'Content-Type': 'application/json',
				'Accept': 'application/json',
			},
		);

		final dio = Dio(baseOptions);
		final refreshClient = Dio(baseOptions);

		dio.interceptors.add(RetryInterceptor(dio: dio));
		dio.interceptors.add(
			AuthInterceptor(
				refreshClient: refreshClient,
				tokenStorage: tokenStorage,
				onSessionExpired: onSessionExpired,
			),
		);
		if (kDebugMode) {
			// Placed before ErrorInterceptor so raw HTTP status codes and
			// response bodies are visible before any error transformation.
			dio.interceptors.add(
				PrettyDioLogger(
					requestHeader: true,
					requestBody: true,
					responseBody: true,
					responseHeader: false,
					compact: false,
					logPrint: (msg) => debugPrint(msg.toString()),
				),
			);
		}

		dio.interceptors.add(ErrorInterceptor());

		return DioClient._(dio);
	}

	Future<T> get<T>(
		String path, {
		Map<String, dynamic>? queryParameters,
		bool requiresAuth = true,
		bool extractData = true,
		required JsonParser<T> parser,
	}) {
		return request<T>(
			method: 'GET',
			path: path,
			queryParameters: queryParameters,
			requiresAuth: requiresAuth,
			extractData: extractData,
			parser: parser,
		);
	}

	Future<T> post<T>(
		String path, {
		dynamic data,
		Map<String, dynamic>? queryParameters,
		bool requiresAuth = true,
		bool extractData = true,
		required JsonParser<T> parser,
	}) {
		return request<T>(
			method: 'POST',
			path: path,
			data: data,
			queryParameters: queryParameters,
			requiresAuth: requiresAuth,
			extractData: extractData,
			parser: parser,
		);
	}

	Future<T> put<T>(
		String path, {
		dynamic data,
		Map<String, dynamic>? queryParameters,
		bool requiresAuth = true,
		bool extractData = true,
		required JsonParser<T> parser,
	}) {
		return request<T>(
			method: 'PUT',
			path: path,
			data: data,
			queryParameters: queryParameters,
			requiresAuth: requiresAuth,
			extractData: extractData,
			parser: parser,
		);
	}

	Future<T> patch<T>(
		String path, {
		dynamic data,
		Map<String, dynamic>? queryParameters,
		bool requiresAuth = true,
		bool extractData = true,
		required JsonParser<T> parser,
	}) {
		return request<T>(
			method: 'PATCH',
			path: path,
			data: data,
			queryParameters: queryParameters,
			requiresAuth: requiresAuth,
			extractData: extractData,
			parser: parser,
		);
	}

	Future<T> delete<T>(
		String path, {
		dynamic data,
		Map<String, dynamic>? queryParameters,
		bool requiresAuth = true,
		bool extractData = true,
		required JsonParser<T> parser,
	}) {
		return request<T>(
			method: 'DELETE',
			path: path,
			data: data,
			queryParameters: queryParameters,
			requiresAuth: requiresAuth,
			extractData: extractData,
			parser: parser,
		);
	}

	Future<T> request<T>({
		required String method,
		required String path,
		dynamic data,
		Map<String, dynamic>? queryParameters,
		bool requiresAuth = true,
		bool extractData = true,
		Options? options,
		required JsonParser<T> parser,
	}) async {
		debugPrint('[MindZep API] → $method $path');
		try {
			final mergedExtra = <String, dynamic>{
				...?options?.extra,
				'requiresAuth': requiresAuth,
			};

			final mergedOptions = (options ?? Options()).copyWith(
				method: method,
				extra: mergedExtra,
			);

			final response = await _dio.request<dynamic>(
				path,
				data: data,
				queryParameters: queryParameters,
				options: mergedOptions,
			);

			final payload =
					extractData ? ApiResponseParser.extractData(response.data) : response.data;
			return parser(payload);
		} on ApiErrorModel {
			rethrow;
		} on DioException catch (error) {
			debugPrint('[MindZep API] ✗ $method $path → ${error.response?.statusCode ?? error.type}: ${error.message}');
			if (error.error is ApiErrorModel) {
				throw error.error! as ApiErrorModel;
			}
			throw ApiErrorModel.fromDioException(error);
		}
	}
}

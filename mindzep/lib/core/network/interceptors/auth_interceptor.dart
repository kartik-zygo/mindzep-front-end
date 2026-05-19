import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api_endpoints.dart';
import '../api_response_parser.dart';
import '../token_storage.dart';

class AuthInterceptor extends Interceptor {
	AuthInterceptor({
		required Dio refreshClient,
		required TokenStorage tokenStorage,
		this.onSessionExpired,
	})  : _refreshClient = refreshClient,
				_tokenStorage = tokenStorage;

	final Dio _refreshClient;
	final TokenStorage _tokenStorage;
	final VoidCallback? onSessionExpired;

	static const String _retryMarker = '__auth_retry__';
	Completer<bool>? _refreshCompleter;

	@override
	Future<void> onRequest(
		RequestOptions options,
		RequestInterceptorHandler handler,
	) async {
		if (!_requiresAuth(options)) {
			return handler.next(options);
		}

		final accessToken = await _tokenStorage.getAccessToken();
		if (accessToken != null && accessToken.isNotEmpty) {
			options.headers['Authorization'] = 'Bearer $accessToken';
		}

		handler.next(options);
	}

	@override
	Future<void> onError(
		DioException err,
		ErrorInterceptorHandler handler,
	) async {
		if (!_shouldTryRefresh(err)) {
			return handler.next(err);
		}

		final refreshed = await _refreshAccessToken();
		if (!refreshed) {
			await _tokenStorage.clearSession();
			onSessionExpired?.call();
			return handler.next(err);
		}

		try {
			final retriedRequest = _cloneRequest(err.requestOptions);
			retriedRequest.extra[_retryMarker] = true;

			final accessToken = await _tokenStorage.getAccessToken();
			if (accessToken != null && accessToken.isNotEmpty) {
				retriedRequest.headers['Authorization'] = 'Bearer $accessToken';
			}

			final response = await _refreshClient.fetch<dynamic>(retriedRequest);
			return handler.resolve(response);
		} on DioException catch (retryError) {
			return handler.next(retryError);
		}
	}

	bool _requiresAuth(RequestOptions options) {
		final explicit = options.extra['requiresAuth'];
		return explicit != false;
	}

	bool _shouldTryRefresh(DioException err) {
		final statusCode = err.response?.statusCode;
		if (statusCode != 401) return false;

		final request = err.requestOptions;
		if (!_requiresAuth(request)) return false;
		if (request.path.endsWith(ApiEndpoints.refresh)) return false;
		if (request.extra[_retryMarker] == true) return false;

		return true;
	}

	Future<bool> _refreshAccessToken() async {
		if (_refreshCompleter != null) {
			return _refreshCompleter!.future;
		}

		final completer = Completer<bool>();
		_refreshCompleter = completer;

		try {
			final refreshToken = await _tokenStorage.getRefreshToken();
			if (refreshToken == null || refreshToken.isEmpty) {
				completer.complete(false);
				return false;
			}

			final response = await _refreshClient.post<dynamic>(
				ApiEndpoints.refresh,
				data: {'refreshToken': refreshToken},
				options: Options(extra: {'requiresAuth': false}),
			);

			final data = ApiResponseParser.extractData(response.data);
			final map = _asStringKeyMap(data);
			final newAccessToken = map['accessToken']?.toString() ?? '';
			final newRefreshToken =
					map['refreshToken']?.toString() ?? refreshToken;

			if (newAccessToken.isEmpty) {
				completer.complete(false);
				return false;
			}

			await _tokenStorage.saveTokens(
				accessToken: newAccessToken,
				refreshToken: newRefreshToken,
			);

			completer.complete(true);
			return true;
		} catch (_) {
			completer.complete(false);
			return false;
		} finally {
			_refreshCompleter = null;
		}
	}

	RequestOptions _cloneRequest(RequestOptions request) {
		return request.copyWith(
			data: request.data,
			queryParameters: Map<String, dynamic>.from(request.queryParameters),
			headers: Map<String, dynamic>.from(request.headers),
			extra: Map<String, dynamic>.from(request.extra),
		);
	}

	Map<String, dynamic> _asStringKeyMap(dynamic value) {
		if (value is Map<String, dynamic>) {
			return value;
		}
		if (value is Map) {
			return value.map((key, val) => MapEntry(key.toString(), val));
		}
		return <String, dynamic>{};
	}
}

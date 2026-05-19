import 'pagination.dart';

class ApiResponseParser {
  ApiResponseParser._();

  static dynamic extractData(dynamic payload) {
    final map = _asStringKeyMap(payload);
    if (map == null) {
      return payload;
    }

    if (map.containsKey('data')) {
      return map['data'];
    }
    if (map.containsKey('result')) {
      return map['result'];
    }
    return map;
  }

  static String extractMessage(dynamic payload) {
    final map = _asStringKeyMap(payload);
    if (map == null) {
      return 'Request completed successfully.';
    }

    final message = map['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
    return 'Request completed successfully.';
  }

  static PaginationMeta? extractPagination(dynamic payload) {
    final map = _asStringKeyMap(payload);
    if (map == null) {
      return null;
    }

    final paginationMap = _asStringKeyMap(map['pagination']) ??
        _asStringKeyMap(map['meta']) ??
        _asStringKeyMap(map['page']);

    if (paginationMap == null) {
      return null;
    }

    return PaginationMeta.fromJson(paginationMap);
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }
}

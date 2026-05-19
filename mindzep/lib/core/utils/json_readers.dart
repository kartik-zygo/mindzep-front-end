class JsonReaders {
  JsonReaders._();

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asMapList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => asMap(entry))
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static dynamic readAny(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }
    return null;
  }

  static String readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    final value = readAny(json, keys);
    if (value == null) return fallback;
    return value.toString();
  }

  static int readInt(
    Map<String, dynamic> json,
    List<String> keys, {
    int fallback = 0,
  }) {
    final value = readAny(json, keys);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double readDouble(
    Map<String, dynamic> json,
    List<String> keys, {
    double fallback = 0,
  }) {
    final value = readAny(json, keys);
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool readBool(
    Map<String, dynamic> json,
    List<String> keys, {
    bool fallback = false,
  }) {
    final value = readAny(json, keys);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is num) return value != 0;
    return fallback;
  }

  static DateTime readDateTime(
    Map<String, dynamic> json,
    List<String> keys, {
    DateTime? fallback,
  }) {
    final value = readAny(json, keys);
    if (value is DateTime) return value.isUtc ? value.toLocal() : value;
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }

  static List<String> readStringList(Map<String, dynamic> json, List<String> keys) {
    final value = readAny(json, keys);
    if (value is List) {
      return value.map((entry) => entry.toString()).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }
}

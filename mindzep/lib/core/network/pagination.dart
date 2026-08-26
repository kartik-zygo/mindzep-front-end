class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final page = _readInt(json, ['page', 'currentPage']) ?? 1;
    final limit = _readInt(json, ['limit', 'perPage']) ?? 10;
    final total = _readInt(json, ['total', 'count']) ?? 0;
    final totalPages = _readInt(json, ['totalPages', 'pages']) ??
        (limit > 0 ? (total / limit).ceil() : 0);

    return PaginationMeta(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: _readBool(json, ['hasNext']) ?? page < totalPages,
      hasPrevious: _readBool(json, ['hasPrevious', 'hasPrev']) ?? page > 1,
    );
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is num) return value.toInt();
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return null;
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta? pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });
}

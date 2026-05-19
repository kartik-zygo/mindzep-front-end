import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/psychologist_models.dart';

class PsychologistRepository {
  PsychologistRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<PaginatedResponse<PsychologistModel>> listPsychologists({
    int page = 1,
    int limit = 10,
    String? search,
    List<String>? specializations,
  }) {
    return _dioClient.get<PaginatedResponse<PsychologistModel>>(
      ApiEndpoints.psychologists,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search,
        if (specializations != null && specializations.isNotEmpty)
          'specializations': specializations.join(','),
      },
      extractData: false,
      parser: (json) {
        final payload = JsonReaders.asMap(json);
        final data = ApiResponseParser.extractData(payload);
        final dataMap = JsonReaders.asMap(data);
        final listSource = data is List
            ? data
            : JsonReaders.readAny(
                dataMap,
                const ['psychologists', 'items', 'results', 'data'],
              );

        final items = JsonReaders.asMapList(listSource)
            .map(PsychologistModel.fromJson)
            .toList();

        return PaginatedResponse<PsychologistModel>(
          items: items,
          pagination: ApiResponseParser.extractPagination(payload),
        );
      },
    );
  }

  Future<PsychologistModel> getPsychologistById(String psychologistId) {
    return _dioClient.get<PsychologistModel>(
      ApiEndpoints.psychologistById(psychologistId),
      parser: (json) => PsychologistModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<List<PsychologistReviewModel>> getPsychologistReviews(
    String psychologistId,
  ) {
    return _dioClient.get<List<PsychologistReviewModel>>(
      ApiEndpoints.psychologistReviews(psychologistId),
      parser: (json) {
        return JsonReaders.asMapList(json)
            .map(PsychologistReviewModel.fromJson)
            .toList();
      },
    );
  }

  Future<List<PsychologistBlogPreviewModel>> getPsychologistBlogs(
    String psychologistId,
  ) {
    return _dioClient.get<List<PsychologistBlogPreviewModel>>(
      ApiEndpoints.psychologistBlogs(psychologistId),
      parser: (json) {
        return JsonReaders.asMapList(json)
            .map(PsychologistBlogPreviewModel.fromJson)
            .toList();
      },
    );
  }

  Future<PsychologistModel> updateMyProfile(
    PsychologistUpdateRequest request,
  ) {
    return _dioClient.put<PsychologistModel>(
      ApiEndpoints.psychologistMe,
      data: request.toJson(),
      parser: (json) => PsychologistModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<PsychologistModel> getMyProfile() {
    return _dioClient.get<PsychologistModel>(
      ApiEndpoints.psychologistMe,
      parser: (json) => PsychologistModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<void> updateAvailability(AvailabilityUpdateRequest request) {
    return _dioClient.put<void>(
      ApiEndpoints.psychologistAvailability,
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<PsychologistDocumentModel> uploadMyDocument({
    required String filePath,
    String? documentType,
  }) async {
    final fileName = _extractFilename(filePath);
    final formData = FormData.fromMap({
      if (documentType != null && documentType.trim().isNotEmpty)
        'documentType': documentType,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return _dioClient.post<PsychologistDocumentModel>(
      ApiEndpoints.psychologistDocuments,
      data: formData,
      parser: (json) =>
          PsychologistDocumentModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<List<PsychologistDocumentModel>> listMyDocuments() {
    return _dioClient.get<List<PsychologistDocumentModel>>(
      ApiEndpoints.psychologistDocuments,
      parser: (json) => JsonReaders.asMapList(json)
          .map(PsychologistDocumentModel.fromJson)
          .toList(),
    );
  }

  Future<List<SlotModel>> getPublicSlotsByPsychologist(
    String psychologistId, {
    String? date,
  }) {
    return _dioClient.get<List<SlotModel>>(
      ApiEndpoints.slotsByPsychologist(psychologistId),
      queryParameters: {
        if (date != null && date.trim().isNotEmpty) 'date': date,
      },
      parser: (json) {
        // Backend returns data as { "slots": [...] } — unwrap the list
        final map = JsonReaders.asMap(json);
        final listSource =
            JsonReaders.readAny(map, ['slots', 'items', 'data']) ?? json;
        return JsonReaders.asMapList(listSource)
            .map(SlotModel.fromJson)
            .toList();
      },
    );
  }

  Future<PaginatedResponse<SlotModel>> getMySlots({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<PaginatedResponse<SlotModel>>(
      ApiEndpoints.slotsMe,
      queryParameters: {'page': page, 'limit': limit},
      extractData: false,
      parser: (json) {
        final payload = JsonReaders.asMap(json);
        final data = ApiResponseParser.extractData(payload);

        return PaginatedResponse<SlotModel>(
          items: JsonReaders.asMapList(data).map(SlotModel.fromJson).toList(),
          pagination: ApiResponseParser.extractPagination(payload),
        );
      },
    );
  }

  Future<SlotModel> createSlot(SlotCreateRequest request) {
    return _dioClient.post<SlotModel>(
      ApiEndpoints.slotsMe,
      data: request.toJson(),
      parser: (json) => SlotModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<void> bulkSlotAction(SlotBulkActionRequest request) {
    return _dioClient.patch<void>(
      ApiEndpoints.slotsBulk,
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<SlotModel> updateSlot(String slotId, SlotUpdateRequest request) {
    return _dioClient.put<SlotModel>(
      ApiEndpoints.slotById(slotId),
      data: request.toJson(),
      parser: (json) => SlotModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<void> deleteSlot(String slotId) {
    return _dioClient.delete<void>(
      ApiEndpoints.slotById(slotId),
      parser: (_) => null,
    );
  }

  String _extractFilename(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? 'upload_file' : parts.last;
  }
}

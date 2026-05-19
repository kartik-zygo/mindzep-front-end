import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/upload_models.dart';

class UploadRepository {
  UploadRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<UploadResultModel> uploadAvatar(String filePath) {
    return _uploadSingleFile(
      endpoint: ApiEndpoints.uploadAvatar,
      filePath: filePath,
    );
  }

  Future<UploadResultModel> uploadDocument(String filePath) {
    return _uploadSingleFile(
      endpoint: ApiEndpoints.uploadDocument,
      filePath: filePath,
    );
  }

  Future<UploadResultModel> uploadBlogCover(String filePath) {
    return _uploadSingleFile(
      endpoint: ApiEndpoints.uploadBlogCover,
      filePath: filePath,
    );
  }

  Future<UploadResultModel> _uploadSingleFile({
    required String endpoint,
    required String filePath,
  }) async {
    final fileName = _extractFilename(filePath);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return _dioClient.post<UploadResultModel>(
      endpoint,
      data: formData,
      parser: (json) => UploadResultModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  String _extractFilename(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? 'upload_file' : parts.last;
  }
}

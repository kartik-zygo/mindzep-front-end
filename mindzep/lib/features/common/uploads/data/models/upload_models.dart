import '../../../../../core/utils/json_readers.dart';

class UploadResultModel {
  final String url;
  final String? fileName;

  const UploadResultModel({required this.url, required this.fileName});

  factory UploadResultModel.fromJson(Map<String, dynamic> json) {
    final fileName = JsonReaders.readString(json, ['fileName', 'name']).trim();

    return UploadResultModel(
      url: JsonReaders.readString(json, ['url', 'fileUrl', 'location']),
      fileName: fileName.isEmpty ? null : fileName,
    );
  }
}

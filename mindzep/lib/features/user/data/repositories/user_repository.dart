import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/user_models.dart';

class UserRepository {
  UserRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<UserProfileModel> getMe() {
    return _dioClient.get<UserProfileModel>(
      ApiEndpoints.me,
      parser: (json) {
        final map = JsonReaders.asMap(json);
        final user = map.containsKey('user') ? JsonReaders.asMap(map['user']) : map;
        return UserProfileModel.fromJson(user);
      },
    );
  }

  Future<UserProfileModel> updateMe(UserUpdateRequest request) {
    return _dioClient.put<UserProfileModel>(
      ApiEndpoints.me,
      data: request.toJson(),
      parser: (json) {
        final map = JsonReaders.asMap(json);
        final user = map.containsKey('user') ? JsonReaders.asMap(map['user']) : map;
        return UserProfileModel.fromJson(user);
      },
    );
  }

  Future<ExtendedProfileModel> getMyProfile() {
    return _dioClient.get<ExtendedProfileModel>(
      ApiEndpoints.meProfile,
      parser: (json) =>
          ExtendedProfileModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<ExtendedProfileModel> updateMyProfile(
    ExtendedProfileUpdateRequest request,
  ) {
    return _dioClient.put<ExtendedProfileModel>(
      ApiEndpoints.meProfile,
      data: request.toJson(),
      parser: (json) =>
          ExtendedProfileModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<WalletSummaryModel> getMyWallet() {
    return _dioClient.get<WalletSummaryModel>(
      ApiEndpoints.meWallet,
      parser: (json) => WalletSummaryModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<MoodLogModel> createMood(MoodCreateRequest request) {
    return _dioClient.post<MoodLogModel>(
      ApiEndpoints.meMoods,
      data: request.toJson(),
      parser: (json) => MoodLogModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<List<MoodLogModel>> listMoods() {
    return _dioClient.get<List<MoodLogModel>>(
      ApiEndpoints.meMoods,
      parser: (json) {
        final list = JsonReaders.asMapList(json);
        return list.map(MoodLogModel.fromJson).toList();
      },
    );
  }

  Future<PaginatedResponse<UserNotificationModel>> listMyNotifications({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<PaginatedResponse<UserNotificationModel>>(
      ApiEndpoints.meNotifications,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      extractData: false,
      parser: (json) {
        final payload = JsonReaders.asMap(json);
        final data = ApiResponseParser.extractData(payload);
        final items = JsonReaders.asMapList(data)
            .map(UserNotificationModel.fromJson)
            .toList();
        final pagination = ApiResponseParser.extractPagination(payload);

        return PaginatedResponse<UserNotificationModel>(
          items: items,
          pagination: pagination,
        );
      },
    );
  }

  Future<void> markAllMyNotificationsRead() {
    return _dioClient.put<void>(
      ApiEndpoints.meNotificationsReadAll,
      parser: (_) => null,
    );
  }

  Future<void> markMyNotificationRead(String notificationId) {
    return _dioClient.put<void>(
      ApiEndpoints.meNotificationRead(notificationId),
      parser: (_) => null,
    );
  }
}

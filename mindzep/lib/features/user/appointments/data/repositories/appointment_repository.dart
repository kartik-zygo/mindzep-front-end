import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_response_parser.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/network/pagination.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/appointment_models.dart';

class AppointmentRepository {
  AppointmentRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<AppointmentModel> bookAppointment(BookAppointmentRequest request) {
    return _dioClient.post<AppointmentModel>(
      ApiEndpoints.appointments,
      data: request.toJson(),
      parser: (json) {
        final map = JsonReaders.asMap(json);
        // Backend returns { "appointment": { ... } } — unwrap if present
        final apptMap = JsonReaders.readAny(map, ['appointment']) != null
            ? JsonReaders.asMap(map['appointment'])
            : map;
        return AppointmentModel.fromJson(apptMap);
      },
    );
  }

  Future<PaginatedResponse<AppointmentModel>> listAppointments({
    String? status,
    int page = 1,
    int limit = 10,
  }) {
    return _dioClient.get<PaginatedResponse<AppointmentModel>>(
      ApiEndpoints.appointments,
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      extractData: false,
      parser: (json) {
        final payload = JsonReaders.asMap(json);
        final data = ApiResponseParser.extractData(payload);

        return PaginatedResponse<AppointmentModel>(
          items: JsonReaders.asMapList(data)
              .map(AppointmentModel.fromJson)
              .toList(),
          pagination: ApiResponseParser.extractPagination(payload),
        );
      },
    );
  }

  Future<AppointmentModel> getAppointmentById(String appointmentId) {
    return _dioClient.get<AppointmentModel>(
      ApiEndpoints.appointmentById(appointmentId),
      parser: (json) => AppointmentModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<void> cancelAppointment(
    String appointmentId,
    CancelAppointmentRequest request,
  ) {
    return _dioClient.delete<void>(
      ApiEndpoints.appointmentById(appointmentId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> addPsychologistNotes(
    String appointmentId,
    PsychologistNotesRequest request,
  ) {
    return _dioClient.put<void>(
      ApiEndpoints.appointmentPsychologistNotes(appointmentId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> rateAppointment(
    String appointmentId,
    RateAppointmentRequest request,
  ) {
    return _dioClient.post<void>(
      ApiEndpoints.appointmentRate(appointmentId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }
}

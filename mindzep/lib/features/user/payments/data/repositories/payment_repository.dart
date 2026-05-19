import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/payment_models.dart';

class PaymentRepository {
  PaymentRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<CashfreeOrderModel> createOrder(CreateOrderRequest request) {
    return _dioClient.post<CashfreeOrderModel>(
      ApiEndpoints.paymentsCreateOrder,
      data: request.toJson(),
      parser: (json) => CashfreeOrderModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<void> verifyPayment(VerifyPaymentRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.paymentsVerify,
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<List<PaymentRecordModel>> listPayments() {
    return _dioClient.get<List<PaymentRecordModel>>(
      ApiEndpoints.payments,
      parser: (json) =>
          JsonReaders.asMapList(json).map(PaymentRecordModel.fromJson).toList(),
    );
  }

  Future<void> refundPayment(RefundPaymentRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.paymentsRefund,
      data: request.toJson(),
      parser: (_) => null,
    );
  }
}

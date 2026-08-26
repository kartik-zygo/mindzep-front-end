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

  /// Pays for an appointment directly from the user's wallet balance.
  /// The backend deducts [request.amount], marks the appointment paid, and
  /// returns a status — no Cashfree gateway is involved.
  Future<PaymentVerifyResult> payFromWallet(WalletPaymentRequest request) {
    return _dioClient.post<PaymentVerifyResult>(
      ApiEndpoints.paymentsWalletPay,
      data: request.toJson(),
      parser: (json) => PaymentVerifyResult.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<PaymentVerifyResult> verifyPayment(VerifyPaymentRequest request) {
    return _dioClient.post<PaymentVerifyResult>(
      ApiEndpoints.paymentsVerify,
      data: request.toJson(),
      parser: (json) => PaymentVerifyResult.fromJson(JsonReaders.asMap(json)),
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

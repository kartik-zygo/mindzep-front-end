import '../models/payment_models.dart';

class CashfreePaymentService {
  Future<CashfreeCheckoutResult> startCheckout({
    required CashfreeOrderModel order,
  }) async {
    return CashfreeCheckoutResult(
      status: 'FAILED',
      message: 'Payment is temporarily disabled in this build.',
      raw: const <String, dynamic>{'disabled': true, 'provider': 'cashfree'},
    );
  }
}

import '../../../../../core/utils/json_readers.dart';

class CreateOrderRequest {
  final String type;
  final double amount;
  final String? appointmentId;

  const CreateOrderRequest({
    required this.type,
    required this.amount,
    this.appointmentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'order_amount': amount,
      if (appointmentId != null) 'appointmentId': appointmentId,
    };
  }
}

/// Request to pay for an appointment straight from the wallet balance.
/// The backend response is parsed with [PaymentVerifyResult] (a
/// `paid`/`failed` status).
class WalletPaymentRequest {
  final String type;
  final double amount;
  final String? appointmentId;

  const WalletPaymentRequest({
    required this.type,
    required this.amount,
    this.appointmentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      if (appointmentId != null) 'appointmentId': appointmentId,
    };
  }
}

/// Response of `POST /payments/create-order`.
///
/// The backend settles the order itself while payments are switched off
/// (`PAYMENTS_ENABLED=false`): it answers `status: "paid"`,
/// `gateway: "none"` and `requiresGatewayCheckout: false`, and both
/// [cfOrderId] and [paymentSessionId] come back null.
///
/// [requiresGatewayCheckout] is the branch to read. The defaults below are
/// deliberately conservative so an older server that omits the new fields is
/// reported as needing a checkout this build cannot open, rather than being
/// mistaken for a settled order.
class PaymentOrderModel {
  final String orderId;
  final String? cfOrderId;
  final String? paymentSessionId;

  /// 'none' while payments are off, 'cashfree' when they are re-enabled.
  final String gateway;

  /// 'paid' once settled, 'created' when a checkout is still owed.
  final String status;

  final bool requiresGatewayCheckout;
  final double amount;
  final String currency;
  final String? paymentId;

  const PaymentOrderModel({
    required this.orderId,
    required this.cfOrderId,
    required this.paymentSessionId,
    required this.gateway,
    required this.status,
    required this.requiresGatewayCheckout,
    required this.amount,
    required this.currency,
    required this.paymentId,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    String? optional(List<String> keys) {
      final value = JsonReaders.readString(json, keys).trim();
      return value.isEmpty ? null : value;
    }

    return PaymentOrderModel(
      orderId: JsonReaders.readString(json, ['cashfreeOrderId', 'orderId']),
      cfOrderId: optional(['cfOrderId']),
      paymentSessionId: optional(['paymentSessionId']),
      gateway: JsonReaders.readString(json, ['gateway'], fallback: 'cashfree'),
      status: JsonReaders.readString(json, ['status'], fallback: 'created')
          .trim()
          .toLowerCase(),
      requiresGatewayCheckout: JsonReaders.readBool(
        json,
        ['requiresGatewayCheckout'],
        fallback: true,
      ),
      amount: JsonReaders.readDouble(json, ['amount', 'orderAmount']),
      currency: JsonReaders.readString(
        json,
        ['currency', 'orderCurrency'],
        fallback: 'INR',
      ),
      paymentId: optional(['paymentId']),
    );
  }

  static const _paidStatuses = {'paid', 'success', 'completed', 'captured'};

  /// The server already took the money (or waived it) — nothing left to do.
  bool get isSettled =>
      !requiresGatewayCheckout && _paidStatuses.contains(status);
}

/// Typed result of a settlement call such as `POST /payments/wallet-pay`.
class PaymentVerifyResult {
  final String status;
  final String message;
  final Map<String, dynamic> raw;

  const PaymentVerifyResult({
    required this.status,
    required this.message,
    required this.raw,
  });

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> json) {
    final payment = JsonReaders.asMap(
      JsonReaders.readAny(json, ['payment', 'order']),
    );
    final status = JsonReaders.readString(json, ['status', 'paymentStatus'])
            .trim()
            .isNotEmpty
        ? JsonReaders.readString(json, ['status', 'paymentStatus'])
        : JsonReaders.readString(payment, ['status', 'paymentStatus']);

    return PaymentVerifyResult(
      status: status.trim().toLowerCase(),
      message: JsonReaders.readString(json, ['message']),
      raw: json,
    );
  }

  static const _paidStatuses = {'paid', 'success', 'completed', 'captured'};
  static const _pendingStatuses = {
    'pending',
    'created',
    'not_paid',
    'active',
    'processing',
  };

  /// Backend confirmed the money. An empty status on a 2xx response is also
  /// treated as paid (legacy responses carry no status field).
  bool get isPaid => status.isEmpty || _paidStatuses.contains(status);

  /// Not settled yet — worth polling before declaring failure.
  bool get isPending => _pendingStatuses.contains(status);
}

class PaymentRecordModel {
  final String id;
  final String status;
  final double amount;
  final String? type;
  final DateTime createdAt;

  const PaymentRecordModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    final type = JsonReaders.readString(json, ['type']).trim();

    return PaymentRecordModel(
      id: JsonReaders.readString(json, ['id', '_id', 'paymentId']),
      status: JsonReaders.readString(json, ['status'], fallback: 'pending'),
      amount: JsonReaders.readDouble(json, ['amount']),
      type: type.isEmpty ? null : type,
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class RefundPaymentRequest {
  final String paymentId;
  final String reason;

  const RefundPaymentRequest({
    required this.paymentId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'reason': reason,
    };
  }
}

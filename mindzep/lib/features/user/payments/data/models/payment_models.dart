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

class CashfreeOrderModel {
  final String orderId;
  final String paymentSessionId;
  final double orderAmount;
  final String orderCurrency;
  final String? customerEmail;
  final String? customerPhone;
  final String? appId;

  const CashfreeOrderModel({
    required this.orderId,
    required this.paymentSessionId,
    required this.orderAmount,
    required this.orderCurrency,
    required this.customerEmail,
    required this.customerPhone,
    required this.appId,
  });

  factory CashfreeOrderModel.fromJson(Map<String, dynamic> json) {
    return CashfreeOrderModel(
      orderId: JsonReaders.readString(
        json,
        ['orderId', 'cashfreeOrderId', 'cfOrderId'],
      ),
      paymentSessionId: JsonReaders.readString(
        json,
        ['paymentSessionId', 'tokenData', 'cfPaymentSessionId'],
      ),
      orderAmount: JsonReaders.readDouble(
        json,
        ['orderAmount', 'amount'],
      ),
      orderCurrency: JsonReaders.readString(
        json,
        ['orderCurrency', 'currency'],
        fallback: 'INR',
      ),
      customerEmail: JsonReaders.readString(
        json,
        ['customerEmail', 'email'],
      ).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['customerEmail', 'email']),
      customerPhone: JsonReaders.readString(
        json,
        ['customerPhone', 'phone'],
      ).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['customerPhone', 'phone']),
      appId: JsonReaders.readString(json, ['appId']).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['appId']),
    );
  }
}

class VerifyPaymentRequest {
  final String cashfreeOrderId;
  final String? cfPaymentId;

  const VerifyPaymentRequest({
    required this.cashfreeOrderId,
    this.cfPaymentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'cashfreeOrderId': cashfreeOrderId,
      if (cfPaymentId != null && cfPaymentId!.isNotEmpty)
        'cfPaymentId': cfPaymentId,
    };
  }
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

class CashfreeCheckoutResult {
  final String status;
  final String message;
  final Map<String, dynamic> raw;

  const CashfreeCheckoutResult({
    required this.status,
    required this.message,
    required this.raw,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
}

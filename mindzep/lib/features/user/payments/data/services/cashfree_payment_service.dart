import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import '../../../../../core/config/app_config.dart';

class CashfreePaymentService {
  final CFPaymentGatewayService _gateway = CFPaymentGatewayService();

  CFEnvironment get _environment => AppConfig.isPaymentProduction
      ? CFEnvironment.PRODUCTION
      : CFEnvironment.SANDBOX;

  /// Registers success and error callbacks that receive payment results.
  /// Call this in [State.initState] before calling [launchDropCheckout].
  void setCallbacks({
    required void Function(String orderId) onSuccess,
    required void Function(CFErrorResponse error, String orderId) onError,
  }) {
    _gateway.setCallback(onSuccess, onError);
  }

  /// Launches the Cashfree drop-in checkout sheet.
  ///
  /// [doPayment] is synchronous — the sheet opens immediately and this method
  /// returns right away. Payment results arrive via the callbacks registered
  /// in [setCallbacks]. Throws [CFException] if the session/theme cannot be
  /// built (e.g. empty orderId or paymentSessionId).
  void launchDropCheckout({
    required String paymentSessionId,
    required String cashfreeOrderId,
  }) {
    final session = CFSessionBuilder()
        .setEnvironment(_environment)
        .setOrderId(cashfreeOrderId)
        .setPaymentSessionId(paymentSessionId)
        .build();

    final theme = CFThemeBuilder()
        .setNavigationBarBackgroundColorColor('#6C63FF')
        .setNavigationBarTextColor('#FFFFFF')
        .setButtonBackgroundColor('#6C63FF')
        .setButtonTextColor('#FFFFFF')
        .setPrimaryTextColor('#212121')
        .setSecondaryTextColor('#757575')
        .build();

    final paymentComponent = CFPaymentComponentBuilder()
        .setComponents([
          CFPaymentModes.CARD,
          CFPaymentModes.UPI,
          CFPaymentModes.NETBANKING,
          CFPaymentModes.WALLET,
        ])
        .build();

    final checkout = CFDropCheckoutPaymentBuilder()
        .setSession(session)
        .setPaymentComponent(paymentComponent)
        .setTheme(theme)
        .build();

    _gateway.doPayment(checkout);
  }
}

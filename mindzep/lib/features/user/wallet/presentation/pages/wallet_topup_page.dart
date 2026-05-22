import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../../payments/data/repositories/payment_repository.dart';
import '../../../payments/data/services/cashfree_payment_service.dart';
import '../../../../../injection/injection_container.dart';

class WalletTopUpPage extends StatefulWidget {
  const WalletTopUpPage({super.key});

  @override
  State<WalletTopUpPage> createState() => _WalletTopUpPageState();
}

class _WalletTopUpPageState extends State<WalletTopUpPage> {
  late final PaymentRepository _paymentRepository;
  late final CashfreePaymentService _cashfreeService;

  bool _isProcessing = false;
  String _statusMessage = '';
  double _selectedAmount = 500;

  static const _presets = [200.0, 500.0, 1000.0, 2000.0];

  @override
  void initState() {
    super.initState();
    _paymentRepository = sl<PaymentRepository>();
    _cashfreeService = sl<CashfreePaymentService>();

    _cashfreeService.setCallbacks(
      onSuccess: _onPaymentVerified,
      onError: _onPaymentError,
    );
  }

  // ── Cashfree callback: payment confirmed by SDK ──────────────────────────
  void _onPaymentVerified(String orderId) {
    _verifyWithBackend(orderId);
  }

  // ── Cashfree callback: payment failed / cancelled ────────────────────────
  void _onPaymentError(CFErrorResponse errorResponse, String orderId) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage = '';
    });
    AppSnackbar.show(
      context,
      message: errorResponse.getMessage() ?? 'Payment failed. Please try again.',
      type: SnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Money to Wallet'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              children: [
                _buildAmountCard(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildPresets(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildInfoNote(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        children: [
          Text(
            'Amount to Add',
            style: AppTextStyles.subheadline.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            '₹${_selectedAmount.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'Wallet balance will be credited instantly after payment',
            style: AppTextStyles.caption2.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Amount',
          style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.paddingS,
          crossAxisSpacing: AppDimensions.paddingS,
          childAspectRatio: 2.8,
          children: _presets.map((amount) {
            final selected = _selectedAmount == amount;
            return GestureDetector(
              onTap: () => setState(() => _selectedAmount = amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '₹${amount.toInt()}',
                  style: AppTextStyles.subheadline.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              'Wallet balance is used automatically during therapy calls. '
              'Any unused balance can be used for future sessions.',
              style: AppTextStyles.caption1.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          0,
          AppDimensions.paddingM,
          AppDimensions.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary),
                ),
              ),
            AppButton(
              label: 'Add ₹${_selectedAmount.toInt()} to Wallet',
              isLoading: _isProcessing,
              onPressed: _startTopUp,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            // ── Temporary dev bypass ─────────────────────────────────────────
            // Remove this button before production release.
            TextButton(
              onPressed: _isProcessing ? null : _bypassTopUp,
              child: Text(
                '[Dev] Skip Payment Gateway',
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textTertiary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Real Cashfree top-up flow ──────────────────────────────────────────────

  Future<void> _startTopUp() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating payment order...';
    });

    try {
      final orderData = await _paymentRepository.createOrder(
        CreateOrderRequest(
          type: 'wallet_topup',
          amount: _selectedAmount,
        ),
      );

      setState(() => _statusMessage = 'Opening payment gateway...');

      _cashfreeService.launchDropCheckout(
        paymentSessionId: orderData.paymentSessionId,
        cashfreeOrderId: orderData.orderId,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    } on CFException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      AppSnackbar.show(context, message: e.message, type: SnackbarType.error);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      final message = error is ApiErrorModel
          ? error.message
          : 'Failed to create order. Please retry.';
      AppSnackbar.show(context, message: message, type: SnackbarType.error);
    }
  }

  // ── Backend verification after SDK success ─────────────────────────────────

  Future<void> _verifyWithBackend(String cashfreeOrderId) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying payment...';
    });

    try {
      await _paymentRepository.verifyPayment(
        VerifyPaymentRequest(cashfreeOrderId: cashfreeOrderId),
      );

      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: '₹${_selectedAmount.toInt()} added to your wallet!',
        type: SnackbarType.success,
      );
      // Pop with true so the wallet page knows to refresh
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      AppSnackbar.show(
        context,
        message:
            'Payment received but wallet update is delayed. '
            'Balance will reflect shortly.',
        type: SnackbarType.warning,
      );
    }
  }

  // ── Dev bypass: simulate top-up without actual payment ────────────────────

  Future<void> _bypassTopUp() async {
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: '[Dev] Top-up bypassed — ₹${_selectedAmount.toInt()} not actually added.',
      type: SnackbarType.info,
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../appointments/data/models/appointment_models.dart';
import '../../../appointments/data/repositories/appointment_repository.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../../payments/data/repositories/payment_repository.dart';
import '../../../payments/data/services/cashfree_payment_service.dart';
import '../../../../../injection/injection_container.dart';

class PaymentPage extends StatefulWidget {
  final PsychologistEntity psychologist;
  final SlotEntity slot;
  final String sessionType;

  const PaymentPage({
    super.key,
    required this.psychologist,
    required this.slot,
    required this.sessionType,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedMethod = 0;
  bool _isProcessing = false;
  String _statusMessage = '';

  late final AppointmentRepository _appointmentRepository;
  late final PaymentRepository _paymentRepository;
  late final CashfreePaymentService _cashfreeService;

  String? _appointmentId;

  final _methods = [
    (icon: Icons.account_balance_wallet_rounded, label: 'UPI / Wallets'),
    (icon: Icons.credit_card_rounded, label: 'Credit / Debit Card'),
    (icon: Icons.account_balance_rounded, label: 'Net Banking'),
  ];

  @override
  void initState() {
    super.initState();
    _appointmentRepository = sl<AppointmentRepository>();
    _paymentRepository = sl<PaymentRepository>();
    _cashfreeService = sl<CashfreePaymentService>();

    // Register Cashfree callbacks — must happen before doPayment is called
    _cashfreeService.setCallbacks(
      onSuccess: _onPaymentVerified,
      onError: _onPaymentError,
    );
  }

  // ── Cashfree callback: SDK confirmed payment ─────────────────────────────
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
        title: const Text('Payment'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              children: [
                _buildOrderSummary(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildPaymentMethods(),
                const SizedBox(height: AppDimensions.paddingL),
                _buildBillingNote(),
              ],
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final est = CurrencyUtils.calculateCallCost(
      totalSeconds: widget.slot.durationMinutes * 60,
      freeMinutes: widget.psychologist.freeMinutes,
      ratePerMinute: widget.psychologist.ratePerMinute,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingM),
          _SummaryRow(label: 'Psychologist', value: widget.psychologist.name),
          _SummaryRow(
            label: 'Date',
            value:
                '${widget.slot.startTime.day}/${widget.slot.startTime.month}/${widget.slot.startTime.year}',
          ),
          _SummaryRow(
            label: 'Time',
            value:
                '${widget.slot.startTime.hour.toString().padLeft(2, "0")}:${widget.slot.startTime.minute.toString().padLeft(2, "0")}',
          ),
          _SummaryRow(
            label: 'Session Type',
            value: widget.sessionType == 'video' ? 'Video Call' : 'Audio Call',
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Rate',
            value: CurrencyUtils.formatRatePerMin(widget.psychologist.ratePerMinute),
            highlight: true,
          ),
          _SummaryRow(
            label: 'Est. for ${widget.slot.durationMinutes} min',
            value: CurrencyUtils.formatRupees(est),
            highlight: true,
          ),
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.paddingS),
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    CurrencyUtils.callBillingText(
                      totalSeconds: 0,
                      freeMinutes: widget.psychologist.freeMinutes,
                      ratePerMinute: widget.psychologist.ratePerMinute,
                    ),
                    style: AppTextStyles.caption2.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method',
            style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppDimensions.paddingS),
        ..._methods.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            onTap: () => setState(() => _selectedMethod = i),
            child: Row(
              children: [
                Icon(
                  m.icon,
                  color: _selectedMethod == i ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(
                    m.label,
                    style: AppTextStyles.subheadline.copyWith(
                      color: _selectedMethod == i
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Radio<int>(
                  value: i,
                  groupValue: _selectedMethod,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBillingNote() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              'You will only be charged for the actual duration of the call. '
              'First 2 minutes are free.',
              style: AppTextStyles.caption1.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
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
              label: 'Pay & Confirm Booking',
              isLoading: _isProcessing,
              onPressed: _startPayment,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            // ── Temporary dev bypass ─────────────────────────────────────────
            // Remove this button before production release.
            TextButton(
              onPressed: _isProcessing ? null : _bypassPayment,
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

  // ── Real Cashfree payment flow ─────────────────────────────────────────────

  Future<void> _startPayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Booking appointment...';
    });

    try {
      // Step 1: Book the appointment slot
      if (_appointmentId == null) {
        final appointment = await _appointmentRepository.bookAppointment(
          BookAppointmentRequest(
            slotId: widget.slot.id,
            psychologistId: widget.psychologist.id,
            sessionType: widget.sessionType,
          ),
        );
        _appointmentId = appointment.id;
      }

      setState(() => _statusMessage = 'Creating payment order...');

      // Step 2: Create Cashfree order on the backend
      final orderData = await _paymentRepository.createOrder(
        CreateOrderRequest(
          type: 'appointment',
          amount: CurrencyUtils.calculateCallCost(
            totalSeconds: widget.slot.durationMinutes * 60,
            freeMinutes: widget.psychologist.freeMinutes,
            ratePerMinute: widget.psychologist.ratePerMinute,
          ),
          appointmentId: _appointmentId,
        ),
      );

      setState(() => _statusMessage = 'Opening payment gateway...');

      // Step 3: Launch Cashfree drop checkout
      // This is synchronous — the sheet opens immediately and returns.
      // Payment results arrive via _onPaymentVerified / _onPaymentError.
      _cashfreeService.launchDropCheckout(
        paymentSessionId: orderData.paymentSessionId,
        cashfreeOrderId: orderData.orderId,
      );

      // Sheet is now visible — reset loading state so the user can see it
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
          : 'Payment setup failed. Please retry.';
      AppSnackbar.show(context, message: message, type: SnackbarType.error);
    }
  }

  // ── Backend verification after Cashfree SDK success ──────────────────────

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
      context.pushReplacement(RouteNames.bookingConfirmed, extra: {
        'psychologist': widget.psychologist,
        'slot': widget.slot,
        'sessionType': widget.sessionType,
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      // Payment succeeded on Cashfree but backend verification is pending.
      // The backend webhook will update the appointment status automatically.
      AppSnackbar.show(
        context,
        message:
            'Payment received but confirmation is delayed. '
            'Your booking will be updated shortly.',
        type: SnackbarType.warning,
      );
    }
  }

  // ── Dev bypass: skip payment, confirm booking directly ───────────────────

  Future<void> _bypassPayment() async {
    setState(() => _isProcessing = true);
    try {
      if (_appointmentId == null) {
        final appointment = await _appointmentRepository.bookAppointment(
          BookAppointmentRequest(
            slotId: widget.slot.id,
            psychologistId: widget.psychologist.id,
            sessionType: widget.sessionType,
          ),
        );
        _appointmentId = appointment.id;
      }
      if (!mounted) return;
      context.pushReplacement(RouteNames.bookingConfirmed, extra: {
        'psychologist': widget.psychologist,
        'slot': widget.slot,
        'sessionType': widget.sessionType,
      });
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiErrorModel
          ? error.message
          : 'Booking failed. Please retry.';
      AppSnackbar.show(context, message: message, type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.subheadline.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.subheadline.copyWith(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
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

  late final AppointmentRepository _appointmentRepository;
  late final PaymentRepository _paymentRepository;
  late final CashfreePaymentService _cashfreePaymentService;
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
    _cashfreePaymentService = sl<CashfreePaymentService>();
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
          _buildPayButton(context),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final est = CurrencyUtils.calculateCallCost(
        totalSeconds: widget.slot.durationMinutes * 60,
        freeMinutes: widget.psychologist.freeMinutes,
        ratePerMinute: widget.psychologist.ratePerMinute);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingM),
          _SummaryRow(
              label: 'Psychologist', value: widget.psychologist.name),
          _SummaryRow(
              label: 'Date',
              value: '${widget.slot.startTime.day}/${widget.slot.startTime.month}/${widget.slot.startTime.year}'),
          _SummaryRow(
              label: 'Time',
              value: '${widget.slot.startTime.hour.toString().padLeft(2, "0")}:${widget.slot.startTime.minute.toString().padLeft(2, "0")}'),
          _SummaryRow(
              label: 'Session Type',
              value: widget.sessionType == 'video'
                  ? 'Video Call'
                  : 'Audio Call'),
          const Divider(height: 24),
          _SummaryRow(
              label: 'Rate',
              value: CurrencyUtils.formatRatePerMin(
                  widget.psychologist.ratePerMinute),
              highlight: true),
          _SummaryRow(
              label: 'Est. for ${widget.slot.durationMinutes} min',
              value: CurrencyUtils.formatRupees(est),
              highlight: true),
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.paddingS),
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    CurrencyUtils.callBillingText(
                      totalSeconds: 0,
                      freeMinutes: widget.psychologist.freeMinutes,
                      ratePerMinute: widget.psychologist.ratePerMinute,
                    ),
                    style: AppTextStyles.caption2
                        .copyWith(color: AppColors.info),
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
            style: AppTextStyles.headline
                .copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppDimensions.paddingS),
        ..._methods.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            onTap: () => setState(() => _selectedMethod = i),
            child: Row(
              children: [
                Icon(m.icon,
                    color: _selectedMethod == i
                        ? AppColors.primary
                        : AppColors.textSecondary),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(m.label,
                      style: AppTextStyles.subheadline.copyWith(
                          color: _selectedMethod == i
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)),
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
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              'You will only be charged for the actual duration of the call. '
              'First 2 minutes are free.',
              style:
                  AppTextStyles.caption1.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: AppButton(
          label: 'Confirm Booking',
          isLoading: _isProcessing,
          onPressed: () => _processPayment(context),
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final estimatedAmount = CurrencyUtils.calculateCallCost(
        totalSeconds: widget.slot.durationMinutes * 60,
        freeMinutes: widget.psychologist.freeMinutes,
        ratePerMinute: widget.psychologist.ratePerMinute,
      );

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

      final order = await _paymentRepository.createOrder(
        CreateOrderRequest(
          type: 'appointment',
          amount: estimatedAmount,
          appointmentId: _appointmentId,
        ),
      );

      final cashfreeResult = await _cashfreePaymentService.startCheckout(
        order: order,
      );

      if (!cashfreeResult.isSuccess) {
        if (!mounted) return;
        AppSnackbar.show(
          context,
          message: cashfreeResult.message,
          type: SnackbarType.error,
        );
        return;
      }

      final cfPaymentId = (cashfreeResult.raw['referenceId'] ??
              cashfreeResult.raw['cfPaymentId'] ??
              cashfreeResult.raw['paymentId'] ??
              cashfreeResult.raw['txId'] ??
              '')
          .toString();

      await _paymentRepository.verifyPayment(
        VerifyPaymentRequest(
          cashfreeOrderId: order.orderId,
          cfPaymentId: cfPaymentId,
        ),
      );

      if (!mounted) return;
      context.pushReplacement(RouteNames.bookingConfirmed, extra: {
        'psychologist': widget.psychologist,
        'slot': widget.slot,
        'sessionType': widget.sessionType,
      });
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiErrorModel ? error.message : 'Payment failed. Please retry.';
      AppSnackbar.show(
        context,
        message: message,
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
              style: AppTextStyles.subheadline
                  .copyWith(color: AppColors.textSecondary)),
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



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
import '../../../data/repositories/user_repository.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../../payments/data/repositories/payment_repository.dart';
import '../../../../../injection/injection_container.dart';

class PaymentPage extends StatefulWidget {
  final PsychologistEntity psychologist;
  final SlotEntity slot;
  final String sessionType;

  /// The exact sub-range the user chose inside the availability window.
  final DateTime bookedStartTime;
  final int bookedDurationMinutes;

  const PaymentPage({
    super.key,
    required this.psychologist,
    required this.slot,
    required this.sessionType,
    required this.bookedStartTime,
    required this.bookedDurationMinutes,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  String _statusMessage = '';

  late final AppointmentRepository _appointmentRepository;
  late final PaymentRepository _paymentRepository;
  late final UserRepository _userRepository;

  String? _appointmentId;

  /// Current wallet balance, fetched on entry. `null` while loading or if the
  /// fetch failed, in which case the booking is settled by the backend.
  double? _walletBalance;
  bool _walletLoading = true;

  /// True when the wallet alone can cover the chargeable cost — in that case
  /// the balance is debited instead of letting the backend settle the order.
  bool get _canPayFromWallet =>
      _walletBalance != null &&
      _estimatedCost > 0 &&
      _walletBalance! >= _estimatedCost;

  // Charge for the chosen session length: the full booked duration billed at
  // the psychologist's live backend rate. No free minutes — the booking is
  // prepaid in full, so the call itself carries no per-minute charge.
  double get _estimatedCost => CurrencyUtils.calculateCallCost(
        totalSeconds: widget.bookedDurationMinutes * 60,
        freeMinutes: 0,
        ratePerMinute: widget.psychologist.ratePerMinute,
      );

  DateTime get _sessionEnd =>
      widget.bookedStartTime.add(Duration(minutes: widget.bookedDurationMinutes));

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _appointmentRepository = sl<AppointmentRepository>();
    _paymentRepository = sl<PaymentRepository>();
    _userRepository = sl<UserRepository>();

    _loadWallet();
  }

  // ── Wallet balance check ─────────────────────────────────────────────────
  Future<void> _loadWallet() async {
    try {
      final wallet = await _userRepository.getMyWallet();
      if (!mounted) return;
      setState(() {
        _walletBalance = wallet.balance;
        _walletLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletBalance = null;
        _walletLoading = false;
      });
    }
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
                if (_canPayFromWallet)
                  _buildWalletNote()
                else
                  _buildNoPaymentNote(),
              ],
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final psych = widget.psychologist;
    final est = _estimatedCost;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingM),
          _SummaryRow(label: 'Psychologist', value: psych.name),
          _SummaryRow(
            label: 'Date',
            value:
                '${widget.bookedStartTime.day}/${widget.bookedStartTime.month}/${widget.bookedStartTime.year}',
          ),
          _SummaryRow(
            label: 'Time',
            value:
                '${_hhmm(widget.bookedStartTime)} – ${_hhmm(_sessionEnd)}',
          ),
          _SummaryRow(
            label: 'Session Type',
            value: widget.sessionType == 'video' ? 'Video Call' : 'Audio Call',
          ),
          _SummaryRow(
            label: 'Session Duration',
            value: '${widget.bookedDurationMinutes} min',
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Rate',
            value: CurrencyUtils.formatRatePerMin(psych.ratePerMinute),
          ),
          _SummaryRow(
            label: 'Total',
            value: CurrencyUtils.formatRupees(est),
            highlight: true,
          ),
          if (_walletBalance != null)
            _SummaryRow(
              label: 'Wallet balance',
              value: CurrencyUtils.formatRupees(_walletBalance!),
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
                    _billingExplanation(),
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

  /// Honest, backend-derived explanation of how the user is billed.
  String _billingExplanation() {
    return 'You pay for the full ${widget.bookedDurationMinutes}-minute session '
        'now at ${CurrencyUtils.formatRatePerMin(widget.psychologist.ratePerMinute)}. '
        'There are no extra per-minute charges during the call.';
  }

  Widget _buildNoPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No payment needed',
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confirming this booking settles it straight away — there is '
                  'no payment step to complete.',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletNote() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paying from wallet',
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your wallet balance covers this booking, so '
                  '${CurrencyUtils.formatRupees(_estimatedCost)} will be '
                  'deducted from your wallet.',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
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
            if (_walletLoading)
              const AppButton(
                label: 'Checking wallet…',
                isLoading: true,
                onPressed: null,
              )
            else if (_canPayFromWallet)
              AppButton(
                label: 'Pay ${CurrencyUtils.formatRupees(_estimatedCost)} from Wallet',
                prefixIcon: Icons.account_balance_wallet_rounded,
                isLoading: _isProcessing,
                onPressed: _payFromWallet,
              )
            else
              AppButton(
                label: 'Confirm Booking',
                isLoading: _isProcessing,
                onPressed: _confirmBooking,
              ),
          ],
        ),
      ),
    );
  }

  // ── Booking + settlement ───────────────────────────────────────
  //
  // Books the slot, then asks the backend to create the order. Payments are
  // disabled server-side, so the order comes back already settled and the
  // booking is confirmed without any checkout step.

  Future<void> _confirmBooking() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Booking appointment...';
    });

    try {
      await _ensureAppointmentBooked();

      setState(() => _statusMessage = 'Confirming booking...');

      final order = await _paymentRepository.createOrder(
        CreateOrderRequest(
          type: 'appointment',
          amount: _estimatedCost,
          appointmentId: _appointmentId,
        ),
      );

      if (!mounted) return;

      if (!order.isSettled) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
        AppSnackbar.show(
          context,
          message: 'This booking could not be confirmed automatically. '
              'Please contact support.',
          type: SnackbarType.error,
        );
        return;
      }

      _goToConfirmation();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      final message = error is ApiErrorModel
          ? error.message
          : 'Booking failed. Please retry.';
      AppSnackbar.show(context, message: message, type: SnackbarType.error);
    }
  }

  // ── Wallet payment flow ────────────────────────────────────────
  //
  // Books the slot, then debits the appointment cost from the wallet via the
  // backend. On a paid status we go straight to the confirmation screen.

  Future<void> _payFromWallet() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Booking appointment...';
    });

    try {
      await _ensureAppointmentBooked();

      setState(() => _statusMessage = 'Paying from wallet...');

      final result = await _paymentRepository.payFromWallet(
        WalletPaymentRequest(
          type: 'appointment',
          amount: _estimatedCost,
          appointmentId: _appointmentId,
        ),
      );

      if (!mounted) return;

      if (result.isPaid) {
        _goToConfirmation();
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
        AppSnackbar.show(
          context,
          message: result.message.isNotEmpty
              ? result.message
              : 'Wallet payment failed. Please try again.',
          type: SnackbarType.error,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      final message = error is ApiErrorModel
          ? error.message
          : 'Wallet payment failed. Please retry.';
      AppSnackbar.show(context, message: message, type: SnackbarType.error);
    }
  }

  /// Books the slot once — a retry after a failed settlement reuses the
  /// appointment created by the first attempt.
  Future<void> _ensureAppointmentBooked() async {
    if (_appointmentId != null) return;

    final appointment = await _appointmentRepository.bookAppointment(
      BookAppointmentRequest(
        slotId: widget.slot.id,
        psychologistId: widget.psychologist.id,
        sessionType: widget.sessionType,
        startTime: widget.bookedStartTime,
        durationMinutes: widget.bookedDurationMinutes,
      ),
    );
    _appointmentId = appointment.id;
  }

  void _goToConfirmation() {
    context.pushReplacement(RouteNames.bookingConfirmed, extra: {
      'psychologist': widget.psychologist,
      'slot': widget.slot,
      'sessionType': widget.sessionType,
      'appointmentId': _appointmentId,
      'bookedStartTime': widget.bookedStartTime,
      'bookedDurationMinutes': widget.bookedDurationMinutes,
    });
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

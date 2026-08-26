import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/widgets/app_button.dart';
import '../bloc/call_bloc.dart';

class PostCallSummaryScreen extends StatelessWidget {
  final CallEnded callEnded;

  const PostCallSummaryScreen({super.key, required this.callEnded});

  bool get _walletExhausted => callEnded.endReason == 'wallet_exhausted';

  @override
  Widget build(BuildContext context) {
    final mins = callEnded.totalSeconds ~/ 60;
    final secs = callEnded.totalSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color:
                        _walletExhausted ? AppColors.error : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      _walletExhausted
                          ? Icons.account_balance_wallet_rounded
                          : Icons.call_rounded,
                      color: Colors.white,
                      size: 48),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              Text('Call Summary',
                  style: AppTextStyles.title2
                      .copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.paddingS),
              Text('with ${callEnded.psychologistName}',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.paddingM),
              _buildEndReasonNote(),
              const SizedBox(height: AppDimensions.paddingM),
              // Summary card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.timer_rounded,
                      label: 'Duration',
                      value: '${mins}m ${secs}s',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Amount Charged',
                      value: callEnded.totalCharge == 0
                          ? 'Free'
                          : CurrencyUtils.formatRupees(callEnded.totalCharge),
                      valueColor: callEnded.totalCharge == 0
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    if (callEnded.paidFromWallet != null) ...[
                      const Divider(height: 24),
                      _SummaryRow(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Paid from Wallet',
                        value: CurrencyUtils.formatRupees(
                            callEnded.paidFromWallet!),
                        valueColor: AppColors.textPrimary,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              if (_walletExhausted) ...[
                AppButton(
                  label: 'Recharge Wallet',
                  onPressed: () => context.go(RouteNames.userWallet),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                AppButton(
                  label: 'Back to Home',
                  style: AppButtonStyle.outlined,
                  onPressed: () => context.go(RouteNames.userHome),
                ),
              ] else ...[
                AppButton(
                  label: 'Back to Home',
                  onPressed: () => context.go(RouteNames.userHome),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                AppButton(
                  label: 'Book Another Session',
                  style: AppButtonStyle.outlined,
                  onPressed: () => context.go(RouteNames.userHome),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Explains why the call ended, driven by `endReason` from the backend.
  Widget _buildEndReasonNote() {
    final String text;
    final Color color;
    final IconData icon;

    switch (callEnded.endReason) {
      case 'wallet_exhausted':
        text = callEnded.message ??
            'Your wallet balance ran out, so the call was ended automatically. '
                'Recharge to continue talking.';
        color = AppColors.error;
        icon = Icons.warning_amber_rounded;
        break;
      case 'heartbeat_timeout':
        text = 'The call ended because the connection was lost.';
        color = AppColors.warning;
        icon = Icons.wifi_off_rounded;
        break;
      default:
        text = callEnded.message ?? 'The call ended normally.';
        color = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption1.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppDimensions.paddingM),
        Text(label,
            style: AppTextStyles.subheadline
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.subheadline.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

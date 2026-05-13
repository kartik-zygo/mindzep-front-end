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
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: Colors.white, size: 48),
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
              const SizedBox(height: AppDimensions.paddingXL),
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
                      value:
                          '${mins}m ${secs}s',
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
                    if (callEnded.totalSeconds < 120) ...[
                      const Divider(height: 24),
                      _SummaryRow(
                        icon: Icons.check_circle_rounded,
                        label: 'Billing',
                        value: 'Free (< 2 min)',
                        valueColor: AppColors.success,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              // Rating prompt
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Column(
                  children: [
                    Text('Rate your experience',
                        style: AppTextStyles.headline
                            .copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: AppDimensions.paddingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.star_outline_rounded,
                                size: 36, color: Color(0xFFFFB300)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
          ),
        ),
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


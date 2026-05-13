import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_strings.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              AppStrings.somethingWentWrong,
              style: AppTextStyles.title3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              AppButton(
                label: AppStrings.retry,
                onPressed: onRetry,
                isFullWidth: false,
                width: 140,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

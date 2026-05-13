import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  (Color bg, Color text) _colors() {
    return switch (status.toLowerCase()) {
      'confirmed' || 'approved' || 'active' || 'paid' || 'published' =>
        (AppColors.success.withOpacity(0.12), AppColors.success),
      'pending' || 'upcoming' || 'under review' =>
        (AppColors.warning.withOpacity(0.12), AppColors.warning),
      'cancelled' || 'rejected' || 'failed' || 'suspended' =>
        (AppColors.error.withOpacity(0.12), AppColors.error),
      'completed' || 'done' =>
        (AppColors.info.withOpacity(0.12), AppColors.info),
      'draft' => (AppColors.textTertiary.withOpacity(0.12), AppColors.textSecondary),
      _ => (AppColors.primary.withOpacity(0.12), AppColors.primary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption1.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';

enum EmptyStateVariant {
  appointments,
  psychologists,
  blogs,
  sessions,
  notifications,
  generic,
}

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateVariant variant;
  final IconData? icon;

  const AppEmptyState({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.variant = EmptyStateVariant.generic,
    this.icon,
  });

  IconData _variantIcon() {
    if (icon != null) return icon!;
    return switch (variant) {
      EmptyStateVariant.appointments => Icons.calendar_today_outlined,
      EmptyStateVariant.psychologists => Icons.person_search_outlined,
      EmptyStateVariant.blogs => Icons.article_outlined,
      EmptyStateVariant.sessions => Icons.history_outlined,
      EmptyStateVariant.notifications => Icons.notifications_none_outlined,
      EmptyStateVariant.generic => Icons.inbox_outlined,
    };
  }

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
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _variantIcon(),
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              title,
              style: AppTextStyles.title3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                body!,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

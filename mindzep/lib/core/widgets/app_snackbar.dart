import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (color, icon) = switch (type) {
      SnackbarType.success => (AppColors.success, Icons.check_circle_outline),
      SnackbarType.error => (AppColors.error, Icons.error_outline),
      SnackbarType.warning => (AppColors.warning, Icons.warning_amber_outlined),
      SnackbarType.info => (AppColors.info, Icons.info_outline),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.subheadline.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

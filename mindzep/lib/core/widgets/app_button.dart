import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

enum AppButtonStyle { primary, secondary, outlined, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? prefixIcon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    Widget button;

    switch (style) {
      case AppButtonStyle.primary:
        button = _GradientButton(
          onPressed: isLoading ? null : onPressed,
          height: height,
          child: child,
        );
        break;
      case AppButtonStyle.secondary:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: child,
        );
        break;
      case AppButtonStyle.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, height),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: DefaultTextStyle(
            style: AppTextStyles.headline.copyWith(color: AppColors.primary),
            child: child,
          ),
        );
        break;
      case AppButtonStyle.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, height),
          ),
          child: DefaultTextStyle(
            style: AppTextStyles.headline.copyWith(color: AppColors.primary),
            child: child,
          ),
        );
        break;
      case AppButtonStyle.danger:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: child,
        );
        break;
    }

    if (isFullWidth || width != null) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: button,
      );
    }
    return button;
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;

  const _GradientButton({
    required this.onPressed,
    required this.child,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? AppColors.primaryGradient
            : null,
        color: onPressed == null ? AppColors.textTertiary : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: SizedBox(
            height: height,
            child: Center(
              child: DefaultTextStyle(
                style: AppTextStyles.headline.copyWith(color: Colors.white),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

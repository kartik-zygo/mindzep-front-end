import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppDimensions.radiusL;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
                  child: child,
                ),
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
              child: child,
            ),
    );
  }
}

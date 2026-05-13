import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool isScrollControlled = true,
    double? initialChildSize,
    double maxChildSize = 0.92,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetContainer(
        title: title,
        maxChildSize: maxChildSize,
        initialChildSize: initialChildSize ?? (title != null ? 0.6 : 0.5),
        child: child,
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final double initialChildSize;
  final double maxChildSize;

  const _BottomSheetContainer({
    required this.child,
    this.title,
    required this.initialChildSize,
    required this.maxChildSize,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: 0.3,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.paddingS),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: AppDimensions.paddingM),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: AppDimensions.paddingM),
            ] else
              const SizedBox(height: AppDimensions.paddingS),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

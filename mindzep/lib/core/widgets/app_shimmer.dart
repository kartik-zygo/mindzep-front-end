import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceSecondary,
      highlightColor: AppColors.surface,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 56, height: 56, borderRadius: 28),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 12),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: double.infinity, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerAvatar extends StatelessWidget {
  final double radius;

  const ShimmerAvatar({super.key, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ShimmerBox(
        width: radius * 2,
        height: radius * 2,
        borderRadius: radius,
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 6),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

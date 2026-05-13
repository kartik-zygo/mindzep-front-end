import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum AvailabilityStatus { available, busy, offline }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final AvailabilityStatus? availabilityStatus;
  final bool showStatusDot;
  final String? initials;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.radius = 28,
    this.availabilityStatus,
    this.showStatusDot = false,
    this.initials,
  });

  Color _dotColor(AvailabilityStatus status) => switch (status) {
        AvailabilityStatus.available => AppColors.available,
        AvailabilityStatus.busy => AppColors.busy,
        AvailabilityStatus.offline => AppColors.offline,
      };

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight.withOpacity(0.3),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => _InitialsAvatar(
                  initials: initials,
                  radius: radius,
                ),
                errorWidget: (_, __, ___) => _InitialsAvatar(
                  initials: initials,
                  radius: radius,
                ),
              ),
            )
          : _InitialsAvatar(initials: initials, radius: radius),
    );

    if (!showStatusDot || availabilityStatus == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: AppDimensions.statusDotSize,
            height: AppDimensions.statusDotSize,
            decoration: BoxDecoration(
              color: _dotColor(availabilityStatus!),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: AppDimensions.statusDotBorderWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String? initials;
  final double radius;

  const _InitialsAvatar({this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials ?? '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.55,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

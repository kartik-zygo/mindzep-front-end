import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/widgets/app_avatar.dart';

class PsychologistCard extends StatelessWidget {
  final PsychologistEntity psychologist;
  final bool isFeatured;

  const PsychologistCard({
    super.key,
    required this.psychologist,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = psychologist.status == AvailabilityStatus.available;

    return GestureDetector(
      onTap: () => context.push(
        RouteNames.psychologistDetail.replaceAll(':id', psychologist.id),
        extra: psychologist,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: avatar + info + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: psychologist.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: psychologist.avatarUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _AvatarFallback(psychologist.name),
                              )
                            : _AvatarFallback(psychologist.name),
                      ),
                      if (isAvailable)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          psychologist.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          psychologist.specialization,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFFE8FFF1) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ],
              ),
              // ── Tag Chips
              if (psychologist.specializations.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: psychologist.specializations.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5E5CE6)),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // ── Rating + Experience
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFF9500)),
                  const SizedBox(width: 3),
                  Text(
                    '${psychologist.ratingAverage.toStringAsFixed(1)} (${psychologist.totalReviews})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 3),
                  Text(
                    '${psychologist.yearsExperience} years',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              // ── Price + Buttons
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyUtils.formatRupees(psychologist.ratePerMinute),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5E5CE6)),
                            ),
                            const TextSpan(
                              text: '/min',
                              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      ),
                      if (psychologist.freeMinutes > 0)
                        Text(
                          '• ${psychologist.freeMinutes} min free',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF34C759), fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push(
                      RouteNames.slotBooking.replaceAll(':psychologistId', psychologist.id),
                      extra: psychologist,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF5E5CE6)),
                          SizedBox(width: 5),
                          Text('Book', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isAvailable ? () => context.push(RouteNames.preCall, extra: psychologist) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isAvailable
                            ? const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30D158)])
                            : null,
                        color: isAvailable ? null : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isAvailable
                            ? [BoxShadow(color: const Color(0xFF34C759).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_rounded, size: 15, color: isAvailable ? Colors.white : const Color(0xFF8E8E93)),
                          const SizedBox(width: 5),
                          Text(
                            'Call Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? Colors.white : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback(this.name);

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((p) => p[0]).join().toUpperCase();
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5E5CE6))),
      ),
    );
  }
}


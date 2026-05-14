import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_card.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() =>
      _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _activeFilter = 'All';
  static const _filters = ['All', 'Upcoming', 'Ongoing', 'Done', 'Cancelled'];

  List<AppointmentEntity> get _filtered {
    final all = MockData.appointments;
    return switch (_activeFilter) {
      'Upcoming' =>
        all.where((a) => a.status == AppointmentStatus.upcoming).toList(),
      'Ongoing' =>
        all.where((a) => a.status == AppointmentStatus.ongoing).toList(),
      'Done' =>
        all.where((a) => a.status == AppointmentStatus.completed).toList(),
      'Cancelled' =>
        all
            .where((a) =>
                a.status == AppointmentStatus.cancelled ||
                a.status == AppointmentStatus.noShow)
            .toList(),
      _ => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final all = MockData.appointments;
    final upcoming =
        all.where((a) => a.status == AppointmentStatus.upcoming).length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _adminGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Appointments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Stats pills
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              '$upcoming upcoming',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Summary cards row
                      Row(
                        children: [
                          _SummaryChip(
                              icon: Icons.event_outlined,
                              label: '${all.length} Total'),
                          const SizedBox(width: 10),
                          _SummaryChip(
                              icon: Icons.check_circle_outline_rounded,
                              label:
                                  '${all.where((a) => a.status == AppointmentStatus.completed).length} Done'),
                          const SizedBox(width: 10),
                          _SummaryChip(
                              icon: Icons.cancel_outlined,
                              label:
                                  '${all.where((a) => a.status == AppointmentStatus.cancelled || a.status == AppointmentStatus.noShow).length} Cancelled'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final f = _filters[i];
                            final selected = _activeFilter == f;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _activeFilter = f),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusFull),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_outlined,
                        size: 56,
                        color: AppColors.textTertiary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No appointments found',
                      style: AppTextStyles.callout.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                itemCount: filtered.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDimensions.paddingS),
                      child: Text(
                        '${filtered.length} appointments',
                        style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return _AdminApptCard(appointment: filtered[i - 1]);
                },
              ),
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────

class _AdminApptCard extends StatelessWidget {
  final AppointmentEntity appointment;
  const _AdminApptCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final psych = MockData.psychologists.firstWhere(
      (p) => p.id == appointment.psychologistId,
      orElse: () => MockData.psychologists.first,
    );
    final user = MockData.adminUsers.firstWhere(
      (u) => u.id == appointment.userId,
      orElse: () => MockData.adminUsers.first,
    );

    final statusColor = switch (appointment.status) {
      AppointmentStatus.upcoming => AppColors.info,
      AppointmentStatus.ongoing => AppColors.success,
      AppointmentStatus.completed => AppColors.textSecondary,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => AppColors.warning,
    };

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator bar
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel(appointment.status),
                      style: AppTextStyles.caption1.copyWith(
                          color: statusColor, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatDateTime(appointment.scheduledAt),
                      style: AppTextStyles.footnote
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (appointment.totalCharge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    '₹${appointment.totalCharge!.toStringAsFixed(0)}',
                    style: AppTextStyles.caption1.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // User → Psychologist row
          Row(
            children: [
              // User side
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(
                      imageUrl: user.avatarUrl,
                      radius: 18,
                      initials: user.name[0],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption1.copyWith(
                                  fontWeight: FontWeight.w600)),
                          Text('User',
                              style: AppTextStyles.caption2.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.textSecondary),
              ),
              // Psychologist side
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(
                      imageUrl: psych.avatarUrl,
                      radius: 18,
                      initials: psych.name[0],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(psych.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption1.copyWith(
                                  fontWeight: FontWeight.w600)),
                          Text('Therapist',
                              style: AppTextStyles.caption2.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (appointment.sessionType != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  appointment.sessionType == SessionType.video
                      ? Icons.videocam_outlined
                      : Icons.phone_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  appointment.sessionType == SessionType.video
                      ? 'Video Call'
                      : 'Voice Call',
                  style: AppTextStyles.caption2
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (appointment.durationMinutes != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${appointment.durationMinutes} min',
                    style: AppTextStyles.caption2
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(AppointmentStatus s) {
    return switch (s) {
      AppointmentStatus.upcoming => 'Upcoming',
      AppointmentStatus.ongoing => 'Ongoing',
      AppointmentStatus.completed => 'Completed',
      AppointmentStatus.cancelled => 'Cancelled',
      AppointmentStatus.noShow => 'No Show',
    };
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $h:$m';
  }
}


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

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = MockData.appointments;
    final upcoming = all
        .where((a) => a.status == AppointmentStatus.upcoming)
        .toList();
    final completed = all
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();
    final cancelled = all
        .where((a) =>
            a.status == AppointmentStatus.cancelled ||
            a.status == AppointmentStatus.noShow)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Appointments'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.subheadline
              .copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Done (${completed.length})'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AdminApptList(appointments: upcoming),
          _AdminApptList(appointments: completed),
          _AdminApptList(appointments: cancelled),
        ],
      ),
    );
  }
}

class _AdminApptList extends StatelessWidget {
  final List<AppointmentEntity> appointments;
  const _AdminApptList({required this.appointments});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: appointments.length,
      itemBuilder: (_, i) => _AdminApptCard(appointment: appointments[i]),
    );
  }
}

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

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(
                        imageUrl: user.avatarUrl,
                        radius: 16,
                        initials: user.name[0]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(user.name,
                          style: AppTextStyles.subheadline
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(
                        imageUrl: psych.avatarUrl,
                        radius: 16,
                        initials: psych.name[0]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(psych.name,
                          style: AppTextStyles.subheadline
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              StatusBadge(status: _statusLabel(appointment.status)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
              '${appointment.scheduledAt.day}/${appointment.scheduledAt.month} · ${appointment.scheduledAt.hour.toString().padLeft(2, "0")}:${appointment.scheduledAt.minute.toString().padLeft(2, "0")}',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary)),
              if (appointment.totalCharge != null) ...[
                const Spacer(),
                const Icon(Icons.currency_rupee_rounded,
                    size: 12, color: AppColors.success),
                Text(
                    appointment.totalCharge!.toStringAsFixed(0),
                    style: AppTextStyles.caption1
                        .copyWith(color: AppColors.success)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.ongoing:
        return 'Ongoing';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}


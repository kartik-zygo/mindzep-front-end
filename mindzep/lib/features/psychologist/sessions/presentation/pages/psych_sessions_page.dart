import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_empty_state.dart';

const _kTealGradient = LinearGradient(
  colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class PsychSessionsPage extends StatefulWidget {
  const PsychSessionsPage({super.key});

  @override
  State<PsychSessionsPage> createState() => _PsychSessionsPageState();
}

class _PsychSessionsPageState extends State<PsychSessionsPage>
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
    final sessions = MockData.psychSessions;
    final upcoming = sessions
        .where((s) => s.status == AppointmentStatus.upcoming)
        .toList();
    final ongoing = sessions
        .where((s) => s.status == AppointmentStatus.ongoing)
        .toList();
    final completed = sessions
        .where((s) =>
            s.status == AppointmentStatus.completed ||
            s.status == AppointmentStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Teal Gradient Header ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: _kTealGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My Sessions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Summary badges
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${upcoming.length} upcoming',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Stats chips row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _HeaderStat(label: 'Total', value: '${sessions.length + 230}'),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Hours', value: '${((sessions.length + 230) * 45 ~/ 60)}h'),
                        const SizedBox(width: 8),
                        _HeaderStat(
                          label: 'Avg Rating',
                          value: '${MockData.psychologists.first.ratingAverage.toStringAsFixed(1)}★',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // TabBar inside gradient header
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                    tabs: [
                      Tab(text: 'Upcoming (${upcoming.length})'),
                      Tab(text: 'Ongoing'),
                      Tab(text: 'History'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── Tab content ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SessionList(sessions: upcoming),
                _SessionList(sessions: ongoing),
                _SessionList(sessions: completed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<AppointmentEntity> sessions;
  const _SessionList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const AppEmptyState(title: 'No Sessions', variant: EmptyStateVariant.sessions);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: sessions.length,
      itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AppointmentEntity session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final user = MockData.adminUsers.firstWhere(
      (u) => u.id == session.userId,
      orElse: () => MockData.adminUsers.first,
    );
    final statusLabel = _statusLabel(session.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: user.avatarUrl,
                radius: 22,
                initials: user.name[0],
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: AppTextStyles.subheadline
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                        '${session.scheduledAt.day}/${session.scheduledAt.month} · ${session.scheduledAt.hour.toString().padLeft(2, "0")}:${session.scheduledAt.minute.toString().padLeft(2, "0")}',
                        style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusBadge(status: statusLabel),
            ],
          ),
          if (session.actualDurationSeconds != null) ...[
            const SizedBox(height: AppDimensions.paddingS),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text('${session.durationMinutes} min',
                    style: AppTextStyles.caption1
                        .copyWith(color: AppColors.textSecondary)),
                if (session.totalCharge != null) ...[
                  const SizedBox(width: AppDimensions.paddingM),
                  const Icon(Icons.currency_rupee_rounded,
                      size: 13, color: AppColors.success),
                  Text('${session.totalCharge!.toStringAsFixed(0)} earned',
                      style: AppTextStyles.caption1
                          .copyWith(color: AppColors.success)),
                ],
              ],
            ),
          ],
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

class _HeaderStat extends StatelessWidget {
  final String label, value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

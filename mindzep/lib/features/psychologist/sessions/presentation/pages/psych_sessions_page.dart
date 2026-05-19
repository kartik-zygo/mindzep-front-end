import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/appointments/data/models/appointment_models.dart';
import '../../../../user/appointments/data/repositories/appointment_repository.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_snackbar.dart';

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
  late final AppointmentRepository _appointmentRepository;

  bool _loading = true;
  String? _errorMessage;
  List<AppointmentEntity> _sessions = const <AppointmentEntity>[];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _appointmentRepository = sl<AppointmentRepository>();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await _appointmentRepository.listAppointments(
        page: 1,
        limit: 100,
      );

      if (!mounted) return;
      setState(() {
        _sessions = response.items.map((item) => item.toEntity()).toList();
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[MindZep] PsychSessions load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
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
    final totalMinutes = sessions.fold<int>(0, (sum, item) => sum + item.durationMinutes);

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
                        _HeaderStat(label: 'Total', value: '${sessions.length}'),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Hours', value: _formatHours(totalMinutes)),
                        const SizedBox(width: 8),
                        _HeaderStat(
                          label: 'Avg Rating',
                          value: _avgRatingValue(sessions),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingL),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMessage!,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppDimensions.paddingM),
                              ElevatedButton(
                                onPressed: _loadSessions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSessions,
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _SessionList(
                              sessions: upcoming,
                              onAddNotes: _showAddNotesDialog,
                            ),
                            _SessionList(
                              sessions: ongoing,
                              onAddNotes: _showAddNotesDialog,
                            ),
                            _SessionList(
                              sessions: completed,
                              onAddNotes: _showAddNotesDialog,
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddNotesDialog(AppointmentEntity session) async {
    final controller = TextEditingController(text: session.psychologistNotes ?? '');
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Session Notes'),
              content: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Add private notes for this session',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final notes = controller.text.trim();
                          if (notes.isEmpty) {
                            AppSnackbar.show(
                              dialogContext,
                              message: 'Notes cannot be empty.',
                              type: SnackbarType.error,
                            );
                            return;
                          }

                          setDialogState(() {
                            submitting = true;
                          });

                          try {
                            await _appointmentRepository.addPsychologistNotes(
                              session.id,
                              PsychologistNotesRequest(notes: notes),
                            );
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            AppSnackbar.show(
                              context,
                              message: 'Notes saved successfully.',
                              type: SnackbarType.success,
                            );
                            _loadSessions();
                          } catch (_) {
                            if (!mounted) return;
                            setDialogState(() {
                              submitting = false;
                            });
                            AppSnackbar.show(
                              dialogContext,
                              message: 'Unable to save notes right now.',
                              type: SnackbarType.error,
                            );
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _avgRatingValue(List<AppointmentEntity> sessions) {
    final rated = sessions.where((s) => s.rating != null).toList();
    if (rated.isEmpty) {
      return '0.0★';
    }

    final total = rated.fold<double>(0, (sum, item) => sum + (item.rating ?? 0));
    final avg = total / rated.length;
    return '${avg.toStringAsFixed(1)}★';
  }

  String _formatHours(int minutes) {
    final hours = minutes / 60;
    if (hours == hours.roundToDouble()) {
      return '${hours.toStringAsFixed(0)}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}

class _SessionList extends StatelessWidget {
  final List<AppointmentEntity> sessions;
  final Future<void> Function(AppointmentEntity session)? onAddNotes;
  const _SessionList({required this.sessions, this.onAddNotes});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const AppEmptyState(title: 'No Sessions', variant: EmptyStateVariant.sessions);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: sessions.length,
      itemBuilder: (_, i) => _SessionCard(
        session: sessions[i],
        onAddNotes: onAddNotes,
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AppointmentEntity session;
  final Future<void> Function(AppointmentEntity session)? onAddNotes;
  const _SessionCard({required this.session, this.onAddNotes});

  @override
  Widget build(BuildContext context) {
    final userName = session.userName.trim().isEmpty ? 'Patient' : session.userName;
    final statusLabel = _statusLabel(session.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: null,
                radius: 22,
                initials: userName[0],
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
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
          if (onAddNotes != null &&
              (session.status == AppointmentStatus.ongoing ||
                  session.status == AppointmentStatus.completed)) ...[
            const SizedBox(height: AppDimensions.paddingS),
            if (session.psychologistNotes != null &&
                session.psychologistNotes!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
                child: Text(
                  'Notes: ${session.psychologistNotes!}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onAddNotes!(session),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  session.psychologistNotes == null ||
                          session.psychologistNotes!.trim().isEmpty
                      ? 'Add Notes'
                      : 'Edit Notes',
                ),
              ),
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

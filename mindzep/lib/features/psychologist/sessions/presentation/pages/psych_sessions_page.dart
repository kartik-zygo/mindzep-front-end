import 'package:flutter/material.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/appointments/data/models/appointment_models.dart';
import '../../../../user/appointments/data/repositories/appointment_repository.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../shared/psych_ui.dart';

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
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final ongoing = sessions
        .where((s) => s.status == AppointmentStatus.ongoing)
        .toList();
    final completed = sessions
        .where((s) =>
            s.status == AppointmentStatus.completed ||
            s.status == AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final totalMinutes =
        sessions.fold<int>(0, (sum, item) => sum + item.durationMinutes);

    return PsychScaffold(
      body: Column(
        children: [
          PsychGradientHeader(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Sessions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    PsychStatusPill(
                      label: '${upcoming.length} upcoming',
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    PsychGlassStat(
                      value: '${sessions.length}',
                      label: 'Total',
                    ),
                    const SizedBox(width: 10),
                    PsychGlassStat(
                      value: _formatHours(totalMinutes),
                      label: 'Hours',
                    ),
                    const SizedBox(width: 10),
                    PsychGlassStat(
                      value: _avgRatingValue(sessions),
                      label: 'Avg Rating',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Upcoming (${upcoming.length})'),
                    Tab(text: 'Ongoing (${ongoing.length})'),
                    Tab(text: 'History (${completed.length})'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: PsychPalette.teal))
                : _errorMessage != null
                    ? _ErrorView(message: _errorMessage!, onRetry: _loadSessions)
                    : RefreshIndicator(
                        color: PsychPalette.teal,
                        onRefresh: _loadSessions,
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _SessionList(
                                sessions: upcoming,
                                onAddNotes: _showAddNotesDialog),
                            _SessionList(
                                sessions: ongoing,
                                onAddNotes: _showAddNotesDialog),
                            _SessionList(
                                sessions: completed,
                                onAddNotes: _showAddNotesDialog),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddNotesDialog(AppointmentEntity session) async {
    final controller =
        TextEditingController(text: session.psychologistNotes ?? '');
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Session Notes',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: PsychPalette.ink)),
              content: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Add private notes for this session',
                  filled: true,
                  fillColor: PsychPalette.scaffold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: PsychPalette.inkSoft)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PsychPalette.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
    if (rated.isEmpty) return '0.0★';
    final total =
        rated.fold<double>(0, (sum, item) => sum + (item.rating ?? 0));
    return '${(total / rated.length).toStringAsFixed(1)}★';
  }

  String _formatHours(int minutes) {
    final hours = minutes / 60;
    if (hours == hours.roundToDouble()) {
      return '${hours.toStringAsFixed(0)}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: PsychPalette.inkFaint, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: PsychPalette.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PsychPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<AppointmentEntity> sessions;
  final Future<void> Function(AppointmentEntity session)? onAddNotes;
  const _SessionList({required this.sessions, this.onAddNotes});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          PsychEmptyState(
            icon: Icons.event_note_rounded,
            title: 'No sessions here',
            subtitle: 'Sessions will appear here once they are scheduled.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (_, i) => PsychFadeIn(
        delayMs: (i * 40).clamp(0, 240),
        child: _SessionCard(session: sessions[i], onAddNotes: onAddNotes),
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
    final userName =
        session.userName.trim().isEmpty ? 'Patient' : session.userName;
    final isVideo = session.sessionType == SessionType.video;
    final (statusColor, statusLabel) = _statusStyle(session.status);
    final canAddNotes = onAddNotes != null &&
        (session.status == AppointmentStatus.ongoing ||
            session.status == AppointmentStatus.completed);
    final hasNotes = session.psychologistNotes != null &&
        session.psychologistNotes!.trim().isNotEmpty;

    return PsychCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      PsychPalette.tealMist,
                      PsychPalette.tealMistStrong
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PsychPalette.tealDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PsychPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.phone_rounded,
                          size: 13,
                          color: PsychPalette.inkFaint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(session.scheduledAt)} · ${_hhmm(session.scheduledAt)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: PsychPalette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PsychStatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          if (session.actualDurationSeconds != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: PsychPalette.scaffold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: PsychPalette.inkSoft),
                  const SizedBox(width: 5),
                  Text(
                    'Lasted ${session.durationMinutes} min',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PsychPalette.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasNotes) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: PsychPalette.tealMist.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PsychPalette.tealMistStrong),
              ),
              child: Text(
                session.psychologistNotes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: PsychPalette.inkSoft,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (canAddNotes) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => onAddNotes!(session),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: PsychPalette.tealMist,
                    borderRadius: BorderRadius.circular(PsychRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(hasNotes ? Icons.edit_rounded : Icons.add_rounded,
                          size: 15, color: PsychPalette.tealDeep),
                      const SizedBox(width: 5),
                      Text(
                        hasNotes ? 'Edit Notes' : 'Add Notes',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: PsychPalette.tealDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, String) _statusStyle(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming:
        return (PsychPalette.info, 'Upcoming');
      case AppointmentStatus.ongoing:
        return (PsychPalette.success, 'Ongoing');
      case AppointmentStatus.completed:
        return (PsychPalette.tealDeep, 'Completed');
      case AppointmentStatus.cancelled:
        return (PsychPalette.danger, 'Cancelled');
      case AppointmentStatus.noShow:
        return (PsychPalette.warning, 'No Show');
    }
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../data/models/appointment_models.dart';
import '../../data/repositories/appointment_repository.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final AppointmentRepository _appointmentRepository;

  int _selectedTab = 0;
  static const _tabs = ['Upcoming', 'Active', 'Past'];
  bool _loading = true;
  String? _errorMessage;
  List<AppointmentEntity> _allAppointments = const <AppointmentEntity>[];
  final Set<String> _cancellingAppointmentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _appointmentRepository = sl<AppointmentRepository>();
    _loadAppointments();
  }

  List<AppointmentEntity> get _upcoming {
    final appointments = _allAppointments
        .where((appointment) => appointment.status == AppointmentStatus.upcoming)
        .toList();
    appointments.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return appointments;
  }

  List<AppointmentEntity> get _ongoing {
    final appointments = _allAppointments
        .where((appointment) => appointment.status == AppointmentStatus.ongoing)
        .toList();
    appointments.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return appointments;
  }

  List<AppointmentEntity> get _past {
    final appointments = _allAppointments
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.completed ||
              appointment.status == AppointmentStatus.cancelled ||
              appointment.status == AppointmentStatus.noShow,
        )
        .toList();
    appointments.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return appointments;
  }

  Future<void> _loadAppointments({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final paginated = await _appointmentRepository.listAppointments(
        page: 1,
        limit: 200,
      );

      final mapped = paginated.items
          .map((appointment) => appointment.toEntity())
          .toList();

      if (!mounted) return;
      setState(() {
        _allAppointments = mapped;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            error is ApiErrorModel ? error.message : 'Unable to load sessions.';
      });
    } finally {
      if (mounted && showLoader) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(AppointmentEntity appointment) async {
    if (_cancellingAppointmentIds.contains(appointment.id)) {
      return;
    }

    setState(() {
      _cancellingAppointmentIds.add(appointment.id);
    });

    try {
      await _appointmentRepository.cancelAppointment(
        appointment.id,
        const CancelAppointmentRequest(reason: 'Cancelled by user'),
      );

      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Appointment cancelled successfully.',
        type: SnackbarType.success,
      );
      await _loadAppointments(showLoader: false);
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiErrorModel ? error.message : 'Unable to cancel session.';
      AppSnackbar.show(
        context,
        message: message,
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingAppointmentIds.remove(appointment.id);
        });
      }
    }
  }

  void _startCallFromAppointment(AppointmentEntity appointment) {
    context.push(
      RouteNames.preCall,
      extra: appointment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _allAppointments;
    final upcoming = _upcoming;
    final ongoing = _ongoing;
    final past = _past;

    final lists = [upcoming, ongoing, past];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Sessions',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            onPressed: () => context.go(RouteNames.userHome),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats row
                    Row(
                      children: [
                        _HeaderStat(label: 'Total', value: '${all.length}', color: Colors.white),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Upcoming', value: '${upcoming.length}', color: const Color(0xFFB8B4FF)),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Completed', value: '${past.where((a) => a.status == AppointmentStatus.completed).length}', color: const Color(0xFFB8F0C8)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab bar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: List.generate(_tabs.length, (i) {
                          final selected = _selectedTab == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _tabs[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? const Color(0xFF5E5CE6) : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && all.isEmpty
                    ? _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadAppointments,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: _AppointmentList(
                          appointments: lists[_selectedTab],
                          tabLabel: _tabs[_selectedTab],
                          cancellingIds: _cancellingAppointmentIds,
                          onCancel: _cancelAppointment,
                          onStartCall: _startCallFromAppointment,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6E6E73)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF))),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentEntity> appointments;
  final String tabLabel;
  final Set<String> cancellingIds;
  final ValueChanged<AppointmentEntity> onCancel;
  final ValueChanged<AppointmentEntity> onStartCall;

  const _AppointmentList({
    required this.appointments,
    required this.tabLabel,
    required this.cancellingIds,
    required this.onCancel,
    required this.onStartCall,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: Color(0xFFEEF0FF), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_rounded, size: 32, color: Color(0xFF5E5CE6)),
            ),
            const SizedBox(height: 16),
            Text('No $tabLabel Sessions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 6),
            Text(
              tabLabel == 'Upcoming' ? 'Book a session with a therapist' : 'No sessions found',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
            if (tabLabel == 'Upcoming') ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go(RouteNames.userConsult),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Find a Therapist',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: appointments.length,
      itemBuilder: (_, i) => _AppointmentCard(
        appointment: appointments[i],
        isCancelling: cancellingIds.contains(appointments[i].id),
        onCancel: () => onCancel(appointments[i]),
        onStartCall: () => onStartCall(appointments[i]),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final bool isCancelling;
  final VoidCallback onCancel;
  final VoidCallback onStartCall;

  const _AppointmentCard({
    required this.appointment,
    required this.isCancelling,
    required this.onCancel,
    required this.onStartCall,
  });

  @override
  Widget build(BuildContext context) {
    final psychologistName = appointment.psychologistName.trim().isEmpty
        ? 'Psychologist'
        : appointment.psychologistName;
    final specialization = appointment.sessionType == SessionType.video
        ? 'Video Therapist'
        : appointment.sessionType == SessionType.audio
            ? 'Audio Therapist'
            : 'Chat Therapist';
    final isActive = appointment.status == AppointmentStatus.ongoing;
    final isUpcoming = appointment.status == AppointmentStatus.upcoming;
    final dt = appointment.scheduledAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active banner
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30D158)]),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('Session in progress', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: appointment.psychologistAvatar != null
                            ? CachedNetworkImage(
                                imageUrl: appointment.psychologistAvatar!,
                                width: 52, height: 52,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _SmallAvatarFallback(psychologistName),
                              )
                            : _SmallAvatarFallback(psychologistName),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(psychologistName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                            Text(specialization,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF8E8E93)),
                                const SizedBox(width: 3),
                                Text(
                                  '${dt.day}/${dt.month}/${dt.year} • ${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBg(appointment.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(appointment.status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(appointment.status)),
                        ),
                      ),
                    ],
                  ),
                  // Session type chip
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              appointment.sessionType == SessionType.video
                                  ? Icons.videocam_rounded
                                  : appointment.sessionType == SessionType.audio
                                      ? Icons.phone_rounded
                                      : Icons.chat_rounded,
                              size: 13, color: const Color(0xFF5E5CE6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.sessionType == SessionType.video
                                  ? 'Video'
                                  : appointment.sessionType == SessionType.audio
                                      ? 'Audio'
                                      : 'Chat',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5E5CE6)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${appointment.durationMinutes} min',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                  // Action buttons for active/upcoming
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onStartCall,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34C759), Color(0xFF30D158)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Enter Call',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (isUpcoming) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onStartCall,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD4FF)),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFEEF0FF),
                              ),
                              child: const Text(
                                'Join Call',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5E5CE6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: isCancelling ? null : onCancel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isCancelling
                                      ? const Color(0xFFFFE0E0).withOpacity(0.6)
                                      : const Color(0xFFFFE0E0),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCancelling ? 'Cancelling...' : 'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCancelling
                                      ? const Color(0xFFFF3B30).withOpacity(0.5)
                                      : const Color(0xFFFF3B30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return 'Upcoming';
      case AppointmentStatus.ongoing: return 'In Progress';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.cancelled: return 'Cancelled';
      case AppointmentStatus.noShow: return 'No Show';
    }
  }

  Color _statusBg(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return const Color(0xFFEEF0FF);
      case AppointmentStatus.ongoing: return const Color(0xFFE8FFF1);
      case AppointmentStatus.completed: return const Color(0xFFF2F2F7);
      case AppointmentStatus.cancelled: return const Color(0xFFFFEEEE);
      case AppointmentStatus.noShow: return const Color(0xFFFFF8ED);
    }
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return const Color(0xFF5E5CE6);
      case AppointmentStatus.ongoing: return const Color(0xFF34C759);
      case AppointmentStatus.completed: return const Color(0xFF8E8E93);
      case AppointmentStatus.cancelled: return const Color(0xFFFF3B30);
      case AppointmentStatus.noShow: return const Color(0xFFFF9500);
    }
  }
}

class _SmallAvatarFallback extends StatelessWidget {
  final String name;
  const _SmallAvatarFallback(this.name);

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((p) => p[0]).join().toUpperCase();
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)),
      child: Center(child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5E5CE6)))),
    );
  }
}


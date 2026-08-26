import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../psychologist/data/models/psychologist_models.dart';
import '../../../../psychologist/data/repositories/psychologist_repository.dart';
import '../../../../user/appointments/data/repositories/appointment_repository.dart';
import '../../../../../core/widgets/app_drawer.dart';
import '../../../../shared/walkthrough/presentation/walkthrough_coach.dart';
import '../../../../shared/walkthrough/tours/app_tours.dart';
import '../../../../shared/walkthrough/walkthrough_keys.dart';
import '../../../shared/psych_ui.dart';

class PsychDashboardPage extends StatefulWidget {
  const PsychDashboardPage({super.key});

  @override
  State<PsychDashboardPage> createState() => _PsychDashboardPageState();
}

class _PsychDashboardPageState extends State<PsychDashboardPage> {
  late final PsychologistRepository _psychologistRepository;
  late final AppointmentRepository _appointmentRepository;

  bool _isOnline = true;
  bool _loading = true;
  String? _errorMessage;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PsychologistEntity? _psychologist;
  List<AppointmentEntity> _sessions = const <AppointmentEntity>[];

  /// Guards the first-run tour against a second launch on refresh.
  bool _walkthroughRequested = false;

  @override
  void initState() {
    super.initState();
    _psychologistRepository = sl<PsychologistRepository>();
    _appointmentRepository = sl<AppointmentRepository>();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final errors = <String>[];

    // Load psychologist profile independently
    try {
      final psychModel = await _psychologistRepository.getMyProfile();
      if (mounted) {
        setState(() {
          _psychologist = psychModel.toEntity();
          _isOnline = _psychologist!.status == AvailabilityStatus.available;
        });
      }
    } catch (e) {
      debugPrint('[MindZep] PsychDashboard profile error: $e');
      errors.add('Profile: $e');
    }

    // Load appointments independently — profile still shows if this fails
    try {
      final appointments = await _appointmentRepository.listAppointments(
        page: 1,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _sessions =
              appointments.items.map((item) => item.toEntity()).toList();
        });
      }
    } catch (e) {
      debugPrint('[MindZep] PsychDashboard appointments error: $e');
      errors.add('Sessions: $e');
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorMessage = errors.isEmpty ? null : errors.join('\n');
    });

    _maybeStartWalkthrough();
  }

  /// Runs the guided tour once, the first time a psychologist opens their
  /// dashboard. Fired after loading so every highlighted card is laid out.
  void _maybeStartWalkthrough() {
    if (_walkthroughRequested) return;
    _walkthroughRequested = true;

    WalkthroughCoach.startIfFirstTime(
      context,
      tourId: TourIds.psychDashboard,
      steps: AppTours.psychDashboard(),
      accentColor: AppTours.psychAccent,
      secondaryColor: AppTours.psychSecondary,
    );
  }

  Future<void> _toggleOnlineStatus() async {
    final next = !_isOnline;
    setState(() {
      _isOnline = next;
    });

    try {
      await _psychologistRepository.updateAvailability(
        AvailabilityUpdateRequest(status: next ? 'available' : 'offline'),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOnline = !next;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final psych = _psychologist ?? _fallbackPsych();
    final sessions = _sessions;
    final upcoming = sessions
        .where((s) => s.status == AppointmentStatus.upcoming)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final now = DateTime.now();
    final today = sessions.where((s) {
      return s.scheduledAt.year == now.year &&
          s.scheduledAt.month == now.month &&
          s.scheduledAt.day == now.day;
    }).toList();

    final weeklyData = _buildWeeklyData(sessions);
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final totalWeekSessions = weeklyData.reduce((a, b) => a + b).toInt();
    final previousWeekSessions = _countPreviousWeekSessions(sessions);
    final growthPct = _computeWeekGrowth(
      currentWeekSessions: totalWeekSessions,
      previousWeekSessions: previousWeekSessions,
    );
    final isGrowthPositive = growthPct >= 0;
    final todayMinutes =
        today.fold<int>(0, (sum, item) => sum + item.durationMinutes);

    return PsychScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const AppPsychDrawer(),
      body: RefreshIndicator(
        color: PsychPalette.teal,
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(psych, today, todayMinutes),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PsychFadeIn(
                      child: Row(
                        key: WalkthroughKeys.psychQuickActions,
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Add Slot',
                            sublabel: 'Set availability',
                            color: PsychPalette.teal,
                            onTap: () => context.go(RouteNames.psychSlots),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.edit_note_rounded,
                            label: 'Write Blog',
                            sublabel: 'Share insights',
                            color: PsychPalette.tealLight,
                            onTap: () => context.go(RouteNames.psychBlogs),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PsychFadeIn(
                      delayMs: 60,
                      child: _WeekCard(
                        weeklyData: weeklyData,
                        weekDays: weekDays,
                        totalWeekSessions: totalWeekSessions,
                        growthPct: growthPct,
                        isGrowthPositive: isGrowthPositive,
                      ),
                    ),
                    const SizedBox(height: 14),
                    PsychFadeIn(
                      delayMs: 100,
                      child: _OnlineStatusCard(
                        key: WalkthroughKeys.psychAvailability,
                        isOnline: _isOnline,
                        onToggle: _toggleOnlineStatus,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PsychSectionTitle(
                      title: 'Upcoming Sessions',
                      actionLabel: 'See all',
                      onAction: () => context.go(RouteNames.psychSessions),
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      const PsychCard(
                        child: PsychEmptyState(
                          icon: Icons.calendar_today_rounded,
                          title: 'No upcoming sessions',
                          subtitle: 'Your schedule looks clear for now.',
                        ),
                      )
                    else
                      ...upcoming.take(4).map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SessionCard(session: s),
                            ),
                          ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _BottomStatCard(
                            icon: Icons.video_camera_front_rounded,
                            iconColor: PsychPalette.teal,
                            bgColor: PsychPalette.tealMist,
                            label: 'Total Sessions',
                            value:
                                '${psych.totalSessions > 0 ? psych.totalSessions : sessions.length}',
                            badge: '$totalWeekSessions this week',
                            badgeColor: PsychPalette.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BottomStatCard(
                            icon: Icons.star_rounded,
                            iconColor: PsychPalette.warning,
                            bgColor: const Color(0xFFFFF6E6),
                            label: 'Avg Rating',
                            value: psych.ratingAverage.toStringAsFixed(1),
                            badge: '${psych.totalReviews} reviews',
                            badgeColor: PsychPalette.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    PsychologistEntity psych,
    List<AppointmentEntity> today,
    int todayMinutes,
  ) {
    return PsychGradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          Row(
            children: [
              PsychGlassIconButton(
                key: WalkthroughKeys.psychMenu,
                icon: Icons.menu_rounded,
                size: 40,
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      psych.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PsychGlassIconButton(
                icon: Icons.notifications_none_rounded,
                size: 40,
                onTap: () => context.push(RouteNames.psychNotifications),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.go(RouteNames.psychProfile),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: AppAvatar(
                      imageUrl: psych.avatarUrl,
                      radius: 20,
                      initials: _initials(psych.name),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some data could not be refreshed. Pull to retry.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              PsychGlassStat(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0x33FFFFFF),
                value: '${today.length}',
                label: 'Sessions Today',
              ),
              const SizedBox(width: 10),
              PsychGlassStat(
                icon: Icons.star_rounded,
                iconColor: const Color(0x33FFFFFF),
                value: psych.ratingAverage.toStringAsFixed(1),
                label: 'Avg Rating',
              ),
              const SizedBox(width: 10),
              PsychGlassStat(
                icon: Icons.reviews_rounded,
                iconColor: const Color(0x33FFFFFF),
                value: '${psych.totalReviews}',
                label: 'Total Reviews',
              ),
              const SizedBox(width: 10),
              PsychGlassStat(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0x33FFFFFF),
                value: _formatHours(todayMinutes),
                label: 'Hours Today',
              ),
            ],
          ),
        ],
      ),
    );
  }

  PsychologistEntity _fallbackPsych() => PsychologistEntity(
        id: 'me',
        name: 'Psychologist',
        credentials: '-',
        specialization: 'General',
        specializations: const <String>['General'],
        languages: const <String>['English'],
        yearsExperience: 0,
        ratingAverage: 0,
        totalReviews: 0,
        totalSessions: 0,
        ratePerMinute: 0,
        freeMinutes: 2,
        status: AvailabilityStatus.offline,
        avatarUrl: null,
        bio: null,
        isApproved: true,
        isActive: true,
        createdAt: DateTime.now(),
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  List<double> _buildWeeklyData(List<AppointmentEntity> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final values = List<double>.filled(7, 0);

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.scheduledAt.year,
        session.scheduledAt.month,
        session.scheduledAt.day,
      );
      if (sessionDate.isBefore(monday) ||
          sessionDate.isAfter(monday.add(const Duration(days: 6)))) {
        continue;
      }
      final index = sessionDate.weekday - 1;
      if (index >= 0 && index < 7) {
        values[index] += 1;
      }
    }
    return values;
  }

  int _countPreviousWeekSessions(List<AppointmentEntity> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final previousMonday = currentMonday.subtract(const Duration(days: 7));
    final previousSunday = previousMonday.add(const Duration(days: 6));

    return sessions.where((session) {
      final date = DateTime(
        session.scheduledAt.year,
        session.scheduledAt.month,
        session.scheduledAt.day,
      );
      return !date.isBefore(previousMonday) && !date.isAfter(previousSunday);
    }).length;
  }

  double _computeWeekGrowth({
    required int currentWeekSessions,
    required int previousWeekSessions,
  }) {
    if (previousWeekSessions == 0) {
      return currentWeekSessions == 0 ? 0 : 100;
    }
    return ((currentWeekSessions - previousWeekSessions) /
            previousWeekSessions) *
        100;
  }

  String _formatHours(int totalMinutes) {
    final hours = totalMinutes / 60;
    if (hours == hours.roundToDouble()) {
      return '${hours.toStringAsFixed(0)}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}

// ── This-week chart card ────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final List<double> weeklyData;
  final List<String> weekDays;
  final int totalWeekSessions;
  final double growthPct;
  final bool isGrowthPositive;

  const _WeekCard({
    required this.weeklyData,
    required this.weekDays,
    required this.totalWeekSessions,
    required this.growthPct,
    required this.isGrowthPositive,
  });

  @override
  Widget build(BuildContext context) {
    final growthColor =
        isGrowthPositive ? PsychPalette.success : PsychPalette.danger;
    return PsychCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 13,
                      color: PsychPalette.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalWeekSessions sessions',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: PsychPalette.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: growthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(PsychRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGrowthPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: growthColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${isGrowthPositive ? '+' : ''}${growthPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: growthColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 84,
            child: _WeeklyChart(data: weeklyData, days: weekDays),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> data;
  final List<String> days;
  const _WeeklyChart({required this.data, required this.days});

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  size: Size(constraints.maxWidth, double.infinity),
                  painter: _BarChartPainter(
                    data: data,
                    progress: t,
                    highlightIndex: todayIndex,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(days.length, (i) {
                final isToday = i == todayIndex;
                return Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday ? PsychPalette.tealDeep : PsychPalette.inkFaint,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final int highlightIndex;
  const _BarChartPainter({
    required this.data,
    required this.progress,
    required this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final max = data.fold<double>(0, (a, b) => a > b ? a : b);
    final count = data.length;
    final barWidth = size.width / count * 0.42;
    final gap = size.width / count;

    for (int i = 0; i < count; i++) {
      final normalized = max <= 0 ? 0.0 : data[i] / max;
      final barHeight = normalized * size.height * progress;
      final x = gap * i + (gap - barWidth) / 2;
      final y = size.height - barHeight;

      // Background track
      final bgPaint = Paint()..color = const Color(0xFFEFF3F5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          const Radius.circular(7),
        ),
        bgPaint,
      );

      if (barHeight <= 0) continue;

      final isHighlight = i == highlightIndex;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: isHighlight
              ? const [Color(0xFF1B9FB4), Color(0xFF38CBA6)]
              : [
                  PsychPalette.teal.withValues(alpha: 0.85),
                  PsychPalette.tealLight.withValues(alpha: 0.85),
                ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(7),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.data != data || old.progress != progress;
}

// ── Quick action ────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PsychCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: PsychPalette.ink,
                    ),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PsychPalette.inkSoft,
                      ),
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

// ── Online status card ──────────────────────────────────────────────────────

class _OnlineStatusCard extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;
  const _OnlineStatusCard({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return PsychCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isOnline
                  ? PsychPalette.brandGradient
                  : const LinearGradient(
                      colors: [Color(0xFFB8C0C6), Color(0xFFD2D9DE)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isOnline ? PsychShadows.glow(PsychPalette.teal) : null,
            ),
            child: Icon(
              isOnline
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_tethering_off_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? PsychPalette.success
                            : PsychPalette.inkFaint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? "You're Online" : "You're Offline",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color:
                            isOnline ? PsychPalette.ink : PsychPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Patients can book sessions'
                      : 'You appear offline to patients',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PsychPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: isOnline ? PsychPalette.brandGradient : null,
                color: isOnline ? null : const Color(0xFFD2D9DE),
                borderRadius: BorderRadius.circular(PsychRadii.pill),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment:
                    isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming session card ───────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final AppointmentEntity session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dt = session.scheduledAt;
    final isVideo = session.sessionType == SessionType.video;

    return PsychCard(
      onTap: () => context.go(RouteNames.psychSessions),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PsychPalette.tealMist, PsychPalette.tealMistStrong],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _initials(session.userName),
                style: const TextStyle(
                  fontSize: 17,
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
                  session.userName.trim().isEmpty
                      ? 'Patient'
                      : session.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: PsychPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    PsychStatusPill(
                      label: isVideo ? 'Video' : 'Audio',
                      color: isVideo ? PsychPalette.info : PsychPalette.success,
                      icon: isVideo
                          ? Icons.videocam_rounded
                          : Icons.phone_rounded,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: PsychPalette.inkFaint),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${_formatDate(dt)} · ${_hhmm(dt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: PsychPalette.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: PsychPalette.inkFaint, size: 22),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = target.difference(today).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    return '${dt.day}/${dt.month}';
  }
}

// ── Bottom stat card ────────────────────────────────────────────────────────

class _BottomStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor;
  final String label, value, badge;
  final Color badgeColor;
  const _BottomStatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return PsychCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: PsychPalette.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: PsychPalette.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PsychRadii.chip),
            ),
            child: Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

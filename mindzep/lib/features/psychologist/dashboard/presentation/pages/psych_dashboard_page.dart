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
          _sessions = appointments.items.map((item) => item.toEntity()).toList();
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
    final psych = _psychologist ??
        PsychologistEntity(
          id: 'me',
          name: 'Psychologist',
          credentials: '-',
          specialization: 'General',
          specializations: <String>['General'],
          languages: <String>['English'],
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
    final sessions = _sessions;
    final upcoming = sessions.where((s) => s.status == AppointmentStatus.upcoming).toList();
    final today = sessions.where((s) {
      final now = DateTime.now();
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
    final todayMinutes = today.fold<int>(0, (sum, item) => sum + item.durationMinutes);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F2F7),
      drawer: const AppPsychDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── Teal Gradient Header ────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196A6), Color(0xFF30B0C7), Color(0xFF34C7A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      // Top row: hamburger + greeting/name + notification bell + avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Hamburger menu
                          GestureDetector(
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  psych.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Notification bell
                          GestureDetector(
                            onTap: () => context.push(RouteNames.userNotifications),
                            child: Container(
                              width: 40, height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF3B30),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Avatar — tap to go to profile
                          GestureDetector(
                            onTap: () => context.go(RouteNames.psychProfile),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                              ),
                              child: ClipOval(
                                child: AppAvatar(
                                  imageUrl: psych.avatarUrl,
                                  radius: 20,
                                  initials: psych.name
                                      .trim()
                                      .split(' ')
                                      .where((part) => part.isNotEmpty)
                                      .take(2)
                                      .map((part) => part[0])
                                      .join()
                                      .toUpperCase(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      // ── 4-stat row ──────────────────────────────────
                      Row(
                        children: [
                          _DashStat(
                            icon: Icons.calendar_today_rounded,
                            value: '${today.length}',
                            label: 'Sessions\nToday',
                            color: const Color(0xFF7EEEDD),
                          ),
                          const SizedBox(width: 8),
                          _DashStat(
                            icon: Icons.star_rounded,
                            value: psych.ratingAverage.toStringAsFixed(1),
                            label: 'Avg\nRating',
                            color: const Color(0xFFFFE083),
                          ),
                          const SizedBox(width: 8),
                          _DashStat(
                            icon: Icons.favorite_rounded,
                            value: '${psych.totalReviews}',
                            label: 'Total\nReviews',
                            color: const Color(0xFFFFB3C6),
                          ),
                          const SizedBox(width: 8),
                          _DashStat(
                            icon: Icons.access_time_rounded,
                            value: _formatHours(todayMinutes),
                            label: 'Hours\nToday',
                            color: const Color(0xFFB8C8FF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body Content ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Actions Row ──────────────────────────
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Add Slot',
                        color: const Color(0xFF30B0C7),
                        onTap: () => context.go(RouteNames.psychSlots),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.article_outlined,
                        label: 'Write Blog',
                        color: const Color(0xFF34C7A3),
                        onTap: () => context.go(RouteNames.psychBlogs),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── This Week Chart Card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'This Week',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalWeekSessions sessions',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isGrowthPositive
                                    ? const Color(0xFFD4F5E9)
                                    : const Color(0xFFFFE8EA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isGrowthPositive
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 12,
                                    color: isGrowthPositive
                                        ? const Color(0xFF1AAA6A)
                                        : const Color(0xFFD93025),
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '${isGrowthPositive ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isGrowthPositive
                                          ? const Color(0xFF1AAA6A)
                                          : const Color(0xFFD93025),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
                          child: _WeeklyChart(data: weeklyData, days: weekDays),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Online Status Card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isOnline
                                  ? [const Color(0xFF30B0C7), const Color(0xFF34C7A3)]
                                  : [const Color(0xFFAAAAAA), const Color(0xFFCCCCCC)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            _isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                            color: Colors.white, size: 22,
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
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: _isOnline ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnline ? "You're Online" : "You're Offline",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _isOnline ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _isOnline ? 'Patients can book sessions' : 'You appear offline to patients',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleOnlineStatus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isOnline
                                    ? [const Color(0xFF30B0C7), const Color(0xFF34C7A3)]
                                    : [const Color(0xFFAAAAAA), const Color(0xFFCCCCCC)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isOnline ? 'Manage' : 'Go Online',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Upcoming Sessions ─────────────────────────────
                  _SectionHeader(
                    title: 'Upcoming Sessions',
                    actionLabel: 'All >',
                    onAction: () => context.go(RouteNames.psychSessions),
                  ),
                  const SizedBox(height: 12),
                  if (upcoming.isEmpty)
                    _EmptyBox(
                      icon: Icons.calendar_today_rounded,
                      title: 'No upcoming sessions',
                      subtitle: 'Your schedule looks clear for now',
                    )
                  else
                    ...upcoming.take(4).map((s) => _SessionCard(session: s)),
                  const SizedBox(height: 20),

                  // ── Bottom Stats Row ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _BottomStatCard(
                          icon: Icons.video_camera_front_rounded,
                          iconColor: const Color(0xFF30B0C7),
                          bgColor: const Color(0xFFE8F8FB),
                          label: 'Total Sessions',
                          value: '${psych.totalSessions > 0 ? psych.totalSessions : sessions.length}',
                          badge: '$totalWeekSessions this week',
                          badgeColor: const Color(0xFF30B0C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BottomStatCard(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFF9500),
                          bgColor: const Color(0xFFFFF8ED),
                          label: 'Avg Rating',
                          value: psych.ratingAverage.toStringAsFixed(1),
                          badge: '${psych.totalReviews} reviews',
                          badgeColor: const Color(0xFFFF9500),
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
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
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
    return ((currentWeekSessions - previousWeekSessions) / previousWeekSessions) * 100;
  }

  String _formatHours(int totalMinutes) {
    final hours = totalMinutes / 60;
    if (hours == hours.roundToDouble()) {
      return '${hours.toStringAsFixed(0)}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}

// ── Weekly Chart ──────────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final List<double> data;
  final List<String> days;
  const _WeeklyChart({required this.data, required this.days});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size(constraints.maxWidth, double.infinity),
                painter: _BarChartPainter(data: data),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((d) => Text(
                d,
                style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
              )).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  const _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final max = data.fold<double>(0, (a, b) => a > b ? a : b);
    final count = data.length;
    final barWidth = size.width / count * 0.45;
    final gap = size.width / count;

    for (int i = 0; i < count; i++) {
      final normalized = max <= 0 ? 0 : data[i] / max;
      final barHeight = normalized * size.height;
      final x = gap * i + (gap - barWidth) / 2;
      final y = size.height - barHeight;

      // Background bar
      final bgPaint = Paint()
        ..color = const Color(0xFFF0F0F5)
        ..style = PaintingStyle.fill;
      final bgRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, size.height),
        const Radius.circular(6),
      );
      canvas.drawRRect(bgRRect, bgPaint);

      // Colored bar with gradient
      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight))
        ..style = PaintingStyle.fill;

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rRect, paint);

      // Highlight the tallest bar
      if (max > 0 && data[i] == max) {
        final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x + barWidth / 2, y + 5), 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.data != data;
}

// ── Quick Action Widget ───────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Widgets ──────────────────────────────────────────────────────────────

class _DashStat extends StatelessWidget {  final IconData icon;
  final String value, label;
  final Color color;
  const _DashStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.9), shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xCCFFFFFF), height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30B0C7)),
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AppointmentEntity session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dt = session.scheduledAt;
    final isVideo = session.sessionType == SessionType.video;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F8FB), Color(0xFFD0F5F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                session.userName.trim().split(' ').take(2)
                    .map((p) => p[0]).join().toUpperCase(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF30B0C7)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.userName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 2),
                // Session type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isVideo ? const Color(0xFFE8F0FF) : const Color(0xFFE8FBF0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isVideo ? 'Video Call' : 'Audio Call',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isVideo ? const Color(0xFF3B6CF8) : const Color(0xFF28A745),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Time row
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(dt)} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${session.durationMinutes}m',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action button
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                color: Colors.white, size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

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

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyBox({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF30B0C7), size: 26),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3C3C3C))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../admin/data/repositories/admin_repository.dart';
import '../../../../user/blog/data/repositories/blog_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminRepository _adminRepository;
  late final BlogRepository _blogRepository;

  bool _loading = true;
  Map<String, dynamic> _metrics = <String, dynamic>{};
  List<Map<String, dynamic>> _revenue = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _recentPsychologists =
      const <Map<String, dynamic>>[];
  int _pendingPsychologistCount = 0;
  int _pendingBlogCount = 0;

  @override
  void initState() {
    super.initState();
    _adminRepository = sl<AdminRepository>();
    _blogRepository = sl<BlogRepository>();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
    });

    try {
      final dashboard = await _adminRepository.dashboard();
      final psychologists = await _adminRepository.listPsychologists(
        page: 1,
        limit: 20,
      );
      final submittedBlogs = await _blogRepository.listAdminSubmittedBlogs(
        page: 1,
        limit: 50,
      );

      final metrics = _asMap(dashboard['metrics']);
      final chartData = _asMapList(dashboard['chartData']);

      final revenue = chartData
          .map((point) {
            final day = (point['day'] ?? point['date'] ?? '').toString();
            final amount = (point['amount'] ?? point['revenue'] ?? 0) as num;
            return {
              'day': day.length >= 3 ? day.substring(0, 3) : day,
              'amount': amount.toDouble(),
            };
          })
          .where((point) => point['day']!.toString().isNotEmpty)
          .toList();

      final psychList = psychologists.map(_asMap).toList();
      final pendingPsychologists = psychList
          .where((psych) => !_readBool(psych, ['isActive', 'active'], fallback: true))
          .length;

      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _revenue = revenue;
        _recentPsychologists = psychList.take(3).toList();
        _pendingPsychologistCount = pendingPsychologists;
        _pendingBlogCount = submittedBlogs.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _metrics = <String, dynamic>{};
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value.map((entry) => _asMap(entry)).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  bool _readBool(
    Map<String, dynamic> json,
    List<String> keys, {
    required bool fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      if (value is num) return value != 0;
    }
    return fallback;
  }

  int _metricInt(String key) {
    final value = _metrics[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _metricDouble(List<String> keys) {
    for (final key in keys) {
      final value = _metrics[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final totalUsers = _metricInt('totalUsers');
    final activePsychologists = _metricInt('activePsychologists');
    final sessionsToday = _metricInt('sessionsToday');
    final revenueThisMonth = _metricDouble(
      const ['revenueThisMonth', 'totalRevenue', 'revenueToday'],
    );
    final revenuePoints = _revenue.isNotEmpty
        ? _revenue
        : const <Map<String, dynamic>>[
            {'day': 'Mon', 'amount': 0.0},
            {'day': 'Tue', 'amount': 0.0},
            {'day': 'Wed', 'amount': 0.0},
            {'day': 'Thu', 'amount': 0.0},
            {'day': 'Fri', 'amount': 0.0},
            {'day': 'Sat', 'amount': 0.0},
            {'day': 'Sun', 'amount': 0.0},
          ];

    final totalAlerts = _pendingPsychologistCount + _pendingBlogCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Panel',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                'MindZep Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22),
                              ),
                              if (totalAlerts > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1C1C1E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$totalAlerts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.85,
                        children: [
                          _StatCard(
                            icon: Icons.people_rounded,
                            iconColor: const Color(0xFFADB5FF),
                            label: 'Total Users',
                            value: '$totalUsers',
                          ),
                          _StatCard(
                            icon: Icons.psychology_rounded,
                            iconColor: const Color(0xFF34C7A3),
                            label: 'Psychologists',
                            value: '$activePsychologists',
                          ),
                          _StatCard(
                            icon: Icons.video_call_rounded,
                            iconColor: const Color(0xFFFFD93D),
                            label: "Today's Sessions",
                            value: '$sessionsToday',
                          ),
                          _StatCard(
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFFA8E6CF),
                            label: 'Revenue',
                            value:
                                '₹${(revenueThisMonth / 1000).toStringAsFixed(0)}K',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.paddingM),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                // Pending alerts
                if (_pendingPsychologistCount > 0) ...[
                  _PendingAlert(
                    count: _pendingPsychologistCount,
                    label: 'Therapists awaiting approval',
                    icon: Icons.psychology_rounded,
                    color: AppColors.warning,
                    onTap: () =>
                        context.go(RouteNames.adminPsychologists),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                ],
                if (_pendingBlogCount > 0) ...[
                  _PendingAlert(
                    count: _pendingBlogCount,
                    label: 'Blog posts awaiting review',
                    icon: Icons.article_rounded,
                    color: const Color(0xFF30B0C7),
                    onTap: () => context.go(RouteNames.adminBlogs),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                ],
                if (_pendingPsychologistCount == 0 && _pendingBlogCount == 0)
                  const SizedBox(height: AppDimensions.paddingS),

                // Revenue Chart
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Revenue',
                                  style: AppTextStyles.caption1.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                                Text(
                                  '₹${(revenueThisMonth / 1000).toStringAsFixed(1)}K',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      SizedBox(
                        height: 110,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => const FlLine(
                                color: Color(0x15000000),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= revenuePoints.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      revenuePoints[idx]['day'] as String? ?? '',
                                      style: AppTextStyles.caption2.copyWith(
                                          color: AppColors.textSecondary),
                                    );
                                  },
                                  reservedSize: 22,
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: revenuePoints
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                      (revenuePoints[e.key]['amount'] as num)
                                        .toDouble(),
                                        ))
                                    .toList(),
                                isCurved: true,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8E53)
                                  ],
                                ),
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF6B6B).withOpacity(0.18),
                                      const Color(0xFFFF6B6B).withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Quick Actions
                Row(
                  children: [
                    Container(
                      width: 4, height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Quick Actions',
                        style: AppTextStyles.headline
                            .copyWith(color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Row(
                  children: [
                    _QuickAction(
                      label: 'Approve\nTherapist',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      bgColor: AppColors.success.withOpacity(0.1),
                      onTap: () =>
                          context.go(RouteNames.adminPsychologists),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    _QuickAction(
                      label: 'Review\nBlogs',
                      icon: Icons.article_rounded,
                      color: const Color(0xFF30B0C7),
                      bgColor: const Color(0xFF30B0C7).withOpacity(0.1),
                      onTap: () => context.go(RouteNames.adminBlogs),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    _QuickAction(
                      label: 'Manage\nUsers',
                      icon: Icons.people_rounded,
                      color: AppColors.primary,
                      bgColor: AppColors.primary.withOpacity(0.1),
                      onTap: () => context.go(RouteNames.adminUsers),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Recent Psychologists
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4, height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Recent Psychologists',
                            style: AppTextStyles.headline
                                .copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go(RouteNames.adminUsers),
                      child: Text(
                        'See All',
                        style: AppTextStyles.footnote
                            .copyWith(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ..._recentPsychologists.map(
                      (u) => AppCard(
                        margin: const EdgeInsets.only(
                            bottom: AppDimensions.paddingS),
                        child: Row(
                          children: [
                            AppAvatar(
                              imageUrl: (u['user']['avatarUrl'] ??
                                      u['avatar'] ??
                                      u['profilePicture'])
                                  ?.toString(),
                              radius: 20,
                              initials: ((u['user']['name'] ?? 'U').toString()[0]),
                            ),
                            const SizedBox(width: AppDimensions.paddingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((u['user']['name'] ?? 'Psychologist').toString(),
                                      style: AppTextStyles.subheadline
                                          .copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text((u['user']['email'] ?? '-').toString(),
                                      style: AppTextStyles.caption1.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            _StatusPill(
                              label: _readBool(u, ['isActive', 'active'], fallback: true)
                                  ? 'Active'
                                  : 'Suspended',
                              color: _readBool(u, ['isActive', 'active'], fallback: true)
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card (inside gradient) ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pending Alert Banner ─────────────────────────────────────────────────────

class _PendingAlert extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PendingAlert({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.14), color.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Pending',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: color.withOpacity(0.75))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Tile ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption1
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Pill ─────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption1
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

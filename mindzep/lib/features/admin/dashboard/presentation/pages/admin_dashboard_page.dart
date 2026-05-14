import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final metrics = MockData.dashboardMetrics;
    final revenue = MockData.revenueData;
    final pendingPsychs = MockData.pendingPsychologists;
    final pendingBlogs =
        MockData.blogs.where((b) => b.status == BlogStatus.underReview).toList();
    final totalAlerts = pendingPsychs.length + pendingBlogs.length;

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
                            value: '${metrics['totalUsers']}',
                          ),
                          _StatCard(
                            icon: Icons.psychology_rounded,
                            iconColor: const Color(0xFF34C7A3),
                            label: 'Psychologists',
                            value: '${metrics['activePsychologists']}',
                          ),
                          _StatCard(
                            icon: Icons.video_call_rounded,
                            iconColor: const Color(0xFFFFD93D),
                            label: "Today's Sessions",
                            value: '${metrics['sessionsToday']}',
                          ),
                          _StatCard(
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFFA8E6CF),
                            label: 'Revenue',
                            value:
                                '₹${((metrics['revenueThisMonth'] as double) / 1000).toStringAsFixed(0)}K',
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
                // Pending alerts
                if (pendingPsychs.isNotEmpty) ...[
                  _PendingAlert(
                    count: pendingPsychs.length,
                    label: 'Therapists awaiting approval',
                    icon: Icons.psychology_rounded,
                    color: AppColors.warning,
                    onTap: () =>
                        context.go(RouteNames.adminPsychologists),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                ],
                if (pendingBlogs.isNotEmpty) ...[
                  _PendingAlert(
                    count: pendingBlogs.length,
                    label: 'Blog posts awaiting review',
                    icon: Icons.article_rounded,
                    color: const Color(0xFF30B0C7),
                    onTap: () => context.go(RouteNames.adminBlogs),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                ],
                if (pendingPsychs.isEmpty && pendingBlogs.isEmpty)
                  const SizedBox(height: AppDimensions.paddingS),

                // Revenue Chart
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  '₹${((metrics['revenueThisMonth'] as double) / 1000).toStringAsFixed(1)}K',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up_rounded,
                                    size: 14, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  '+11.9%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      SizedBox(
                        height: 100,
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
                                    if (idx < 0 || idx >= revenue.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      revenue[idx]['day'] as String? ?? '',
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
                                spots: revenue
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          (e.value['amount'] as num).toDouble(),
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
                Text('Quick Actions',
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.textPrimary)),
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

                // Today's Activity
                Text("Today's Activity",
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppDimensions.paddingS),
                AppCard(
                  child: Column(
                    children: [
                      _ActivityRow(
                          label: 'Active Users',
                          value: '1,240',
                          change: '+45',
                          up: true),
                      const Divider(
                          height: 1, color: AppColors.surfaceSecondary),
                      _ActivityRow(
                          label: 'Sessions Today',
                          value: '${metrics['sessionsToday']}',
                          change: '+12',
                          up: true),
                      const Divider(
                          height: 1, color: AppColors.surfaceSecondary),
                      _ActivityRow(
                          label: 'New Signups',
                          value: '28',
                          change: '+8',
                          up: true),
                      const Divider(
                          height: 1, color: AppColors.surfaceSecondary),
                      _ActivityRow(
                          label: 'Revenue Today',
                          value: '₹14.8K',
                          change: '+5%',
                          up: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Recent Users
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Users',
                        style: AppTextStyles.headline
                            .copyWith(color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.go(RouteNames.adminUsers),
                      child: Text(
                        'See All',
                        style: AppTextStyles.footnote
                            .copyWith(color: const Color(0xFFFF6B6B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...MockData.adminUsers.take(3).map(
                      (u) => AppCard(
                        margin: const EdgeInsets.only(
                            bottom: AppDimensions.paddingS),
                        child: Row(
                          children: [
                            AppAvatar(
                              imageUrl: u.avatarUrl,
                              radius: 20,
                              initials: u.name[0],
                            ),
                            const SizedBox(width: AppDimensions.paddingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name,
                                      style: AppTextStyles.subheadline
                                          .copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text(u.email,
                                      style: AppTextStyles.caption1.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            _StatusPill(
                              label: u.isActive ? 'Active' : 'Suspended',
                              color: u.isActive
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
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption1
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity Row ─────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool up;

  const _ActivityRow({
    required this.label,
    required this.value,
    required this.change,
    required this.up,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.subheadline)),
          Text(value,
              style: AppTextStyles.subheadline
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: up
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              change,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: up ? AppColors.success : AppColors.error),
            ),
          ),
        ],
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

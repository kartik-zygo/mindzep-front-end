import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_avatar.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = MockData.dashboardMetrics;
    final revenue = MockData.revenueData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // Metric cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimensions.paddingS,
            crossAxisSpacing: AppDimensions.paddingS,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(
                  label: 'Total Users',
                  value: '${metrics['totalUsers']}',
                  icon: Icons.people_rounded,
                  color: AppColors.primary),
              _MetricCard(
                  label: 'Psychologists',
                  value: '${metrics['totalPsychologists']}',
                  icon: Icons.psychology_rounded,
                  color: AppColors.info),
              _MetricCard(
                  label: 'Today\'s Sessions',
                  value: '${metrics['todaySessions']}',
                  icon: Icons.video_call_rounded,
                  color: AppColors.success),
              _MetricCard(
                  label: 'Pending Approvals',
                  value: '${metrics['pendingApprovals']}',
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingL),
          // Revenue chart
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue (Last 7 Days)',
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppDimensions.paddingM),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(
                              revenue[v.toInt()]['day'] as String? ?? '',
                              style: AppTextStyles.caption2.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            reservedSize: 22,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(
                              '₹${v.toInt()}',
                              style: AppTextStyles.caption2.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            reservedSize: 36,
                          ),
                        ),
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
                          color: AppColors.primary,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          // Recent users
          Text('Recent Users',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingS),
          ...MockData.adminUsers.take(3).map((u) => AppCard(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: u.isActive
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull),
                      ),
                      child: Text(
                        u.isActive ? 'Active' : 'Suspended',
                        style: AppTextStyles.caption1.copyWith(
                          color: u.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.title3
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(label,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

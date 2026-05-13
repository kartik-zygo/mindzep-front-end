import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';

class PsychologistDetailPage extends StatefulWidget {
  final PsychologistEntity psychologist;

  const PsychologistDetailPage({super.key, required this.psychologist});

  @override
  State<PsychologistDetailPage> createState() =>
      _PsychologistDetailPageState();
}

class _PsychologistDetailPageState extends State<PsychologistDetailPage>
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

  PsychologistEntity get p => widget.psychologist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeader(context),
              _buildInfoSection(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 16,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(Icons.share_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Avatar or hero image
            p.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: p.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        _initials(p.name),
                        style: AppTextStyles.largeTitle
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // Name + status at bottom
            Positioned(
              left: AppDimensions.paddingM,
              right: AppDimensions.paddingM,
              bottom: AppDimensions.paddingM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name,
                            style: AppTextStyles.title2
                                .copyWith(color: Colors.white)),
                      ),
                      _StatusChip(status: p.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p.specialization,
                      style: AppTextStyles.subheadline
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildInfoSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _StatCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFFB300),
                    value: p.ratingAverage.toStringAsFixed(1),
                    label: 'Rating'),
                _StatCard(
                    icon: Icons.work_outline_rounded,
                    iconColor: AppColors.primary,
                    value: '${p.yearsExperience}y',
                    label: 'Experience'),
                _StatCard(
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.info,
                    value: '${p.totalReviews}',
                    label: 'Reviews'),
                _StatCard(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: AppColors.success,
                    value: '${p.ratePerMinute}/min',
                    label: 'Rate'),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),
            // Specialization tags
            Wrap(
              spacing: AppDimensions.paddingS,
              runSpacing: AppDimensions.paddingS,
              children: p.specializations
                  .map((s) => Chip(
                        label: Text(s),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        labelStyle: AppTextStyles.caption1
                            .copyWith(color: AppColors.primary),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            // Availability
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTabBar() {
    return SliverToBoxAdapter(
      child: TabBar(
        controller: _tabCtrl,
        labelStyle: AppTextStyles.subheadline
            .copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.subheadline,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Reviews'),
          Tab(text: 'Sessions'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: SizedBox(
        height: 400,
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _AboutTab(psychologist: p),
            _ReviewsTab(reviews: MockData.reviews),
            _SessionsTab(psychologist: p),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          AppDimensions.paddingM,
          AppDimensions.paddingM,
          MediaQuery.of(context).padding.bottom + AppDimensions.paddingM,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Book Session',
                style: AppButtonStyle.outlined,
                prefixIcon: Icons.calendar_today_rounded,
                onPressed: () => context.push(
                  RouteNames.slotBooking
                      .replaceAll(':psychologistId', p.id),
                  extra: p,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: AppButton(
                label: AppStrings.callNow,
                prefixIcon: Icons.call_rounded,
                onPressed: p.status == AvailabilityStatus.available
                    ? () => context.push(RouteNames.preCall, extra: p)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: AppDimensions.paddingS),
        padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingM, horizontal: AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.footnote
                    .copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                style: AppTextStyles.caption2
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AvailabilityStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == AvailabilityStatus.available
        ? AppColors.available
        : status == AvailabilityStatus.busy
            ? AppColors.busy
            : AppColors.offline;
    final label = status == AvailabilityStatus.available
        ? 'Online'
        : status == AvailabilityStatus.busy
            ? 'Busy'
            : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTextStyles.caption1.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final PsychologistEntity psychologist;
  const _AboutTab({required this.psychologist});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            psychologist.bio ??
                'Experienced mental health professional specializing in ${psychologist.specialization}. '
                    'Committed to providing a safe, supportive environment for healing and growth.',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text('Languages',
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.paddingS),
          Wrap(
            spacing: AppDimensions.paddingS,
            children: (psychologist.languages ?? ['English', 'Hindi'])
                .map((l) => Chip(
                      label: Text(l),
                      backgroundColor: AppColors.background,
                      labelStyle: AppTextStyles.caption1
                          .copyWith(color: AppColors.textSecondary),
                      side: const BorderSide(color: AppColors.border),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 100), // space for bottom bar
        ],
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final List<ReviewEntity> reviews;
  const _ReviewsTab({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM,
          AppDimensions.paddingM, AppDimensions.paddingM, 100),
      itemCount: reviews.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.paddingS),
      itemBuilder: (_, i) => _ReviewItem(review: reviews[i]),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewEntity review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: null,
                radius: 16,
                initials: review.userName[0].toUpperCase(),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: AppTextStyles.footnote.copyWith(
                            fontWeight: FontWeight.w600)),
                    Row(
                      children: List.generate(
                          5,
                          (j) => Icon(
                                j < review.rating.floor()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 12,
                                color: const Color(0xFFFFB300),
                              )),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTextStyles.caption1
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(review.comment ?? '',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _SessionsTab extends StatelessWidget {
  final PsychologistEntity psychologist;
  const _SessionsTab({required this.psychologist});

  @override
  Widget build(BuildContext context) {
    final types = [
      (
        icon: Icons.videocam_rounded,
        color: AppColors.primary,
        title: 'Video Session',
        subtitle: 'Face-to-face video call',
      ),
      (
        icon: Icons.phone_rounded,
        color: AppColors.info,
        title: 'Audio Session',
        subtitle: 'Voice call only',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM,
          AppDimensions.paddingM, AppDimensions.paddingM, 100),
      child: Column(
        children: types
            .map((t) => AppCard(
                  margin: const EdgeInsets.only(
                      bottom: AppDimensions.paddingS),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: t.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM),
                        ),
                        child: Icon(t.icon, color: t.color, size: 24),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                style: AppTextStyles.subheadline.copyWith(
                                    fontWeight: FontWeight.w600)),
                            Text(t.subtitle,
                                style: AppTextStyles.caption1.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatRatePerMin(
                            psychologist.ratePerMinute),
                        style: AppTextStyles.subheadline.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}


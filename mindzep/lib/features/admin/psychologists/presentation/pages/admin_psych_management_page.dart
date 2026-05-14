import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';

class AdminPsychManagementPage extends StatefulWidget {
  const AdminPsychManagementPage({super.key});

  @override
  State<AdminPsychManagementPage> createState() =>
      _AdminPsychManagementPageState();
}

class _AdminPsychManagementPageState extends State<AdminPsychManagementPage> {
  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _searchCtrl = TextEditingController();
  String _search = '';
  String _activeFilter = 'All';
  String? _expandedId;

  // Combined mutable list: approved + pending
  late List<_PsychItem> _items;

  static const _filters = ['All', 'Pending', 'Approved', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _items = [
      ...MockData.psychologists.map(
        (p) => _PsychItem(psych: p, approvalStatus: 'approved'),
      ),
      ...MockData.pendingPsychologists.map(
        (p) => _PsychItem(psych: p, approvalStatus: 'pending'),
      ),
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_PsychItem> get _filtered {
    return _items.where((item) {
      final matchSearch = _search.isEmpty ||
          item.psych.name.toLowerCase().contains(_search.toLowerCase()) ||
          item.psych.specialization
              .toLowerCase()
              .contains(_search.toLowerCase());
      final matchFilter = switch (_activeFilter) {
        'Pending' => item.approvalStatus == 'pending',
        'Approved' => item.approvalStatus == 'approved',
        'Active' =>
          item.approvalStatus == 'approved' &&
              item.psych.status == AvailabilityStatus.available,
        'Inactive' => item.psych.status == AvailabilityStatus.offline,
        _ => true,
      };
      return matchSearch && matchFilter;
    }).toList();
  }

  int get _pendingCount =>
      _items.where((i) => i.approvalStatus == 'pending').length;

  void _approve(String id) {
    setState(() {
      final idx = _items.indexWhere((i) => i.psych.id == id);
      if (idx != -1) {
        _items[idx] = _PsychItem(
            psych: _items[idx].psych, approvalStatus: 'approved');
      }
    });
    AppSnackbar.show(context,
        message: 'Psychologist approved!', type: SnackbarType.success);
  }

  void _reject(String id) {
    final name =
        _items.firstWhere((i) => i.psych.id == id).psych.name;
    setState(() => _items.removeWhere((i) => i.psych.id == id));
    AppSnackbar.show(context,
        message: '$name has been rejected.', type: SnackbarType.error);
  }

  void _toggleActive(String id) {
    setState(() {
      final idx = _items.indexWhere((i) => i.psych.id == id);
      if (idx != -1) {
        final current = _items[idx].psych;
        final newStatus = current.status == AvailabilityStatus.offline
            ? AvailabilityStatus.available
            : AvailabilityStatus.offline;
        _items[idx] = _PsychItem(
          psych: _rebuildPsych(current, newStatus),
          approvalStatus: _items[idx].approvalStatus,
        );
      }
    });
  }

  static PsychologistEntity _rebuildPsych(
      PsychologistEntity p, AvailabilityStatus status) {
    return PsychologistEntity(
      id: p.id,
      name: p.name,
      credentials: p.credentials,
      specialization: p.specialization,
      specializations: p.specializations,
      languages: p.languages,
      yearsExperience: p.yearsExperience,
      ratingAverage: p.ratingAverage,
      totalReviews: p.totalReviews,
      totalSessions: p.totalSessions,
      ratePerMinute: p.ratePerMinute,
      freeMinutes: p.freeMinutes,
      status: status,
      avatarUrl: p.avatarUrl,
      bio: p.bio,
      isApproved: p.isApproved,
      isActive: status != AvailabilityStatus.offline,
      createdAt: p.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Manage Therapists',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull),
                              ),
                              child: Text(
                                '$_pendingCount pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXL),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) =>
                                    setState(() => _search = v),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search therapists...',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final f = _filters[i];
                            final selected = _activeFilter == f;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _activeFilter = f),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusFull),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: filtered.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingS),
                child: Text(
                  '${filtered.length} therapists',
                  style: AppTextStyles.footnote
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            final item = filtered[i - 1];
            return _PsychCard(
              item: item,
              isExpanded: _expandedId == item.psych.id,
              onTap: () => setState(() => _expandedId =
                  _expandedId == item.psych.id ? null : item.psych.id),
              onApprove: () => _approve(item.psych.id),
              onReject: () => _reject(item.psych.id),
              onToggleActive: () => _toggleActive(item.psych.id),
            );
          },
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _PsychItem {
  final PsychologistEntity psych;
  final String approvalStatus; // 'pending' | 'approved' | 'rejected'

  _PsychItem({required this.psych, required this.approvalStatus});
}

// ─── Psychologist Card ────────────────────────────────────────────────────────

class _PsychCard extends StatelessWidget {
  final _PsychItem item;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onToggleActive;

  const _PsychCard({
    required this.item,
    required this.isExpanded,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.psych;
    final isPending = item.approvalStatus == 'pending';
    final isActive = p.status == AvailabilityStatus.available ||
        p.status == AvailabilityStatus.busy;

    return AppCard(
      margin:
          const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending banner
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withOpacity(0.15),
                    AppColors.warning.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusL),
                  topRight: Radius.circular(AppDimensions.radiusL),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Awaiting Approval',
                    style: AppTextStyles.caption1.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Main card row (tappable)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: p.avatarUrl,
                    radius: 26,
                    availabilityStatus:
                        isPending ? null : p.status,
                    showStatusDot: !isPending,
                    initials: p.name[0],
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: AppTextStyles.subheadline
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(p.specialization,
                            style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ApprovalBadge(status: item.approvalStatus),
                            if (p.ratingAverage > 0) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.star_rounded,
                                  size: 13,
                                  color: Color(0xFFFF9500)),
                              const SizedBox(width: 2),
                              Text(
                                p.ratingAverage.toStringAsFixed(1),
                                style: AppTextStyles.caption1.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (p.totalSessions > 0)
                        Text(
                          '${p.totalSessions}',
                          style: AppTextStyles.subheadline
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      Text('sessions',
                          style: AppTextStyles.caption2
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded section
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.surfaceSecondary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats mini grid
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Sessions',
                          value: '${p.totalSessions}'),
                      _MiniStat(
                          label: 'Experience',
                          value: '${p.yearsExperience}y'),
                      _MiniStat(
                          label: 'Rate',
                          value: '₹${p.ratePerMinute}/min'),
                    ],
                  ),
                  // Credentials & languages
                  if (p.credentials.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(p.credentials,
                        style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                  if (p.bio != null && p.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.bio!,
                      style: AppTextStyles.caption1
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Specializations
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: p.specializations
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              s,
                              style: AppTextStyles.caption2.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  if (isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.error),
                            label: const Text('Reject',
                                style:
                                    TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white),
                            label: const Text('Approve',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onToggleActive,
                            icon: Icon(
                              isActive
                                  ? Icons.power_off_rounded
                                  : Icons.power_settings_new_rounded,
                              size: 16,
                              color: isActive
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                            label: Text(
                              isActive ? 'Suspend' : 'Reactivate',
                              style: TextStyle(
                                  color: isActive
                                      ? AppColors.error
                                      : AppColors.success),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: isActive
                                      ? AppColors.error
                                      : AppColors.success),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
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
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ApprovalBadge extends StatelessWidget {
  final String status;
  const _ApprovalBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (status) {
      'approved' => (AppColors.success.withOpacity(0.12), AppColors.success),
      'pending' => (AppColors.warning.withOpacity(0.12), AppColors.warning),
      _ => (AppColors.error.withOpacity(0.12), AppColors.error),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTextStyles.caption2
            .copyWith(color: text, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.subheadline
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: AppTextStyles.caption2
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

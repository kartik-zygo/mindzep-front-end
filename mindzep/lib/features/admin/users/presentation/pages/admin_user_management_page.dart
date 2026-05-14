import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _searchCtrl = TextEditingController();
  String _search = '';
  String _activeFilter = 'All';
  String? _expandedId;

  late List<UserEntity> _users;

  static const _filters = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _users = List.from(MockData.adminUsers);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserEntity> get _filtered {
    return _users.where((u) {
      final matchSearch = _search.isEmpty ||
          u.name.toLowerCase().contains(_search.toLowerCase()) ||
          u.email.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = switch (_activeFilter) {
        'Active' => u.isActive,
        'Inactive' => !u.isActive,
        _ => true,
      };
      return matchSearch && matchFilter;
    }).toList();
  }

  void _toggleUser(String id) {
    final user = _users.firstWhere((u) => u.id == id);
    final isSuspending = user.isActive;
    setState(() {
      final idx = _users.indexWhere((u) => u.id == id);
      _users[idx] = user.copyWith(isActive: !user.isActive);
    });
    AppSnackbar.show(
      context,
      message: isSuspending
          ? '${user.name} has been suspended.'
          : '${user.name} has been reactivated.',
      type: isSuspending ? SnackbarType.warning : SnackbarType.success,
    );
  }

  int get _activeCount => _users.where((u) => u.isActive).length;

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
                              'Manage Users',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Active / total pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              '$_activeCount/${_users.length} active',
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
                                  hintText: 'Search users...',
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
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: Text(
                  '${filtered.length} users',
                  style: AppTextStyles.footnote
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            final u = filtered[i - 1];
            return _UserCard(
              user: u,
              isExpanded: _expandedId == u.id,
              onTap: () => setState(() =>
                  _expandedId = _expandedId == u.id ? null : u.id),
              onToggle: () => _toggleUser(u.id),
            );
          },
        ),
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserEntity user;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _UserCard({
    required this.user,
    required this.isExpanded,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: u.avatarUrl,
                    radius: 24,
                    initials: u.name[0],
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name,
                            style: AppTextStyles.subheadline
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(u.email,
                            style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        _StatusPill(isActive: u.isActive),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        u.isVerified ? 'Verified' : 'Unverified',
                        style: AppTextStyles.caption2.copyWith(
                            color: u.isVerified
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
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
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.surfaceSecondary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Role',
                          value: u.role.name[0].toUpperCase() +
                              u.role.name.substring(1)),
                      _MiniStat(
                          label: 'Verified',
                          value: u.isVerified ? 'Yes' : 'No'),
                      _MiniStat(
                          label: 'Joined',
                          value: _formatDate(u.createdAt)),
                    ],
                  ),
                  if (u.phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(u.phone!,
                            style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onToggle,
                      icon: Icon(
                        u.isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: u.isActive
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      label: Text(
                        u.isActive ? 'Suspend User' : 'Reactivate User',
                        style: TextStyle(
                            color: u.isActive
                                ? AppColors.error
                                : AppColors.success),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: u.isActive
                                ? AppColors.error
                                : AppColors.success),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error)
            .withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        isActive ? 'Active' : 'Suspended',
        style: AppTextStyles.caption2.copyWith(
          color: isActive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
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
            Text(value,
                style: AppTextStyles.subheadline
                    .copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: AppTextStyles.caption2
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}


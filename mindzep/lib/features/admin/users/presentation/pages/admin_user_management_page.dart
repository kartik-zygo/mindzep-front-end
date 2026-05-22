import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../admin/data/models/admin_models.dart';
import '../../../../admin/data/repositories/admin_repository.dart';

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

  late final AdminRepository _adminRepository;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _activeFilter = 'All';
  static const _filters = ['All', 'Active', 'Suspended', 'Inactive'];

  bool _loading = true;
  String? _loadError;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _adminRepository = sl<AdminRepository>();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? get _statusParam => switch (_activeFilter) {
    'Active'    => 'active',
    'Suspended' => 'suspended',
    'Inactive'  => 'inactive',
    _           => null,
  };

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final results = await _adminRepository.listUsers(
        page: 1,
        limit: 100,
        search: _search.isNotEmpty ? _search : null,
        status: _statusParam,
      );
      if (!mounted) return;
      setState(() { _users = results; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadError = e is ApiErrorModel ? e.message : 'Failed to load users.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _id(Map<String, dynamic> m) => m['_id'] as String? ?? m['id'] as String? ?? '';
  String _name(Map<String, dynamic> m) => m['name'] as String? ?? 'User';
  String _email(Map<String, dynamic> m) => m['email'] as String? ?? '';
  String _phone(Map<String, dynamic> m) => m['phone'] as String? ?? '';
  bool _isActive(Map<String, dynamic> m) => m['isActive'] as bool? ?? true;
  bool _isSuspended(Map<String, dynamic> m) => m['isSuspended'] as bool? ?? false;

  String _userStatus(Map<String, dynamic> m) {
    if (_isSuspended(m)) return 'Suspended';
    if (!_isActive(m)) return 'Inactive';
    return 'Active';
  }

  Color _statusColor(String status) => switch (status) {
    'Suspended' => AppColors.error,
    'Inactive'  => AppColors.warning,
    _           => AppColors.success,
  };

  Future<void> _toggleUser(Map<String, dynamic> user) async {
    final id = _id(user);
    final name = _name(user);
    final isSuspended = _isSuspended(user);
    try {
      if (isSuspended) {
        await _adminRepository.activateUser(id);
      } else {
        await _adminRepository.suspendUser(id, SuspendEntityRequest(reason: 'Suspended by admin'));
      }
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: isSuspended ? '$name reactivated.' : '$name has been suspended.',
        type: isSuspended ? SnackbarType.success : SnackbarType.warning,
      );
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiErrorModel ? e.message : 'Action failed.';
      AppSnackbar.show(context, message: msg, type: SnackbarType.error);
    }
  }

  void _showDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: user,
        adminRepository: _adminRepository,
        onAction: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!_loading && _loadError == null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              ),
                              child: Text(
                                '${_users.length} users',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) {
                                  setState(() => _search = v);
                                  // debounce: reload after 500ms idle
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (_search == v) _loadUsers();
                                  });
                                },
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _loadUsers(),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, email, phone...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_search.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                  _loadUsers();
                                },
                                child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final f = _filters[i];
                            final selected = _activeFilter == f;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _activeFilter = f);
                                _loadUsers();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: selected ? const Color(0xFFFF6B6B) : Colors.white,
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center, style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textTertiary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('No users found', style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _users.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            child: Text(
              '${_users.length} users',
              style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
            ),
          );
        }
        final user = _users[i - 1];
        return _UserCard(
          user: user,
          status: _userStatus(user),
          statusColor: _statusColor(_userStatus(user)),
          onTap: () => _showDetail(user),
          onToggle: () => _toggleUser(user),
        );
      },
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _UserCard({
    required this.user,
    required this.status,
    required this.statusColor,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? 'User';
    final email = user['email'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String?;
    final isVerified = user['isVerified'] as bool? ?? false;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(imageUrl: avatarUrl, radius: 22, initials: name[0]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                      ),
                  ],
                ),
                if (email.isNotEmpty)
                  Text(email, overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(status, style: AppTextStyles.caption2.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── User Detail Sheet ────────────────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final AdminRepository adminRepository;
  final VoidCallback onAction;

  const _UserDetailSheet({
    required this.user,
    required this.adminRepository,
    required this.onAction,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _loadingDetail = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final id = widget.user['_id'] as String? ?? widget.user['id'] as String? ?? '';
    if (id.isEmpty) { setState(() => _loadingDetail = false); return; }
    try {
      final detail = await widget.adminRepository.getUser(id);
      if (!mounted) return;
      setState(() { _detail = detail; _loadingDetail = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loadingDetail = false; });
    }
  }

  Future<void> _toggleSuspend() async {
    final id = widget.user['_id'] as String? ?? widget.user['id'] as String? ?? '';
    final name = widget.user['name'] as String? ?? 'User';
    final isSuspended = widget.user['isSuspended'] as bool? ?? false;
    try {
      if (isSuspended) {
        await widget.adminRepository.activateUser(id);
      } else {
        await widget.adminRepository.suspendUser(id, SuspendEntityRequest(reason: 'Suspended by admin'));
      }
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: isSuspended ? '$name reactivated.' : '$name has been suspended.',
        type: isSuspended ? SnackbarType.success : SnackbarType.warning,
      );
      Navigator.pop(context);
      widget.onAction();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiErrorModel ? e.message : 'Action failed.';
      AppSnackbar.show(context, message: msg, type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] as String? ?? 'User';
    final email = widget.user['email'] as String? ?? '';
    final phone = widget.user['phone'] as String? ?? '';
    final avatarUrl = widget.user['avatarUrl'] as String?;
    final isSuspended = widget.user['isSuspended'] as bool? ?? false;
    final isVerified = widget.user['isVerified'] as bool? ?? false;
    final createdAt = widget.user['createdAt'] as String?;

    final wallet = _detail != null ? (_detail!['wallet'] as Map?)?.cast<String, dynamic>() : null;
    final profile = _detail != null ? (_detail!['profile'] as Map?)?.cast<String, dynamic>() : null;
    final apptCount = _detail?['appointmentCount'] as int? ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  // Header
                  Row(
                    children: [
                      AppAvatar(imageUrl: avatarUrl, radius: 30, initials: name[0]),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(name,
                                      style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                if (isVerified)
                                  Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                            if (email.isNotEmpty)
                              Text(email, style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary)),
                            if (phone.isNotEmpty)
                              Text(phone, style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (createdAt != null) ...[
                    Text(
                      'Joined ${_formatDate(createdAt)}',
                      style: AppTextStyles.caption2.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Stats
                  if (_loadingDetail)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Row(
                      children: [
                        _StatBox(label: 'Appointments', value: '$apptCount'),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Minutes Used',
                            value: '${profile?['totalMinutesUsed'] ?? 0}'),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Wallet',
                            value: wallet != null ? '₹${wallet['balance'] ?? 0}' : '—'),
                      ],
                    ),
                    if (wallet != null) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wallet Details',
                                style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            _WalletRow(label: 'Balance', value: '₹${wallet['balance'] ?? 0}'),
                            _WalletRow(label: 'Total Added', value: '₹${wallet['totalAdded'] ?? 0}'),
                            _WalletRow(label: 'Total Spent', value: '₹${wallet['totalSpent'] ?? 0}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  // Action
                  OutlinedButton.icon(
                    onPressed: _toggleSuspend,
                    icon: Icon(
                      isSuspended ? Icons.power_settings_new_rounded : Icons.block_rounded,
                      size: 18,
                      color: isSuspended ? AppColors.success : AppColors.error,
                    ),
                    label: Text(
                      isSuspended ? 'Reactivate Account' : 'Suspend Account',
                      style: TextStyle(color: isSuspended ? AppColors.success : AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isSuspended ? AppColors.success : AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  final String label;
  final String value;
  const _WalletRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


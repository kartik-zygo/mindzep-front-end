import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../admin/data/repositories/admin_repository.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() =>
      _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late final AdminRepository _adminRepository;
  String _activeFilter = 'All';
  static const _filters = ['All', 'Upcoming', 'Ongoing', 'Done', 'Cancelled'];

  bool _loading = true;
  String? _loadError;
  List<Map<String, dynamic>> _appointments = const [];

  @override
  void initState() {
    super.initState();
    _adminRepository = sl<AdminRepository>();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final results = await _adminRepository.listAppointments(page: 1, limit: 100);
      if (!mounted) return;
      setState(() { _appointments = results; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadError = e is ApiErrorModel ? e.message : 'Failed to load appointments.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _status(Map<String, dynamic> a) =>
      (a['status'] as String? ?? '').toLowerCase();

  List<Map<String, dynamic>> get _filtered {
    return switch (_activeFilter) {
      'Upcoming'  => _appointments.where((a) => _status(a) == 'upcoming').toList(),
      'Ongoing'   => _appointments.where((a) => _status(a) == 'ongoing').toList(),
      'Done'      => _appointments.where((a) => _status(a) == 'completed').toList(),
      'Cancelled' => _appointments.where((a) => _status(a) == 'cancelled' || _status(a) == 'no_show' || _status(a) == 'noshow').toList(),
      _           => _appointments,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center, style: AppTextStyles.body),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadAppointments, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final upcoming   = _appointments.where((a) => _status(a) == 'upcoming').length;
    final completed  = _appointments.where((a) => _status(a) == 'completed').length;
    final cancelled  = _appointments.where((a) => _status(a) == 'cancelled' || _status(a) == 'no_show' || _status(a) == 'noshow').length;
    final filtered   = _filtered;

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
                              'Appointments',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                            child: Text(
                              '$upcoming upcoming',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _SummaryChip(icon: Icons.event_outlined, label: '${_appointments.length} Total'),
                          const SizedBox(width: 10),
                          _SummaryChip(icon: Icons.check_circle_outline_rounded, label: '$completed Done'),
                          const SizedBox(width: 10),
                          _SummaryChip(icon: Icons.cancel_outlined, label: '$cancelled Cancelled'),
                        ],
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
                              onTap: () => setState(() => _activeFilter = f),
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
        body: filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_outlined, size: 56, color: AppColors.textTertiary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text('No appointments found', style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                itemCount: filtered.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                      child: Text(
                        '${filtered.length} appointments',
                        style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return _AdminApptCard(appointment: filtered[i - 1]);
                },
              ),
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────

class _AdminApptCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  const _AdminApptCard({required this.appointment});

  String get _status => (appointment['status'] as String? ?? '').toLowerCase();

  Color get _statusColor => switch (_status) {
    'upcoming'  => AppColors.info,
    'ongoing'   => AppColors.success,
    'completed' => AppColors.textSecondary,
    'cancelled' => AppColors.error,
    _           => AppColors.warning,
  };

  String get _statusLabel => switch (_status) {
    'upcoming'  => 'Upcoming',
    'ongoing'   => 'Ongoing',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    'no_show'   => 'No Show',
    'noshow'    => 'No Show',
    _           => _status,
  };

  String _readName(dynamic nested, String fallback) {
    if (nested is! Map) return fallback;
    // user objects have direct 'name'; psychologist objects have 'user.name'
    final direct = nested['name'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final userSub = nested['user'];
    if (userSub is Map) {
      final sub = userSub['name'] as String?;
      if (sub != null && sub.isNotEmpty) return sub;
    }
    return fallback;
  }

  String _readAvatar(dynamic nested) {
    if (nested is Map) return nested['avatarUrl'] as String? ?? nested['profilePhoto'] as String? ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final userNested  = appointment['user'];
    final psychNested = appointment['psychologist'];
    final userName  = _readName(userNested, 'User');
    final psychName = _readName(psychNested, 'Therapist');
    final userAvatar  = _readAvatar(userNested);
    final psychAvatar = _readAvatar(psychNested);

    final scheduledRaw = appointment['scheduledAt'] as String?;
    final scheduledAt = scheduledRaw != null ? DateTime.tryParse(scheduledRaw) : null;

    final totalCharge = appointment['totalCharge'] ?? appointment['totalAmount'];
    final sessionType = (appointment['sessionType'] as String? ?? '').toLowerCase();
    final durationMinutes = appointment['durationMinutes'] ?? appointment['duration'];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusLabel,
                        style: AppTextStyles.caption1.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
                    if (scheduledAt != null)
                      Text(_formatDateTime(scheduledAt),
                          style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (totalCharge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    '₹${(totalCharge as num).toStringAsFixed(0)}',
                    style: AppTextStyles.caption1.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(imageUrl: userAvatar.isNotEmpty ? userAvatar : null, radius: 18, initials: userName[0]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600)),
                          Text('User', style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.surfaceSecondary, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
              ),
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(imageUrl: psychAvatar.isNotEmpty ? psychAvatar : null, radius: 18, initials: psychName[0]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(psychName, overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600)),
                          Text('Therapist', style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sessionType.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  sessionType == 'video' ? Icons.videocam_outlined : Icons.phone_outlined,
                  size: 13, color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  sessionType == 'video' ? 'Video Call' : 'Voice Call',
                  style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary),
                ),
                if (durationMinutes != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('$durationMinutes min', style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $h:$m';
  }
}

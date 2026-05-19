import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../appointments/data/repositories/appointment_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_models.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final UserRepository _userRepository;
  late final AppointmentRepository _appointmentRepository;
  late final Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _userRepository = sl<UserRepository>();
    _appointmentRepository = sl<AppointmentRepository>();
    _profileFuture = _loadProfileData();
  }

  Future<_ProfileData> _loadProfileData() async {
    final profile = await _userRepository.getMe();
    final wallet = await _userRepository.getMyWallet();
    final appointments = await _appointmentRepository.listAppointments(
      page: 1,
      limit: 100,
    );

    final entities = appointments.items.map((item) => item.toEntity()).toList();
    final upcomingCount = entities
        .where((appointment) => appointment.status.name == 'upcoming')
        .length;
    final completedCount = entities
        .where((appointment) => appointment.status.name == 'completed')
        .length;

    return _ProfileData(
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      totalSessions: entities.length,
      upcomingSessions: upcomingCount,
      completedSessions: completedCount,
      walletBalance: wallet.balance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.read<AuthBloc>().currentUser;

    return FutureBuilder<_ProfileData>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data ??
            _ProfileData(
              name: authUser?.name ?? 'User',
              email: authUser?.email ?? '-',
              phone: authUser?.phone,
              avatarUrl: authUser?.avatarUrl,
              totalSessions: 0,
              upcomingSessions: 0,
              completedSessions: 0,
              walletBalance: 0,
            );
        final safeName = profile.name.trim().isEmpty ? 'User' : profile.name.trim();

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          body: CustomScrollView(
            slivers: [
          // ── Gradient Header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => context.go(RouteNames.userHome),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(19)),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const Expanded(child: Text('My Profile', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
                      GestureDetector(
                        onTap: () => _showEditProfile(context, profile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                        ),
                        child: AppAvatar(imageUrl: profile.avatarUrl, radius: 44, initials: _initials(profile.name)),
                      ),
                      GestureDetector(
                        onTap: () => _showEditProfile(context, profile),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(safeName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(profile.email, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
                    if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(profile.phone!, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFFFFD60A)),
                        SizedBox(width: 6),
                        Text('Verified Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // ── Stats Row ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: IntrinsicHeight(
                    child: Row(children: [
                      _StatCell(value: '${profile.totalSessions}', label: 'Total\nSessions', icon: Icons.access_time_rounded, color: const Color(0xFF5E5CE6)),
                      _VertDivider(),
                      _StatCell(value: '${profile.upcomingSessions}', label: 'Upcoming', icon: Icons.schedule_rounded, color: const Color(0xFFFF9500)),
                      _VertDivider(),
                      _StatCell(value: '${profile.completedSessions}', label: 'Completed', icon: Icons.check_circle_rounded, color: const Color(0xFF34C759)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ── spacing to compensate translate ────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 0)),

          // ── Menu Sections ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionHeader('ACCOUNT'),
                _MenuGroup(items: [
                  _MenuItemData(
                    icon: Icons.person_outline_rounded, label: 'Edit Profile', subtitle: 'Update name, photo & bio',
                    iconBg: const Color(0xFFEEF0FF), iconColor: const Color(0xFF5E5CE6),
                    onTap: () => _showEditProfile(context, profile),
                  ),
                  _MenuItemData(
                    icon: Icons.lock_outline_rounded, label: 'Change Password', subtitle: 'Secure your account',
                    iconBg: const Color(0xFFFFF0EE), iconColor: const Color(0xFFFF6B6B),
                    onTap: () => _showChangePassword(context),
                  ),
                  _MenuItemData(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'My Wallet',
                    subtitle: 'Balance: ₹${profile.walletBalance.toStringAsFixed(0)}',
                    iconBg: const Color(0xFFE8FFF1), iconColor: const Color(0xFF34C759),
                    onTap: () => context.go(RouteNames.userWallet),
                  ),
                ]),

                _SectionHeader('PREFERENCES'),
                _MenuGroup(items: [
                  _MenuItemData(
                    icon: Icons.notifications_outlined, label: 'Notifications', subtitle: 'Manage alerts & reminders',
                    iconBg: const Color(0xFFFFF8E1), iconColor: const Color(0xFFFF9500),
                    onTap: () => context.push(RouteNames.userNotifications),
                  ),
                  _MenuItemData(
                    icon: Icons.language_rounded, label: 'Language', subtitle: 'English',
                    iconBg: const Color(0xFFE6F8FA), iconColor: const Color(0xFF30B0C7),
                    onTap: () {},
                    trailing: const Text('English', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                  ),
                ]),

                _SectionHeader('SUPPORT'),
                _MenuGroup(items: [
                  _MenuItemData(
                    icon: Icons.help_outline_rounded, label: 'Help & Support', subtitle: 'FAQs and contact',
                    iconBg: const Color(0xFFEEF0FF), iconColor: const Color(0xFF5E5CE6),
                    onTap: () => _showHelp(context),
                  ),
                  _MenuItemData(
                    icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', subtitle: 'How we use your data',
                    iconBg: const Color(0xFFE8FFF1), iconColor: const Color(0xFF34C759),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  _MenuItemData(
                    icon: Icons.star_outline_rounded, label: 'Rate MindZep', subtitle: 'Leave a review',
                    iconBg: const Color(0xFFFFF8E1), iconColor: const Color(0xFFFFD60A),
                    onTap: () => _showRateApp(context),
                  ),
                  _MenuItemData(
                    icon: Icons.info_outline_rounded, label: 'About', subtitle: 'v1.0.0 · © 2026 MindZep',
                    iconBg: const Color(0xFFF2F2F7), iconColor: const Color(0xFF8E8E93),
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFFF3B30), size: 20),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  // ── Modals ─────────────────────────────────────────────────────────────────

  static void _showEditProfile(BuildContext context, _ProfileData user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final bioCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SheetHandle(),
            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 18),
            _FormField(controller: nameCtrl, label: 'Full Name', icon: Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _FormField(controller: phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _FormField(controller: bioCtrl, label: 'Bio (optional)', icon: Icons.notes_rounded, maxLines: 3),
            const SizedBox(height: 20),
            _ActionButton(
              label: 'Save Changes',
              gradient: const [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
              onTap: () async {
                await sl<UserRepository>().updateMe(
                  UserUpdateRequest(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Profile updated!'), backgroundColor: Color(0xFF34C759),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ]),
        ),
      ),
    );
  }

  static void _showChangePassword(BuildContext context) {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final cfmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SheetHandle(),
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text('Create a strong password to keep your account secure.', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            const SizedBox(height: 18),
            _FormField(controller: curCtrl, label: 'Current Password', icon: Icons.lock_outline_rounded, obscure: true),
            const SizedBox(height: 12),
            _FormField(controller: newCtrl, label: 'New Password', icon: Icons.lock_rounded, obscure: true),
            const SizedBox(height: 12),
            _FormField(controller: cfmCtrl, label: 'Confirm Password', icon: Icons.lock_rounded, obscure: true),
            const SizedBox(height: 20),
            _ActionButton(
              label: 'Update Password',
              gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password updated!'), backgroundColor: Color(0xFF34C759),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ]),
        ),
      ),
    );
  }

  static void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  static void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HelpSheet(),
    );
  }

  static void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListView(controller: ctrl, children: [
            _SheetHandle(),
            const Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text('Last updated: May 2026', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
            const SizedBox(height: 16),
            ..._privacyItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 6),
                Text(item['body']!, style: const TextStyle(fontSize: 13, color: Color(0xFF3C3C3C), height: 1.5)),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  static void _showRateApp(BuildContext context) {
    showDialog(context: context, builder: (_) => const _RateAppDialog());
  }

  static void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('You will be redirected to the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93)))),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Future.microtask(() => context.read<AuthBloc>().add(const LogoutRequested()));
            },
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

class _ProfileData {
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int totalSessions;
  final int upcomingSessions;
  final int completedSessions;
  final double walletBalance;

  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.totalSessions,
    required this.upcomingSessions,
    required this.completedSessions,
    required this.walletBalance,
  });
}

// ── Privacy content ────────────────────────────────────────────────────────────

const _privacyItems = [
  {'title': 'Information We Collect', 'body': 'We collect information you provide directly, such as your name, email address, phone number, and any content you submit. We also collect usage data to improve the app experience.'},
  {'title': 'How We Use Your Information', 'body': 'Your data is used to provide personalized mental health services, connect you with therapists, and improve our platform. We never sell your personal information.'},
  {'title': 'Data Security', 'body': 'All session data is end-to-end encrypted. We follow industry-standard security practices and comply with applicable data protection regulations.'},
  {'title': 'Your Rights', 'body': 'You have the right to access, update, or delete your personal data at any time. Contact support@mindzep.com for any data-related requests.'},
  {'title': 'Cookies & Analytics', 'body': 'We use anonymous analytics to understand usage patterns. No personally identifiable information is shared with third-party analytics providers.'},
];

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
    ),
  );
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCell({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, size: 20, color: color)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), height: 1.3)),
      ]),
    ),
  );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 48, color: const Color(0xFFE5E5EA));
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0.8)),
  );
}

class _MenuItemData {
  final IconData icon;
  final String label, subtitle;
  final Color iconBg, iconColor;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuItemData({required this.icon, required this.label, required this.subtitle, required this.iconBg, required this.iconColor, required this.onTap, this.trailing});
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(children: List.generate(items.length, (i) {
        final item = items[i];
        return Column(children: [
          GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(item.icon, size: 20, color: item.iconColor)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                  Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ])),
                item.trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCECED6)),
              ]),
            ),
          ),
          if (i < items.length - 1) const Divider(height: 1, indent: 68, color: Color(0xFFF2F2F7)),
        ]);
      })),
    );
  }
}

class _FormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final int maxLines;
  final TextInputType keyboardType;

  const _FormField({required this.controller, required this.label, required this.icon, this.obscure = false, this.maxLines = 1, this.keyboardType = TextInputType.text});

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  late bool _obs;
  @override
  void initState() { super.initState(); _obs = widget.obscure; }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: widget.controller,
        obscureText: _obs,
        maxLines: _obs ? 1 : widget.maxLines,
        keyboardType: widget.keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          prefixIcon: Icon(widget.icon, size: 18, color: const Color(0xFF8E8E93)),
          suffixIcon: widget.obscure
              ? GestureDetector(
                  onTap: () => setState(() => _obs = !_obs),
                  child: Icon(_obs ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF8E8E93)))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );
}

// ── Notifications sheet ────────────────────────────────────────────────────────

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _sessions = true, _mood = true, _promos = false, _newTherapists = true, _updates = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SheetHandle(),
        const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
        const SizedBox(height: 4),
        const Text('Choose what notifications you receive.', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        const SizedBox(height: 16),
        _Toggle('Session Reminders', 'Before your scheduled sessions', _sessions, (v) => setState(() => _sessions = v)),
        _Toggle('Mood Check-in', 'Daily mood logging reminders', _mood, (v) => setState(() => _mood = v)),
        _Toggle('New Therapists', 'When new therapists join', _newTherapists, (v) => setState(() => _newTherapists = v)),
        _Toggle('Promotions', 'Offers and discounts', _promos, (v) => setState(() => _promos = v)),
        _Toggle('App Updates', 'New features and updates', _updates, (v) => setState(() => _updates = v)),
        const SizedBox(height: 12),
        _ActionButton(label: 'Save Preferences', gradient: const [Color(0xFF5E5CE6), Color(0xFF8B7CF6)], onTap: () => Navigator.pop(context)),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label, sub;
  final bool value;
  final void Function(bool) onChanged;
  const _Toggle(this.label, this.sub, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
        Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF5E5CE6)),
    ]),
  );
}

// ── Help sheet ──────────────────────────────────────────────────────────────────

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  static const _faqs = [
    {'q': 'How do I book a session?', 'a': 'Tap "Consult" from the bottom nav, choose a therapist and tap "Book". Select a slot, choose a session type, and complete payment.'},
    {'q': 'Is my conversation private?', 'a': 'Yes. All sessions are end-to-end encrypted and completely confidential. Your data is never shared without consent.'},
    {'q': 'How do I add money to my wallet?', 'a': 'Go to Wallet from the bottom nav. Tap "Add Money" and choose an amount and payment method.'},
    {'q': 'Can I cancel a session?', 'a': 'Yes, sessions can be cancelled up to 2 hours before the scheduled time from "My Sessions". A full refund will be issued to your wallet.'},
    {'q': 'How do I contact support?', 'a': 'Email us at support@mindzep.com or use the in-app chat (available 9 AM – 9 PM IST). We typically respond within 2 hours.'},
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ListView(controller: ctrl, children: [
          const _SheetHandle(),
          const Text('Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 4),
          const Text('Frequently asked questions', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          const SizedBox(height: 16),
          ..._faqs.map((faq) => _FaqTile(q: faq['q']!, a: faq['a']!)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Still need help?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
              const SizedBox(height: 4),
              const Text('Our team is available Mon–Sat, 9AM–9PM IST.', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: const Color(0xFF5E5CE6), borderRadius: BorderRadius.circular(10)),
                child: const Text('📧 support@mindzep.com', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q, a;
  const _FaqTile({required this.q, required this.a});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(child: Text(widget.q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)))),
              AnimatedRotation(
                turns: _expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF8E8E93)),
              ),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(widget.a, style: const TextStyle(fontSize: 13, color: Color(0xFF3C3C3C), height: 1.5)),
          ),
      ]),
    );
  }
}

// ── Rate App Dialog ────────────────────────────────────────────────────────────

class _RateAppDialog extends StatefulWidget {
  const _RateAppDialog();
  @override
  State<_RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<_RateAppDialog> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(children: [
        Text('💙', style: TextStyle(fontSize: 36)),
        SizedBox(height: 8),
        Text('Rate MindZep', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('How would you rate your experience?', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, size: 36, color: i < _rating ? const Color(0xFFFFD60A) : const Color(0xFFCECED6)),
          ),
        ))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not Now', style: TextStyle(color: Color(0xFF8E8E93)))),
        TextButton(
          onPressed: _rating > 0 ? () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Thanks for your rating! ⭐'),
              backgroundColor: Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
            ));
          } : null,
          child: Text('Submit', style: TextStyle(color: _rating > 0 ? const Color(0xFF5E5CE6) : const Color(0xFFCECED6), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

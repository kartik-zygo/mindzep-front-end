import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/appointments/data/repositories/appointment_repository.dart';
import '../../../../user/blog/data/models/blog_models.dart';
import '../../../../user/blog/data/repositories/blog_repository.dart';
import '../../../../user/data/models/user_models.dart';
import '../../../../user/data/repositories/user_repository.dart';
import '../bloc/psychologist_list_bloc.dart';
import '../bloc/psychologist_list_event_state.dart';
import '../../../../../core/widgets/app_drawer.dart';
import '../widgets/mood_sheet.dart';
import '../widgets/psychologist_card.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final UserRepository _userRepository;
  late final AppointmentRepository _appointmentRepository;
  late final BlogRepository _blogRepository;

  UserProfileModel? _profile;
  WalletSummaryModel? _wallet;
  List<AppointmentEntity> _appointments = const <AppointmentEntity>[];
  List<BlogEntity> _blogs = const <BlogEntity>[];
  bool _loadingDashboard = true;

  late AnimationController _broadcastCtrl;
  late Animation<double> _ring1, _ring2, _ring3;

  static const _moods = [
    {'emoji': '😰', 'label': 'Anxious', 'color': 0xFFFFF3CD, 'ring': 0xFFF59E0B},
    {'emoji': '😢', 'label': 'Sad', 'color': 0xFFE8F4FD, 'ring': 0xFF3B82F6},
    {'emoji': '😤', 'label': 'Stressed', 'color': 0xFFFCE4EC, 'ring': 0xFFEF4444},
    {'emoji': '🙂', 'label': 'Okay', 'color': 0xFFE8F5E9, 'ring': 0xFF10B981},
    {'emoji': '😊', 'label': 'Good', 'color': 0xFFF3E5F5, 'ring': 0xFF8B5CF6},
  ];

  @override
  void initState() {
    super.initState();
    _userRepository = sl<UserRepository>();
    _appointmentRepository = sl<AppointmentRepository>();
    _blogRepository = sl<BlogRepository>();

    _broadcastCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _ring1 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _broadcastCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _ring2 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _broadcastCtrl, curve: const Interval(0.2, 0.9, curve: Curves.easeOut)));
    _ring3 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _broadcastCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    context.read<PsychologistListBloc>().add(const LoadPsychologists());
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loadingDashboard = true;
    });

    UserProfileModel? profile;
    WalletSummaryModel? wallet;
    dynamic appointmentsResponse;
    List<BlogModel>? blogs;

    try {
      profile = await _userRepository.getMe();
    } catch (_) {}

    try {
      wallet = await _userRepository.getMyWallet();
    } catch (_) {}

    try {
      appointmentsResponse = await _appointmentRepository.listAppointments(page: 1, limit: 100);
    } catch (_) {}

    try {
      blogs = await _blogRepository.listPublishedBlogs(page: 1, limit: 20);
    } catch (_) {}

    if (!mounted) return;

    final mappedAppointments = appointmentsResponse?.items
            .map<AppointmentEntity>((item) => item.toEntity())
            .toList() ??
        <AppointmentEntity>[];

    final mappedBlogs = blogs
            ?.map<BlogEntity>((item) => item.toEntity())
            .where((blog) => blog.status == BlogStatus.published)
            .toList() ??
        <BlogEntity>[];

    setState(() {
      if (profile != null) _profile = profile;
      if (wallet != null) _wallet = wallet;
      _appointments = mappedAppointments;
      _blogs = mappedBlogs;
      _loadingDashboard = false;
    });
  }

  @override
  void dispose() {
    _broadcastCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _profile?.name ?? 'User';
    final avatarUrl = _profile?.avatarUrl;
    final upcomingCount = _appointments
        .where((appointment) => appointment.status == AppointmentStatus.upcoming)
        .length;
    final completedCount = _appointments
        .where((appointment) => appointment.status == AppointmentStatus.completed)
        .length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F2F7),
      drawer: const AppUserDrawer(),
      body: CustomScrollView(
        slivers: [
          _buildGradientHeader(
            context,
            userName: userName,
            avatarUrl: avatarUrl,
            walletBalance: _wallet?.balance ?? 0,
          ),
          if (_loadingDashboard)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          _buildMoodSection(),
          _buildQuickActions(context),
          _buildStatsRow(
            totalSessions: _appointments.length,
            upcomingSessions: upcomingCount,
            completedSessions: completedCount,
          ),
          _buildBroadcastBanner(context),
          _buildTopTherapistsSection(context),
          _buildBlogSection(context),
          _buildDailyTip(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Gradient Header ──────────────────────────────────────────────────────

  Widget _buildGradientHeader(
    BuildContext context, {
    required String userName,
    String? avatarUrl,
    required double walletBalance,
  }) {
    final trimmedName = userName.trim().isEmpty ? 'User' : userName;
    final firstName = trimmedName.split(' ').first;

    return SliverToBoxAdapter(
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hamburger menu
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateUtils.greeting(firstName),
                            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            trimmedName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.userNotifications),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.go(RouteNames.userProfile),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: AppAvatar(imageUrl: avatarUrl, radius: 20, initials: _initials(trimmedName)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.go(RouteNames.userWallet),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '₹${walletBalance.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xB3FFFFFF), size: 16),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mood Section ──────────────────────────────────────────────────────────

  Widget _buildMoodSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('How are you feeling?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                const Text('Tap to share', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _moods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final mood = _moods[i];
                  return GestureDetector(
                    onTap: () => MoodSheet.show(context, mood),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(mood['color'] as int),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mood['emoji'] as String, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            mood['label'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5E5CE6)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                label: 'Talk Now',
                sublabel: 'Instant session',
                emoji: '🎧',
                gradient: const [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                onTap: () => context.go(RouteNames.userConsult),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: 'Book Later',
                sublabel: 'Schedule session',
                emoji: '📅',
                gradient: const [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                onTap: () => context.go(RouteNames.userAppointments),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow({
    required int totalSessions,
    required int upcomingSessions,
    required int completedSessions,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          children: [
            _StatBadge(value: '$totalSessions', label: 'Sessions', icon: Icons.access_time_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            _StatBadge(value: '$upcomingSessions', label: 'Upcoming', icon: Icons.trending_up_rounded, color: const Color(0xFFFF9500)),
            const SizedBox(width: 10),
            _StatBadge(value: '$completedSessions', label: 'Done', icon: Icons.shield_rounded, color: const Color(0xFF34C759)),
          ],
        ),
      ),
    );
  }

  // ── Broadcast Call Banner ──────────────────────────────────────────────────

  Widget _buildBroadcastBanner(BuildContext context) {
    final blocState = context.watch<PsychologistListBloc>().state;
    final available = blocState is PsychologistListLoaded
      ? blocState.filtered
        .where((psychologist) => psychologist.status == AvailabilityStatus.available)
        .take(3)
        .toList()
      : const <PsychologistEntity>[];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: GestureDetector(
          onTap: () => context.push(RouteNames.userBroadcast),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1a0a3e), Color(0xFF2d1065), Color(0xFF0d3060)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: const Color(0xFF5E5CE6).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                // Radar animation
                SizedBox(
                  width: 68, height: 68,
                  child: AnimatedBuilder(
                    animation: _broadcastCtrl,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        ...[_ring1, _ring2, _ring3].map((a) => Opacity(
                          opacity: (1 - a.value).clamp(0, 1),
                          child: Container(
                            width: 20 + a.value * 48,
                            height: 20 + a.value * 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF5E5CE6).withOpacity(0.5), width: 1.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )),
                        Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.radio_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Connect Instantly', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('INSTANT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      const Text(
                        'Broadcast to all therapists — first to respond connects',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...available.map((p) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF5E5CE6),
                              child: ClipOval(
                                child: AppAvatar(imageUrl: p.avatarUrl, radius: 12, initials: p.name[0]),
                              ),
                            ),
                          )),
                          const SizedBox(width: 6),
                          Row(children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              '${available.length} online',
                              style: const TextStyle(color: Color(0xFF34C759), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF5E5CE6), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Therapists ─────────────────────────────────────────────────────────

  Widget _buildTopTherapistsSection(BuildContext context) {
    final blocState = context.watch<PsychologistListBloc>().state;
    final top = blocState is PsychologistListLoaded
        ? (() {
            final items = List<PsychologistEntity>.from(blocState.all);
            items.sort((a, b) {
              final ratingCompare = b.ratingAverage.compareTo(a.ratingAverage);
              if (ratingCompare != 0) return ratingCompare;
              return b.totalReviews.compareTo(a.totalReviews);
            });
            return items.take(3).toList();
          })()
        : const <PsychologistEntity>[];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Therapists', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                GestureDetector(
                  onTap: () => context.go(RouteNames.userConsult),
                  child: Row(children: [
                    Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: top.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final p = top[i];
                  return GestureDetector(
                    onTap: () => context.push(RouteNames.psychologistDetail, extra: p),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            AppAvatar(imageUrl: p.avatarUrl, radius: 22, initials: _initials(p.name)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(top: 3),
                                  decoration: BoxDecoration(
                                    color: p.status == AvailabilityStatus.available
                                        ? const Color(0xFFE8FFF1)
                                        : const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.status == AvailabilityStatus.available
                                        ? 'Available'
                                        : 'Offline',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: p.status == AvailabilityStatus.available
                                          ? const Color(0xFF34C759)
                                          : const Color(0xFF8E8E93),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            p.specializations.isNotEmpty
                                ? p.specializations.first
                                : p.specialization,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFF9500)),
                            const SizedBox(width: 3),
                            Text(p.ratingAverage.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('₹${p.ratePerMinute}/min', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5E5CE6))),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Blog Section ───────────────────────────────────────────────────────────

  Widget _buildBlogSection(BuildContext context) {
    final blogs = _blogs;
    if (blogs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final featured = blogs.first;
    final rest = blogs.skip(1).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('From Our Experts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                GestureDetector(
                  onTap: () => context.push(RouteNames.userBlogList),
                  child: Row(children: [
                    Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Featured blog
            GestureDetector(
              onTap: () => context.push(RouteNames.userBlogDetail, extra: featured),
              child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: featured.coverImageUrl != null && featured.coverImageUrl!.isNotEmpty
                      ? Image.network(featured.coverImageUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
                      : null,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(bottom: 14, left: 14, right: 14, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF5E5CE6), borderRadius: BorderRadius.circular(8)),
                      child: Text(featured.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Text(featured.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      CircleAvatar(radius: 10, backgroundColor: const Color(0xFF8B7CF6), child: Text(featured.psychologistName[0], style: const TextStyle(color: Colors.white, fontSize: 9))),
                      const SizedBox(width: 6),
                      Text(featured.psychologistName, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
                      const SizedBox(width: 8),
                      const Icon(Icons.visibility_outlined, color: Color(0x99FFFFFF), size: 12),
                      const SizedBox(width: 3),
                      Text('${featured.viewCount}', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
                    ]),
                  ],
                )),
              ]),
            ),
            ), // GestureDetector

            if (rest.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 195,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rest.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final blog = rest[i];
                    return GestureDetector(
                      onTap: () => context.push(RouteNames.userBlogDetail, extra: blog),
                      child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Container(
                              height: 95,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                              ),
                              child: blog.coverImageUrl != null && blog.coverImageUrl!.isNotEmpty
                                  ? Image.network(blog.coverImageUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(6)),
                                  child: Text(blog.category, style: const TextStyle(color: Color(0xFF5E5CE6), fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(height: 5),
                                Text(blog.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 5),
                                Text(blog.psychologistName, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ), // Container
                    ); // GestureDetector
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Daily Tip ──────────────────────────────────────────────────────────────

  Widget _buildDailyTip() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF8ED), Color(0xFFFFF3CD)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFFF9500).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: const Text('🌟', style: TextStyle(fontSize: 26), textAlign: TextAlign.center),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Tip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF9500), letterSpacing: 0.5)),
                    SizedBox(height: 4),
                    Text(
                      'Take 3 deep breaths before responding to stressful messages. It gives your brain time to think.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5C4500), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

// ── Supporting Widgets ───────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String label, sublabel, emoji;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label, required this.sublabel, required this.emoji,
    required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(sublabel, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _StatBadge({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
      ),
    );
  }
}

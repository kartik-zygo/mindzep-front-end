import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../injection/injection_container.dart';
import '../../data/models/notification_models.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/socket/notifications_socket_manager.dart';

enum _NotifType { session, mood, promo, system, payment }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _notificationRepository;
  late final NotificationsSocketManager _notificationsSocketManager;
  final List<NotificationModel> _notifications = <NotificationModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _notificationRepository = sl<NotificationRepository>();
    _notificationsSocketManager = sl<NotificationsSocketManager>();

    _initialize();
  }

  Future<void> _initialize() async {
    await _loadNotifications();
    await _notificationsSocketManager.connect();
    _notificationsSocketManager.notificationStream.listen((notification) {
      if (!mounted) return;
      setState(() {
        _notifications.insert(0, notification);
      });
    });
  }

  @override
  void dispose() {
    _notificationsSocketManager.disconnect();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((notification) => !notification.isRead).length;

  Future<void> _loadNotifications() async {
    try {
      final items = await _notificationRepository.listNotifications();
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(items);
      });
    } catch (_) {
      // Keep UI stable even if notification sync fails.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    await _notificationRepository.markAllRead();
    if (!mounted) return;

    setState(() {
      for (var index = 0; index < _notifications.length; index++) {
        final current = _notifications[index];
        _notifications[index] = NotificationModel(
          id: current.id,
          title: current.title,
          message: current.message,
          type: current.type,
          isRead: true,
          createdAt: current.createdAt,
        );
      }
    });
  }

  Future<void> _markRead(String id) async {
    await _notificationRepository.markOneRead(id);
    if (!mounted) return;

    setState(() {
      final index = _notifications.indexWhere((notification) => notification.id == id);
      if (index == -1) return;
      final current = _notifications[index];
      _notifications[index] = NotificationModel(
        id: current.id,
        title: current.title,
        message: current.message,
        type: current.type,
        isRead: true,
        createdAt: current.createdAt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _notifications.where((notification) => _isToday(notification.createdAt)).toList();
    final earlier = _notifications.where((notification) => !_isToday(notification.createdAt)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            final location =
                                GoRouterState.of(context).matchedLocation;
                            if (location.startsWith('/admin/')) {
                              context.go(RouteNames.adminDashboard);
                            } else if (location.startsWith('/psych/')) {
                              context.go(RouteNames.psychDashboard);
                            } else {
                              context.go(RouteNames.userHome);
                            }
                          }
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inbox',
                              style: TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$_unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_unreadCount > 0)
                        GestureDetector(
                          onTap: _markAllRead,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Mark all read',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (today.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionLabel('Today')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => _NotifTile(
                    item: today[index],
                    onTap: () => _markRead(today[index].id),
                  ),
                  childCount: today.length,
                ),
              ),
            ],
            if (earlier.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionLabel('Earlier')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => _NotifTile(
                    item: earlier[index],
                    onTap: () => _markRead(earlier[index].id),
                  ),
                  childCount: earlier.length,
                ),
              ),
            ],
            if (_notifications.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      Text('No notifications', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotifTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
          border: item.isRead
              ? null
              : Border.all(color: const Color(0xFF5E5CE6).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _bgColor(_parseType(item.type)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(_emoji(_parseType(item.type)), style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5E5CE6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _timeAgo(item.createdAt),
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCECED6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotifType _parseType(String raw) {
    switch (raw.toLowerCase()) {
      case 'appointment':
      case 'session':
        return _NotifType.session;
      case 'mood':
        return _NotifType.mood;
      case 'promo':
      case 'marketing':
      case 'blog':
        return _NotifType.promo;
      case 'payment':
        return _NotifType.payment;
      case 'account':
      case 'system':
      default:
        return _NotifType.system;
    }
  }

  Color _bgColor(_NotifType type) {
    switch (type) {
      case _NotifType.session:
        return const Color(0xFFEEF0FF);
      case _NotifType.mood:
        return const Color(0xFFFFF8E1);
      case _NotifType.payment:
        return const Color(0xFFE8FFF1);
      case _NotifType.promo:
        return const Color(0xFFFCE4EC);
      case _NotifType.system:
        return const Color(0xFFF2F2F7);
    }
  }

  String _emoji(_NotifType type) {
    switch (type) {
      case _NotifType.session:
        return '📅';
      case _NotifType.mood:
        return '💆';
      case _NotifType.payment:
        return '💳';
      case _NotifType.promo:
        return '📝';
      case _NotifType.system:
        return '🔔';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

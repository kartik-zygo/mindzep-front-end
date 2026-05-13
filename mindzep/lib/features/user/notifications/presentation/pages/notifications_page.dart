import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';

enum _NotifType { session, mood, promo, system, payment }

class _NotifItem {
  final String id;
  final String title;
  final String body;
  final _NotifType type;
  final DateTime time;
  bool isRead;

  _NotifItem({required this.id, required this.title, required this.body, required this.type, required this.time, this.isRead = false});
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _notifications = [
    _NotifItem(id: '1', title: 'Session Reminder', body: 'Your session with Dr. Priya Sharma starts in 30 minutes.', type: _NotifType.session, time: DateTime.now().subtract(const Duration(minutes: 25))),
    _NotifItem(id: '2', title: 'Mood Check-in', body: 'How are you feeling today? Take a moment to log your mood.', type: _NotifType.mood, time: DateTime.now().subtract(const Duration(hours: 2))),
    _NotifItem(id: '3', title: 'Payment Successful', body: 'Your wallet was topped up with ₹500 successfully.', type: _NotifType.payment, time: DateTime.now().subtract(const Duration(hours: 5)), isRead: true),
    _NotifItem(id: '4', title: 'New Article Published', body: '"Managing Anxiety at Work" by Dr. Arjun Mehta is now available.', type: _NotifType.promo, time: DateTime.now().subtract(const Duration(hours: 8))),
    _NotifItem(id: '5', title: 'Session Completed', body: 'Your session with Dr. Sneha Kapoor was completed. Don\'t forget to leave a review!', type: _NotifType.session, time: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
    _NotifItem(id: '6', title: 'Welcome to MindZep!', body: 'Your mental wellness journey begins here. Explore therapists and book your first session.', type: _NotifType.system, time: DateTime.now().subtract(const Duration(days: 2)), isRead: true),
    _NotifItem(id: '7', title: '20% Off This Weekend', body: 'Book any session this weekend and get 20% off. Limited time offer!', type: _NotifType.promo, time: DateTime.now().subtract(const Duration(days: 3)), isRead: true),
    _NotifItem(id: '8', title: 'Streak Achievement 🎉', body: 'You\'ve maintained a 7-day wellness streak! Keep it up!', type: _NotifType.system, time: DateTime.now().subtract(const Duration(days: 4)), isRead: true),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() => setState(() {
    for (final n in _notifications) {
      n.isRead = true;
    }
  });

  void _markRead(String id) => setState(() {
    _notifications.firstWhere((n) => n.id == id).isRead = true;
  });

  void _delete(String id) => setState(() {
    _notifications.removeWhere((n) => n.id == id);
  });

  @override
  Widget build(BuildContext context) {
    final today = _notifications.where((n) => _isToday(n.time)).toList();
    final earlier = _notifications.where((n) => !_isToday(n.time)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
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
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go(RouteNames.userHome),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(19)),
                        child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Inbox', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w500)),
                        Row(children: [
                          const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          if (_unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(10)),
                              child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ]),
                      ]),
                    ),
                    if (_unreadCount > 0)
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),

          // ── Today ────────────────────────────────────────────────────────
          if (today.isNotEmpty) ...[
            const SliverToBoxAdapter(child: _SectionLabel('Today')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _NotifTile(item: today[i], onTap: () => _markRead(today[i].id), onDelete: () => _delete(today[i].id)),
                childCount: today.length,
              ),
            ),
          ],

          // ── Earlier ──────────────────────────────────────────────────────
          if (earlier.isNotEmpty) ...[
            const SliverToBoxAdapter(child: _SectionLabel('Earlier')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _NotifTile(item: earlier[i], onTap: () => _markRead(earlier[i].id), onDelete: () => _delete(earlier[i].id)),
                childCount: earlier.length,
              ),
            ),
          ],

          // ── Empty state ──────────────────────────────────────────────────
          if (_notifications.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Column(children: const [
                  Text('🔔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('All caught up!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                  SizedBox(height: 6),
                  Text('No new notifications', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                ]),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0.5)),
  );
}

class _NotifTile extends StatelessWidget {
  final _NotifItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NotifTile({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        decoration: BoxDecoration(color: const Color(0xFFFF3B30).withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30), size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            border: item.isRead ? null : Border.all(color: const Color(0xFF5E5CE6).withOpacity(0.15)),
          ),
          child: Row(children: [
            // Icon badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _bgColor(item.type), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(_emoji(item.type), style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item.title, style: TextStyle(fontSize: 14, fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700, color: const Color(0xFF1C1C1E)))),
                if (!item.isRead)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF5E5CE6), shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 3),
              Text(item.body, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(_timeAgo(item.time), style: const TextStyle(fontSize: 11, color: Color(0xFFCECED6))),
            ])),
          ]),
        ),
      ),
    );
  }

  Color _bgColor(_NotifType t) {
    switch (t) {
      case _NotifType.session: return const Color(0xFFEEF0FF);
      case _NotifType.mood: return const Color(0xFFFFF8E1);
      case _NotifType.payment: return const Color(0xFFE8FFF1);
      case _NotifType.promo: return const Color(0xFFFCE4EC);
      case _NotifType.system: return const Color(0xFFF2F2F7);
    }
  }

  String _emoji(_NotifType t) {
    switch (t) {
      case _NotifType.session: return '🎧';
      case _NotifType.mood: return '💭';
      case _NotifType.payment: return '💳';
      case _NotifType.promo: return '🎁';
      case _NotifType.system: return '🔔';
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

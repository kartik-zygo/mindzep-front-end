import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';

class BroadcastCallPage extends StatefulWidget {
  const BroadcastCallPage({super.key});

  @override
  State<BroadcastCallPage> createState() => _BroadcastCallPageState();
}

class _BroadcastCallPageState extends State<BroadcastCallPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _ring1, _ring2, _ring3;
  int _elapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _ring1 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ringCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _ring2 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.2, 0.9, curve: Curves.easeOut)));
    _ring3 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed_str {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final available = MockData.psychologists.where((p) => p.status == AvailabilityStatus.available).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.go(RouteNames.userHome),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFF9500), size: 14),
                    const SizedBox(width: 4),
                    Text(_elapsed_str, style: const TextStyle(color: Color(0xFFFF9500), fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),

            const Spacer(),

            // Radar animation
            SizedBox(
              width: 260, height: 260,
              child: Stack(alignment: Alignment.center, children: [
                // Pulse rings
                ...[_ring1, _ring2, _ring3].map((anim) => AnimatedBuilder(
                  animation: anim,
                  builder: (_, __) => Opacity(
                    opacity: (1 - anim.value).clamp(0, 1),
                    child: Container(
                      width: 80 + anim.value * 160,
                      height: 80 + anim.value * 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF5E5CE6).withOpacity(0.4), width: 1.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )),
                // Center icon
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF5E5CE6).withOpacity(0.2 + _pulseCtrl.value * 0.3),
                        blurRadius: 30 + _pulseCtrl.value * 20,
                        spreadRadius: 0,
                      )],
                    ),
                    child: const Icon(Icons.radio_rounded, color: Colors.white, size: 44),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 28),
            const Text('Broadcasting...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Connecting to the first available therapist',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),

            const SizedBox(height: 32),

            // Available therapists row
            if (available.isNotEmpty) ...[
              const Text('Therapists being notified', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final p = available[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF34C759).withOpacity(0.4 + _pulseCtrl.value * 0.4),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: AppAvatar(
                                imageUrl: p.avatarUrl,
                                radius: 22,
                                initials: p.name[0],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(p.name.split(' ').first, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10)),
                      ]),
                    );
                  },
                ),
              ),
            ],

            const Spacer(),

            // Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
              child: GestureDetector(
                onTap: () => context.go(RouteNames.userHome),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Cancel Broadcast', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

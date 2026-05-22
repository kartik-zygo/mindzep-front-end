import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../injection/injection_container.dart';
import '../../../data/models/user_models.dart';
import '../../../data/repositories/user_repository.dart';

// ─── Mood Config ──────────────────────────────────────────────────────────────

class _MoodConfig {
  final String title;
  final String message;
  final String tip;
  final Color accent;

  const _MoodConfig(this.title, this.message, this.tip, this.accent);
}

const _moodConfigs = <String, _MoodConfig>{
  'Anxious': _MoodConfig(
    "It's okay to feel this way",
    "Anxiety is a signal, not a verdict. You're braver than you think — let's take it one breath at a time.",
    "Tip: Even 2 minutes of slow breathing can calm your nervous system.",
    Color(0xFFF59E0B),
  ),
  'Sad': _MoodConfig(
    "Your feelings are valid",
    "Sadness is part of being human. Be gentle with yourself today — the sun always comes back.",
    "Tip: Talking to someone you trust can lighten the heaviest feelings.",
    Color(0xFF3B82F6),
  ),
  'Stressed': _MoodConfig(
    "You're doing a lot",
    "Stress means you care. It's okay to pause, reset, and come back stronger. You don't have to carry it all alone.",
    "Tip: A quick 5-minute walk can reduce stress hormones by up to 20%.",
    Color(0xFFEF4444),
  ),
  'Okay': _MoodConfig(
    "Good to check in!",
    "Being okay is a solid place to be. Small steps forward still count as progress — keep going.",
    "Tip: Celebrating small wins builds positive momentum day by day.",
    Color(0xFF10B981),
  ),
  'Good': _MoodConfig(
    "Love that energy! ✨",
    "Your good mood matters — both for you and everyone around you. Keep nurturing it!",
    "Tip: Sharing positivity with others multiplies it for yourself too.",
    Color(0xFF8B5CF6),
  ),
};

// ─── Public API ───────────────────────────────────────────────────────────────

class MoodSheet {
  static void show(BuildContext context, Map<String, dynamic> mood) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _MoodSheetContent(mood: mood),
    );
  }
}

// ─── Sheet Content ────────────────────────────────────────────────────────────

class _MoodSheetContent extends StatefulWidget {
  final Map<String, dynamic> mood;
  const _MoodSheetContent({required this.mood});

  @override
  State<_MoodSheetContent> createState() => _MoodSheetContentState();
}

class _MoodSheetContentState extends State<_MoodSheetContent> {
  bool _showBreathing = false;
  bool _logged = false;
  bool _logging = false;

  Future<void> _logMood() async {
    if (_logged || _logging) return;
    setState(() => _logging = true);
    final score = (widget.mood['score'] as int?) ?? 3;
    final tag = (widget.mood['apiTag'] as String?) ?? (widget.mood['label'] as String?)?.toLowerCase();
    try {
      await sl<UserRepository>().createMood(MoodCreateRequest(score: score, tag: tag));
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _logging = false;
      _logged = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.mood['label'] as String;
    final emoji = widget.mood['emoji'] as String;
    final bgColor = Color(widget.mood['color'] as int);
    final cfg = _moodConfigs[label] ?? _moodConfigs['Okay']!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showBreathing
                ? _BreathingView(key: const ValueKey('breathe'), onBack: () => setState(() => _showBreathing = false))
                : _MainView(
                    key: const ValueKey('main'),
                    label: label, emoji: emoji, bgColor: bgColor, cfg: cfg,
                    logged: _logged,
                    logging: _logging,
                    onBreath: () => setState(() => _showBreathing = true),
                    onLog: _logMood,
                    onTalkNow: () {
                      Navigator.of(context).pop();
                      context.go(RouteNames.userConsult);
                    },
                    onReadArticle: () {
                      Navigator.of(context).pop();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────

class _MainView extends StatelessWidget {
  final String label, emoji;
  final Color bgColor;
  final _MoodConfig cfg;
  final bool logged;
  final bool logging;
  final VoidCallback onBreath, onLog, onTalkNow, onReadArticle;

  const _MainView({
    super.key,
    required this.label, required this.emoji, required this.bgColor,
    required this.cfg, required this.logged, this.logging = false,
    required this.onBreath, required this.onLog, required this.onTalkNow, required this.onReadArticle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8E8E93)),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Mood header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FEELING ${label.toUpperCase()}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cfg.accent, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cfg.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1E)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cfg.message,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF3C3C3C), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tip row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082), width: 1),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(cfg.tip, style: const TextStyle(fontSize: 12, color: Color(0xFF5C4500))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions section
          const Text(
            'What would help right now?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.headphones_rounded,
            label: 'Talk to a Therapist',
            sub: 'Instant support',
            color: const Color(0xFF5E5CE6),
            bg: const Color(0xFFEEF0FF),
            onTap: onTalkNow,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.air_rounded,
            label: 'Breathing Exercise',
            sub: '4-7-8 technique',
            color: const Color(0xFF30B0C7),
            bg: const Color(0xFFE6F8FA),
            onTap: onBreath,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.menu_book_rounded,
            label: 'Read an Article',
            sub: 'By our experts',
            color: const Color(0xFF34C759),
            bg: const Color(0xFFE8FFF1),
            onTap: onReadArticle,
          ),
          const SizedBox(height: 20),

          // Log button
          GestureDetector(
            onTap: (logged || logging) ? null : onLog,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: logged
                    ? const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30D158)])
                    : const LinearGradient(colors: [Color(0xFFFF9F0A), Color(0xFFFF6B00)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: (logged ? const Color(0xFF34C759) : const Color(0xFFFF9500)).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (logging)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    Icon(logged ? Icons.check_circle_rounded : Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    logged ? 'Mood Logged! 🎉' : (logging ? 'Logging...' : 'Log "$label" Mood'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color, bg;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.sub, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Breathing Exercise View ──────────────────────────────────────────────────

class _BreathingView extends StatefulWidget {
  final VoidCallback onBack;
  const _BreathingView({super.key, required this.onBack});

  @override
  State<_BreathingView> createState() => _BreathingViewState();
}

class _BreathingViewState extends State<_BreathingView> with SingleTickerProviderStateMixin {
  static const _phases = [
    {'label': 'Inhale', 'duration': 4, 'color': Color(0xFF30B0C7)},
    {'label': 'Hold', 'duration': 7, 'color': Color(0xFF8B7CF6)},
    {'label': 'Exhale', 'duration': 8, 'color': Color(0xFF34C7A3)},
  ];

  int _phaseIdx = 0;
  int _count = 4;
  int _cycles = 0;
  bool _done = false;
  Timer? _timer;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this);
    _startPhase();
  }

  void _startPhase() {
    final phase = _phases[_phaseIdx];
    final duration = phase['duration'] as int;
    setState(() => _count = duration);

    _scaleCtrl.duration = Duration(seconds: duration);
    _scaleCtrl.reset();
    if (_phaseIdx == 0) {
      _scaleAnim = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
      _scaleCtrl.forward();
    } else if (_phaseIdx == 1) {
      _scaleAnim = Tween<double>(begin: 1.5, end: 1.5).animate(_scaleCtrl);
    } else {
      _scaleAnim = Tween<double>(begin: 1.5, end: 1.0).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
      _scaleCtrl.forward();
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _count--;
        if (_count <= 0) {
          t.cancel();
          _nextPhase();
        }
      });
    });
  }

  void _nextPhase() {
    final next = (_phaseIdx + 1) % 3;
    if (_phaseIdx == 2) {
      final newCycles = _cycles + 1;
      if (newCycles >= 3) {
        setState(() { _done = true; _cycles = newCycles; });
        return;
      }
      setState(() => _cycles = newCycles);
    }
    setState(() => _phaseIdx = next);
    _startPhase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_phaseIdx];
    final color = phase['color'] as Color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          // Back
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(children: [
              Icon(Icons.arrow_back_ios_rounded, size: 14, color: Color(0xFF8E8E93)),
              SizedBox(width: 4),
              Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93))),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('4-7-8 Breathing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 4),
          Text(
            _done ? 'Well done! 🎉' : 'Follow the circle • ${3 - _cycles} round${(3 - _cycles) == 1 ? '' : 's'} left',
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 28),

          if (_done) ...[
            Container(
              width: 140, height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30B0C7)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text("You've completed 3 full breathing cycles.", textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ] else ...[
            AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, __) => SizedBox(
                width: 200, height: 200,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _scaleAnim.value * 1.12,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                        ),
                      ),
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.5)]),
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$_count', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              Text(phase['label'] as String, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Phase indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final p = _phases[i];
                final pColor = p['color'] as Color;
                final active = i == _phaseIdx;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: active ? 12 : 8,
                      height: active ? 12 : 8,
                      decoration: BoxDecoration(color: active ? pColor : const Color(0xFFE5E5EA), shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 4),
                    Text(p['label'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
                  ]),
                );
              }),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

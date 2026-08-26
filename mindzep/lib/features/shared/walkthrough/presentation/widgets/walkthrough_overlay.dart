import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/walkthrough_step.dart';

/// Full-screen coach-mark overlay: dims the app, punches a spotlight around the
/// current step's target and anchors an explanation card beside it.
///
/// Pushed as a transparent route so the page underneath stays mounted — that is
/// what keeps every [GlobalKey] target measurable while the tour runs.
class WalkthroughOverlay extends StatefulWidget {
  const WalkthroughOverlay({
    super.key,
    required this.steps,
    this.accentColor = const Color(0xFF5E5CE6),
    this.secondaryColor = const Color(0xFF8B7CF6),
  });

  final List<WalkthroughStep> steps;
  final Color accentColor;
  final Color secondaryColor;

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay>
    with TickerProviderStateMixin {
  static const _scrimColor = Color(0xE60B0B14);

  late final AnimationController _pulseController;
  late final AnimationController _cardController;

  int _index = 0;
  Rect? _spotlight;

  /// Suppresses navigation while a step transition is mid-flight, so a fast
  /// double tap cannot skip two steps at once.
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyStep(0));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  WalkthroughStep get _step => widget.steps[_index];

  bool get _isFirst => _index == 0;

  bool get _isLast => _index == widget.steps.length - 1;

  // ── Step navigation ────────────────────────────────────────────────────────

  Future<void> _applyStep(int index) async {
    if (!mounted) return;
    setState(() {
      _index = index;
      _transitioning = true;
    });
    _cardController.value = 0;

    final step = widget.steps[index];
    await _ensureTargetVisible(step);
    if (!mounted) return;

    setState(() {
      _spotlight = _resolveSpotlight(step);
      _transitioning = false;
    });
    _cardController.forward();
  }

  /// Scrolls the target back into view when it sits outside the viewport, then
  /// waits for the scroll to settle before its rect is measured.
  Future<void> _ensureTargetVisible(WalkthroughStep step) async {
    final targetContext = step.targetKey?.currentContext;
    if (targetContext == null) return;
    if (Scrollable.maybeOf(targetContext) == null) return;

    try {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        alignment: 0.35,
      );
    } catch (_) {
      // A detached or shrink-wrapped scrollable can throw — the step then
      // falls back to a centered card.
    }
    // Let the scroll settle so localToGlobal reports the final position.
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  Rect? _resolveSpotlight(WalkthroughStep step) {
    final targetContext = step.targetKey?.currentContext;
    if (targetContext == null) return null;

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;

    final origin = box.localToGlobal(Offset.zero);
    final rect = (origin & box.size).inflate(step.spotlightPadding);
    final screen = MediaQuery.sizeOf(context);

    // Ignore targets that have scrolled fully off screen.
    if (rect.bottom < 0 || rect.top > screen.height) return null;
    if (rect.right < 0 || rect.left > screen.width) return null;

    return Rect.fromLTRB(
      rect.left.clamp(0.0, screen.width),
      rect.top.clamp(0.0, screen.height),
      rect.right.clamp(0.0, screen.width),
      rect.bottom.clamp(0.0, screen.height),
    );
  }

  void _next() {
    if (_transitioning) return;
    if (_isLast) {
      _finish();
    } else {
      HapticFeedback.selectionClick();
      _applyStep(_index + 1);
    }
  }

  void _back() {
    if (_transitioning || _isFirst) return;
    HapticFeedback.selectionClick();
    _applyStep(_index - 1);
  }

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final spotlight = _spotlight;

    return PopScope(
      // Android back exits the tour rather than the page underneath.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: Stack(
            children: [
              // Dimmed backdrop with the spotlight cut out.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => CustomPaint(
                    painter: _SpotlightPainter(
                      spotlight: spotlight,
                      shape: _step.shape,
                      borderRadius: _step.borderRadius,
                      scrimColor: _scrimColor,
                      ringColor: widget.secondaryColor,
                      pulse: _pulseController.value,
                    ),
                  ),
                ),
              ),

              // Explanation card.
              _buildCard(size, padding, spotlight),

              // Skip affordance, always reachable.
              Positioned(
                top: padding.top + 8,
                right: 16,
                child: _SkipButton(onTap: _finish),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Size size, EdgeInsets padding, Rect? spotlight) {
    const cardMargin = 20.0;
    const gap = 16.0;

    // Below the spotlight when it sits in the upper part of the screen,
    // above it otherwise. Centered when there is nothing to point at.
    final placeBelow =
        spotlight == null || spotlight.center.dy < size.height * 0.52;

    final card = _WalkthroughCard(
      step: _step,
      index: _index,
      total: widget.steps.length,
      accentColor: widget.accentColor,
      secondaryColor: widget.secondaryColor,
      isFirst: _isFirst,
      isLast: _isLast,
      onNext: _next,
      onBack: _back,
      onSkip: _finish,
      pointsUp: placeBelow,
      arrowDx: spotlight?.center.dx.clamp(
        cardMargin + 24,
        size.width - cardMargin - 24,
      ),
    );

    final animatedCard = FadeTransition(
      opacity: _cardController,
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: Offset(0, placeBelow ? -0.04 : 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _cardController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: card,
      ),
    );

    if (spotlight == null) {
      return Positioned(
        left: cardMargin,
        right: cardMargin,
        top: 0,
        bottom: 0,
        child: Center(child: animatedCard),
      );
    }

    if (placeBelow) {
      return Positioned(
        left: cardMargin,
        right: cardMargin,
        top: (spotlight.bottom + gap).clamp(padding.top + 56, size.height - 120),
        child: animatedCard,
      );
    }

    return Positioned(
      left: cardMargin,
      right: cardMargin,
      bottom: (size.height - spotlight.top + gap).clamp(
        padding.bottom + 16,
        size.height - 120,
      ),
      child: animatedCard,
    );
  }
}

// ── Spotlight painter ────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.spotlight,
    required this.shape,
    required this.borderRadius,
    required this.scrimColor,
    required this.ringColor,
    required this.pulse,
  });

  final Rect? spotlight;
  final WalkthroughShape shape;
  final double borderRadius;
  final Color scrimColor;
  final Color ringColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final screenPath = Path()..addRect(Offset.zero & size);
    final rect = spotlight;

    if (rect == null) {
      canvas.drawPath(screenPath, Paint()..color = scrimColor);
      return;
    }

    final holePath = _holePath(rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, screenPath, holePath),
      Paint()..color = scrimColor,
    );

    // Solid rim plus a breathing halo that draws the eye to the target.
    canvas.drawPath(
      holePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      _holePath(rect.inflate(4 + pulse * 8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ringColor.withValues(alpha: (1 - pulse) * 0.55),
    );
  }

  Path _holePath(Rect rect) {
    if (shape == WalkthroughShape.circle) {
      return Path()..addOval(
        Rect.fromCircle(center: rect.center, radius: rect.longestSide / 2),
      );
    }
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlight != spotlight ||
      old.shape != shape ||
      old.pulse != pulse ||
      old.borderRadius != borderRadius;
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _WalkthroughCard extends StatelessWidget {
  const _WalkthroughCard({
    required this.step,
    required this.index,
    required this.total,
    required this.accentColor,
    required this.secondaryColor,
    required this.isFirst,
    required this.isLast,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    required this.pointsUp,
    required this.arrowDx,
  });

  final WalkthroughStep step;
  final int index;
  final int total;
  final Color accentColor;
  final Color secondaryColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  /// True when the card sits below the spotlight and its caret points up.
  final bool pointsUp;
  final double? arrowDx;

  @override
  Widget build(BuildContext context) {
    final body = GestureDetector(
      // Swallow taps on the card itself so only its buttons act.
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (step.icon != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(step.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C1C1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}/$total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF56565A),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(
                  child: _ProgressDots(
                    count: total,
                    activeIndex: index,
                    activeColor: accentColor,
                  ),
                ),
                const Spacer(),
                if (!isFirst)
                  TextButton(
                    onPressed: onBack,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: const Color(0xFF8E8E93),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                _PrimaryPill(
                  label: isLast ? 'Got it' : 'Next',
                  accentColor: accentColor,
                  secondaryColor: secondaryColor,
                  onTap: onNext,
                ),
              ],
            ),
            if (!isLast)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    foregroundColor: const Color(0xFF9A9AA0),
                  ),
                  child: const Text(
                    'Skip tour',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final dx = arrowDx;
    if (dx == null) return body;

    final arrow = _CardArrow(pointsUp: pointsUp, dx: dx);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: pointsUp ? [arrow, body] : [body, arrow],
    );
  }
}

/// Little caret linking the card back to the highlighted element.
class _CardArrow extends StatelessWidget {
  const _CardArrow({required this.pointsUp, required this.dx});

  final bool pointsUp;

  /// Global x of the spotlight centre the caret should aim at.
  final double dx;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The card is laid out with a fixed side margin, so the caret's global
        // origin equals that margin; keep the maths tolerant either way.
        final left = (dx - _cardLeftMargin - 9).clamp(
          12.0,
          (constraints.maxWidth - 30).clamp(12.0, double.infinity),
        );
        return SizedBox(
          height: 9,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                left: left,
                child: CustomPaint(
                  size: const Size(18, 9),
                  painter: _ArrowPainter(pointsUp: pointsUp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const double _cardLeftMargin = 20;
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.pointsUp});

  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.pointsUp != pointsUp;
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 5),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? activeColor : const Color(0xFFD9D9DE),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    required this.label,
    required this.accentColor,
    required this.secondaryColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.close_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

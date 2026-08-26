import 'dart:ui';
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// MindZep · Psychologist design system
///
/// A single source of truth for the psychologist-facing visual language so
/// every screen shares the same palette, depth, radii and building blocks.
/// ──────────────────────────────────────────────────────────────────────────

class PsychPalette {
  PsychPalette._();

  // Brand teal
  static const Color tealDeep = Color(0xFF1E96AB);
  static const Color teal = Color(0xFF2BB6C9);
  static const Color tealLight = Color(0xFF34C7A3);
  static const Color tealMist = Color(0xFFE6F8FA);
  static const Color tealMistStrong = Color(0xFFD3F1EE);

  // Rich, layered header gradient (top-left → bottom-right)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1B9FB4), Color(0xFF2BB6C9), Color(0xFF38CBA6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Compact 2-stop gradient for buttons / accents
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF2BB6C9), Color(0xFF34C7A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surfaces
  static const Color scaffold = Color(0xFFF1F5F7);
  static const Color surface = Colors.white;

  // Ink
  static const Color ink = Color(0xFF13212B);
  static const Color inkSoft = Color(0xFF67727B);
  static const Color inkFaint = Color(0xFF9AA6AE);

  // Semantic
  static const Color success = Color(0xFF2BC48A);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color info = Color(0xFF2BB6C9);

  // Hairline
  static const Color line = Color(0xFFEAEEF1);
}

class PsychRadii {
  PsychRadii._();
  static const double card = 22;
  static const double tile = 16;
  static const double chip = 12;
  static const double pill = 100;
}

class PsychShadows {
  PsychShadows._();

  /// Soft elevation for primary cards.
  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x12121A2E),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// Lighter elevation for list tiles.
  static List<BoxShadow> get tile => const [
        BoxShadow(
          color: Color(0x0D121A2E),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  /// Colored glow used under primary CTAs and feature cards.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Scaffold background tuned for the psychologist area.
class PsychScaffold extends StatelessWidget {
  final Widget body;
  final Key? scaffoldKey;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const PsychScaffold({
    super.key,
    required this.body,
    this.scaffoldKey,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: PsychPalette.scaffold,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

/// Rounded gradient header with subtle decorative blobs for depth.
/// Pass [child] as the header content (already padded internally).
class PsychGradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double bottomRadius;

  const PsychGradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 22),
    this.bottomRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(bottomRadius),
        bottomRight: Radius.circular(bottomRadius),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: PsychPalette.headerGradient),
        child: Stack(
          children: [
            // Decorative soft blobs
            Positioned(
              top: -50,
              right: -30,
              child: _blob(150, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: _blob(160, Colors.white.withValues(alpha: 0.07)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// White rounded card with the shared soft shadow.
class PsychCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;

  const PsychCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? PsychRadii.card;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? PsychPalette.surface,
        borderRadius: BorderRadius.circular(r),
        boxShadow: PsychShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: content,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: content,
        ),
      ),
    );
  }
}

/// Frosted glass tile used over the gradient header (stat cells etc.).
class PsychGlassTile extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const PsychGlassTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A glass stat cell (value + label) for headers.
class PsychGlassStat extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String value;
  final String label;

  const PsychGlassStat({
    super.key,
    this.icon,
    this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PsychGlassTile(
        child: Column(
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor ?? Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(height: 7),
            ],
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                height: 1.25,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section heading with an accent bar + optional trailing action.
class PsychSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PsychSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: PsychPalette.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: PsychPalette.ink,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PsychPalette.teal,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: PsychPalette.teal),
              ],
            ),
          ),
      ],
    );
  }
}

/// Primary gradient pill button with a soft glow.
class PsychPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  const PsychPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? PsychPalette.brandGradient : null,
        color: enabled ? null : PsychPalette.inkFaint,
        borderRadius: BorderRadius.circular(PsychRadii.pill),
        boxShadow: enabled ? PsychShadows.glow(PsychPalette.teal) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(PsychRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: isLoading
                  ? const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ]
                  : [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 19),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
    return button;
  }
}

/// Rounded icon button (e.g. header actions) with a translucent fill.
class PsychGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const PsychGlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.20),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

/// Friendly empty-state block used inside cards / lists.
class PsychEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const PsychEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [PsychPalette.tealMist, PsychPalette.tealMistStrong],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: PsychPalette.tealDeep, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: PsychPalette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: PsychPalette.inkSoft,
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Status pill (Available / Booked / Published …) with tinted background.
class PsychStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const PsychStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 10 : 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PsychRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fade + rise entrance animation wrapper for list/section content.
class PsychFadeIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;

  const PsychFadeIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        // Hold at 0 for the delay portion, then animate.
        final total = duration.inMilliseconds + delayMs;
        final start = delayMs / total;
        final progress =
            t <= start ? 0.0 : ((t - start) / (1 - start)).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

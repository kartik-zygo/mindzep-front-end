import 'package:flutter/material.dart';

/// Shape of the spotlight cut-out drawn around a walkthrough target.
enum WalkthroughShape {
  /// Rounded rectangle — cards, banners, rows.
  rounded,

  /// Perfect circle — avatars, icon buttons.
  circle,
}

/// A single stop in a guided product tour.
///
/// When [targetKey] resolves to a laid-out widget the overlay punches a
/// spotlight around it and anchors the explanation card next to it.  When it is
/// `null` (or the widget is not on screen) the step falls back to a centered
/// card — used for the welcome and wrap-up stops.
class WalkthroughStep {
  const WalkthroughStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.icon,
    this.shape = WalkthroughShape.rounded,
    this.spotlightPadding = 8,
    this.borderRadius = 18,
  });

  final String title;
  final String description;
  final GlobalKey? targetKey;
  final IconData? icon;
  final WalkthroughShape shape;

  /// Extra breathing room between the target's bounds and the cut-out edge.
  final double spotlightPadding;

  /// Corner radius used when [shape] is [WalkthroughShape.rounded].
  final double borderRadius;

  bool get isCentered => targetKey == null;
}

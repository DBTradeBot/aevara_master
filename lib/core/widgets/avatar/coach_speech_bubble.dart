// lib/core/widgets/avatar/coach_speech_bubble.dart
//
// CoachSpeechBubble — iOS-style chat bubble (rounded rect + tapered nip).
// • Single Material shape (body + tail share one shadow).
// • Tail on any side; slide with tailOffset (0..1).
// • Fill color comes from Theme.scaffoldBackgroundColor, so you can tint it
//   via a local Theme in the parent.
//
// Notes:
// - Implemented with a ShapeBorder so Material elevation renders correctly.
// - Dart 2 compatible (no switch-expressions); clamp() casts to double.

import 'package:flutter/material.dart';

/// Which side of the bubble the tail should appear on.
enum BubbleTail {
  none,
  left,
  right,
  topLeft,
  topRight,
  topCenter,
  bottomLeft,
  bottomRight,
  bottomCenter,
}

class CoachSpeechBubble extends StatelessWidget {
  const CoachSpeechBubble({
    super.key,
    required this.text,
    this.maxWidth = 320,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 14,
    this.tail = BubbleTail.topLeft,
    this.tailSize = 14,               // iOS-ish nip height
    this.tailOffset,                  // 0..1; null -> sensible default per side
    this.semanticPrefix = "Coach says:",
    this.textStyle,
    this.maxLines,
    this.safeHorizontalInset = 0,
    this.elevation = 6,
  });

  final String text;
  final double maxWidth;
  final EdgeInsets padding;
  final double borderRadius;
  final BubbleTail tail;
  final double tailSize;
  final double? tailOffset; // 0..1
  final String semanticPrefix;
  final TextStyle? textStyle;
  final int? maxLines;
  final double safeHorizontalInset;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final fg = theme.colorScheme.onSurface;

    final TextStyle baseStyle =
        textStyle ??
            theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600) ??
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600);

    // Sensible default offset if not provided.
    double resolvedOffset;
    if (tail == BubbleTail.topCenter || tail == BubbleTail.bottomCenter) {
      resolvedOffset = 0.50;
    } else if (tail == BubbleTail.topLeft || tail == BubbleTail.bottomLeft) {
      resolvedOffset = 0.16; // bias left by default for avatar alignment
    } else if (tail == BubbleTail.topRight || tail == BubbleTail.bottomRight) {
      resolvedOffset = 0.84;
    } else if (tail == BubbleTail.left || tail == BubbleTail.right) {
      resolvedOffset = 0.40;
    } else {
      resolvedOffset = 0.40;
    }
    if (tailOffset != null) resolvedOffset = tailOffset!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: safeHorizontalInset),
      child: Semantics(
        label: '$semanticPrefix $text',
        child: Material(
          color: bg,
          elevation: elevation,
          shadowColor: Colors.black.withOpacity(
            theme.brightness == Brightness.light ? 0.10 : 0.45,
          ),
          shape: _IosBubbleBorder(
            radius: borderRadius,
            tail: tail,
            tailSize: tailSize,
            tailOffset: resolvedOffset.clamp(0.0, 1.0).toDouble(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: Text(
                text,
                softWrap: true,
                maxLines: maxLines,
                overflow:
                maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
                style: baseStyle.copyWith(color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style border: rounded rect + small gently-rounded nip.
/// Nip is a tapered wedge (not a bulb), with subtle curvature like iMessage.
class _IosBubbleBorder extends ShapeBorder {
  const _IosBubbleBorder({
    required this.radius,
    required this.tail,
    required this.tailSize,
    required this.tailOffset, // 0..1 along the chosen edge
  });

  final double radius;
  final BubbleTail tail;
  final double tailSize;
  final double tailOffset;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => _IosBubbleBorder(
    radius: radius * t,
    tail: tail,
    tailSize: tailSize * t,
    tailOffset: tailOffset,
  );

  // Inner path: slightly deflated rounded-rect (no tail) for ink/clipping.
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final rr = RRect.fromRectAndRadius(rect.deflate(1.0), Radius.circular(radius));
    return Path()..addRRect(rr);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final Path path = Path()..addRRect(rrect);

    if (tail == BubbleTail.none) return path;

    // Nip metrics tuned to read clearly in a hero header.
    final double h = tailSize;         // nip height
    final double base = h * 1.2;       // width where nip meets body
    final double round = h * 0.28;     // subtle curvature

    // To avoid corner collisions, clamp inside edges.
    double _clampX(double x) {
      final double leftLimit  = rect.left + radius + base * 0.6;
      final double rightLimit = rect.right - radius - base * 0.6;
      if (x < leftLimit) return leftLimit;
      if (x > rightLimit) return rightLimit;
      return x;
    }
    double _clampY(double y) {
      final double topLimit    = rect.top + radius + base * 0.6;
      final double bottomLimit = rect.bottom - radius - base * 0.6;
      if (y < topLimit) return topLimit;
      if (y > bottomLimit) return bottomLimit;
      return y;
    }

    // Top nip (extends above rect).
    void _addTopTail(double x) {
      x = _clampX(x);
      final double y = rect.top;
      final Path t = Path()
        ..moveTo(x - base / 2, y)
        ..quadraticBezierTo(x - base / 2, y - round, x, y - h)
        ..quadraticBezierTo(x + base / 2, y - round, x + base / 2, y)
        ..close();
      path.addPath(t, Offset.zero);
    }

    // Bottom nip (extends below rect).
    void _addBottomTail(double x) {
      x = _clampX(x);
      final double y = rect.bottom;
      final Path t = Path()
        ..moveTo(x - base / 2, y)
        ..quadraticBezierTo(x - base / 2, y + round, x, y + h)
        ..quadraticBezierTo(x + base / 2, y + round, x + base / 2, y)
        ..close();
      path.addPath(t, Offset.zero);
    }

    // Left nip (extends to the left).
    void _addLeftTail(double y) {
      y = _clampY(y);
      final double x = rect.left;
      final Path t = Path()
        ..moveTo(x, y - base / 2)
        ..quadraticBezierTo(x - round, y - base / 2, x - h, y)
        ..quadraticBezierTo(x - round, y + base / 2, x, y + base / 2)
        ..close();
      path.addPath(t, Offset.zero);
    }

    // Right nip (extends to the right).
    void _addRightTail(double y) {
      y = _clampY(y);
      final double x = rect.right;
      final Path t = Path()
        ..moveTo(x, y - base / 2)
        ..quadraticBezierTo(x + round, y - base / 2, x + h, y)
        ..quadraticBezierTo(x + round, y + base / 2, x, y + base / 2)
        ..close();
      path.addPath(t, Offset.zero);
    }

    // Choose position per side (Dart-2 compatible logic).
    if (tail == BubbleTail.topLeft ||
        tail == BubbleTail.topRight ||
        tail == BubbleTail.topCenter) {
      final double xTop =
      (tail == BubbleTail.topCenter) ? (rect.left + rect.width * 0.5)
          : (rect.left + rect.width * tailOffset);
      _addTopTail(xTop);
    } else if (tail == BubbleTail.bottomLeft ||
        tail == BubbleTail.bottomRight ||
        tail == BubbleTail.bottomCenter) {
      final double xBot =
      (tail == BubbleTail.bottomCenter) ? (rect.left + rect.width * 0.5)
          : (rect.left + rect.width * tailOffset);
      _addBottomTail(xBot);
    } else if (tail == BubbleTail.left) {
      final double yL = rect.top + rect.height * tailOffset;
      _addLeftTail(yL);
    } else if (tail == BubbleTail.right) {
      final double yR = rect.top + rect.height * tailOffset;
      _addRightTail(yR);
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Material paints fill/shadow using the shape.
  }
}

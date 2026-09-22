import 'package:flutter/material.dart';

import '../../data/models/detection_result.dart';

/// Draws a normalized (0.0–1.0) [BoundingBox] onto whatever canvas
/// size it's given, with a small confidence-label tag above the box.
///
/// Used by the History detail screen (single persisted box) and
/// internally by [MultiBoxPainter].
class BoundingBoxPainter extends CustomPainter {
  const BoundingBoxPainter({
    required this.box,
    required this.color,
    required this.label,
    this.dashed = false,
    this.strokeWidth = 3,
    this.labelFontSize = 11,
  });

  final BoundingBox box;
  final Color color;
  final String label;
  final bool dashed;
  final double strokeWidth;
  final double labelFontSize;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBox(canvas, size, box, color, label, dashed, strokeWidth, labelFontSize);
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.box != box ||
        oldDelegate.color != color ||
        oldDelegate.label != label ||
        oldDelegate.dashed != dashed ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.labelFontSize != labelFontSize;
  }
}

/// Draws every box in [boxes] onto the canvas in a single pass.
///
/// All boxes share the same [color] and [dashed] style (driven by the
/// overall detection label). Each box shows its own per-box confidence
/// percentage as a tag, falling back to the top-level [fallbackLabel]
/// when per-box confidence is unavailable.
class MultiBoxPainter extends CustomPainter {
  const MultiBoxPainter({
    required this.boxes,
    required this.color,
    required this.fallbackLabel,
    this.dashed = false,
    this.strokeWidth = 4,
    this.labelFontSize = 13,
  });

  final List<BoundingBox> boxes;
  final Color color;
  final String fallbackLabel;
  final bool dashed;
  final double strokeWidth;
  final double labelFontSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in boxes) {
      final tag = box.confidence != null
          ? '${(box.confidence! * 100).round()}%'
          : fallbackLabel;
      _paintBox(canvas, size, box, color, tag, dashed, strokeWidth, labelFontSize);
    }
  }

  @override
  bool shouldRepaint(covariant MultiBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes ||
        oldDelegate.color != color ||
        oldDelegate.fallbackLabel != fallbackLabel ||
        oldDelegate.dashed != dashed ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.labelFontSize != labelFontSize;
  }
}

// ─── shared drawing logic ─────────────────────────────────────────────────────

void _paintBox(
  Canvas canvas,
  Size size,
  BoundingBox box,
  Color color,
  String label,
  bool dashed,
  double strokeWidth,
  double labelFontSize,
) {
  final rect = Rect.fromLTWH(
    box.left * size.width,
    box.top * size.height,
    box.width * size.width,
    box.height * size.height,
  );
  final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth;

  if (dashed) {
    _drawDashedRRect(canvas, rrect, paint);
  } else {
    canvas.drawRRect(rrect, paint);
  }

  // --- label tag ---
  // Measure text first so we can draw a solid background rect
  final textPainter = TextPainter(
    text: TextSpan(
      text: ' $label ',
      style: TextStyle(
        color: Colors.white,
        fontSize: labelFontSize,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final aboveBox = Offset(rect.left, rect.top - textPainter.height - 4);
  final tagOffset =
      aboveBox.dy < 0 ? Offset(rect.left, rect.top + 4) : aboveBox;

  // Solid filled background for the tag
  canvas.drawRect(
    Rect.fromLTWH(
      tagOffset.dx,
      tagOffset.dy,
      textPainter.width,
      textPainter.height,
    ),
    Paint()..color = color,
  );
  textPainter.paint(canvas, tagOffset);
}

void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
  const dashWidth = 6.0;
  const dashSpace = 4.0;
  final path = Path()..addRRect(rrect);
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final rawNext = distance + dashWidth;
      final next = rawNext > metric.length ? metric.length : rawNext;
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + dashSpace;
    }
  }
}

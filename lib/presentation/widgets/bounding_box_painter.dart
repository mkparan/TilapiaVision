
import 'package:flutter/material.dart';

import '../../data/models/detection_result.dart';

/// Draws a normalized (0.0–1.0) [BoundingBox] onto whatever canvas
/// size it's given, with a small confidence-label tag above the box.
class BoundingBoxPainter extends CustomPainter {
  const BoundingBoxPainter({
    required this.box,
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final BoundingBox box;
  final Color color;
  final String label;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
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
      ..strokeWidth = 3;

    if (dashed) {
      _drawDashedRRect(canvas, rrect, paint);
    } else {
      canvas.drawRRect(rrect, paint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: ' $label ',
        style: TextStyle(
          color: Colors.black.withOpacity(0.85),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          backgroundColor: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final aboveBox = Offset(rect.left, rect.top - textPainter.height - 4);
    final tagOffset = aboveBox.dy < 0 ? Offset(rect.left, rect.top + 4) : aboveBox;
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

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.color != color || oldDelegate.label != label || oldDelegate.dashed != dashed;
  }
}


import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Measure using the same scaler and font as the label, including accessibility
/// and Samsung display/font settings. Horizontal toolbars must grow, not wrap.
Size controlLabelSize(BuildContext context, String label, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final result = Size(
    painter.width.ceilToDouble(),
    painter.height.ceilToDouble(),
  );
  painter.dispose();
  return result;
}

/// Keeps a usable canvas on short landscape screens and large text settings.
class BoundedControls extends StatelessWidget {
  const BoundedControls({super.key, required this.child, required this.height});
  final Widget child;
  final double height;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: math.max(48, height)),
    child: SingleChildScrollView(child: child),
  );
}

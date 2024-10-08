import 'package:flutter/material.dart';

/// A widget that overlays inset shadows on a child.
class InsetShadowBox extends StatelessWidget {
  const InsetShadowBox({
    this.top = 0,
    this.bottom = 0,
    required this.color,
    required this.child,
  });

  /// The distance that the shadows from the child's top edge grows downwards.
  ///
  /// This does not pad the child widget.
  final double top;

  /// The distance that the shadows from the child's bottom edge grows upwards.
  ///
  /// This does not pad the child widget.
  final double bottom;

  /// The shadow color to fade into transparency from the top and bottom borders.
  final Color color;

  final Widget child;

  BoxDecoration _shadowFrom(AlignmentGeometry begin) {
    return BoxDecoration(gradient: LinearGradient(
      begin: begin, end: -begin,
      colors: [color, color.withValues(alpha: 0)]));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          child,
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: top, decoration: _shadowFrom(Alignment.topCenter))),
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(height: bottom, decoration: _shadowFrom(Alignment.bottomCenter))),
        ]);
  }
}

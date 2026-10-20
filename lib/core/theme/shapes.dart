import 'dart:ui' show lerpDouble;

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Squircle (iOS-style continuous corner) shapes used everywhere in the app.
class AppShapes {
  AppShapes._();

  /// Figma's "iOS" corner smoothing.
  static const smoothing = 0.6;

  /// Radius large enough to make any shape fully rounded (pill).
  static const pillRadius = 999.0;

  static SmoothBorderRadius radius(double r) => SmoothBorderRadius(cornerRadius: r, cornerSmoothing: smoothing);

  static SmoothRectangleBorder border(double r, {BorderSide side = BorderSide.none}) =>
      SmoothRectangleBorder(borderRadius: radius(r), side: side);

  static SmoothRectangleBorder pill({BorderSide side = BorderSide.none}) => border(pillRadius, side: side);

  /// Box decoration with a squircle outline, for plain containers.
  static ShapeDecoration decoration({required Color color, double r = 16, BorderSide side = BorderSide.none}) =>
      ShapeDecoration(color: color, shape: border(r, side: side));
}

/// Clips [child] to a squircle.
class Squircle extends StatelessWidget {
  const Squircle({super.key, required this.child, this.radius = 16});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipSmoothRect(radius: AppShapes.radius(radius), child: child);
}

/// An outlined [InputBorder] with squircle corners. Leaves a gap in the top
/// edge for the floating label, like [OutlineInputBorder].
class SquircleInputBorder extends InputBorder {
  const SquircleInputBorder({super.borderSide = const BorderSide(), this.radius = 16, this.gapPadding = 4});

  final double radius;
  final double gapPadding;

  SmoothBorderRadius get _radius => AppShapes.radius(radius);

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  SquircleInputBorder copyWith({BorderSide? borderSide, double? radius, double? gapPadding}) => SquircleInputBorder(
        borderSide: borderSide ?? this.borderSide,
        radius: radius ?? this.radius,
        gapPadding: gapPadding ?? this.gapPadding,
      );

  @override
  ShapeBorder scale(double t) =>
      SquircleInputBorder(borderSide: borderSide.scale(t), radius: radius * t, gapPadding: gapPadding * t);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _radius.toPath(rect.deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _radius.toPath(rect);

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint, {TextDirection? textDirection}) {
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  bool get preferPaintInterior => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) return;
    final path = _radius.toPath(rect.deflate(borderSide.width / 2));
    final paint = borderSide.toPaint();

    if (gapStart == null || gapExtent <= 0 || gapPercentage == 0) {
      canvas.drawPath(path, paint);
      return;
    }

    // Cut the floating label's gap out of the top edge.
    final extent = lerpDouble(0, gapExtent + gapPadding * 2, gapPercentage)!;
    final start = textDirection == TextDirection.rtl ? gapStart + gapPadding - extent : gapStart - gapPadding;
    final gap = Rect.fromLTWH(start, rect.top - borderSide.width, extent, borderSide.width * 3);
    canvas
      ..save()
      ..clipPath(
        Path.combine(PathOperation.difference, Path()..addRect(rect.inflate(borderSide.width * 2)), Path()..addRect(gap)),
      )
      ..drawPath(path, paint)
      ..restore();
  }

  @override
  bool operator ==(Object other) =>
      other is SquircleInputBorder &&
      other.borderSide == borderSide &&
      other.radius == radius &&
      other.gapPadding == gapPadding;

  @override
  int get hashCode => Object.hash(borderSide, radius, gapPadding);
}

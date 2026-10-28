import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// A frosted-glass surface: wraps [child] in a blurred, translucent panel
/// via [BackdropFilter] and [AyurezeTheme.glassDecoration]. Drop-in
/// replacement for `Container(decoration: AyurezeTheme.panelDecoration())`
/// (or `mutedPanelDecoration()`/`heroDecoration()`) wherever a screen wants
/// the liquid-glass look instead of a flat card. Needs something with color
/// behind it to refract - pair with [GlassBlob] or a gradient background,
/// since a frosted panel over a flat canvas looks identical to an opaque one.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AyurezeTheme.radiusCard,
    this.blur = 18,
    this.padding,
    this.margin,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            padding: padding,
            decoration: AyurezeTheme.glassDecoration(radius: radius),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A soft, blurred radial-gradient circle for [GlassSurface]s to refract.
/// Purely decorative - place a few behind scrollable content with
/// `Positioned`, absolutely positioned so they don't affect layout.
class GlassBlob extends StatelessWidget {
  final double size;
  final Color color;

  const GlassBlob({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:doctro/theme/ayureze_theme.dart';

class OslerCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showBorder;

  const OslerCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  State<OslerCard> createState() => _OslerCardState();
}

class _OslerCardState extends State<OslerCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: widget.margin,
        // The shadow sits on an outer box, BEHIND the card. It used to live
        // on the inner (colourless) container, so the blur painted on top of
        // the fill as a grey wash - invisible on the old off-white surface,
        // obvious on white.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusCard),
          boxShadow: [
            BoxShadow(
              color: _isPressed ? Colors.transparent : AyurezeTheme.shadow,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: widget.backgroundColor ?? AyurezeTheme.surface,
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusCard),
          child: InkWell(
            onTap: widget.onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onTap!();
                  },
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusCard),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  widget.padding ?? const EdgeInsets.all(AyurezeTheme.spaceXl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusCard),
                border: widget.showBorder
                    ? Border.all(color: AyurezeTheme.border)
                    : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

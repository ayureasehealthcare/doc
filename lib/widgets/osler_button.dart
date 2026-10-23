import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/app_motion.dart';

enum OslerButtonStyle { primary, secondary, outline, ghost }

class OslerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final OslerButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final Color? customColor;

  const OslerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = OslerButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = customColor ?? _getBackgroundColor();
    final fgColor = _getForegroundColor(bgColor);
    final tappable = !isLoading && onPressed != null;
    return Semantics(
      button: true,
      label: text,
      enabled: tappable,
      child: AnimatedTapScale(
        // Purely visual: the real tap still goes through ElevatedButton's
        // onPressed below, this only adds the press-in feel.
        onTap: tappable ? () {} : null,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !tappable
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              // While loading the button is disabled only to block taps;
              // keep its normal colours so the spinner stays legible
              // instead of white-on-grey.
              disabledBackgroundColor: isLoading ? bgColor : null,
              disabledForegroundColor: isLoading ? fgColor : null,
              // The label takes its colour from foregroundColor via the
              // button's DefaultTextStyle. Setting a style on the Text
              // itself would carry the theme's dark text colour and
              // override it - which is how primary labels ended up dark
              // on dark green.
              textStyle: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
                side: style == OslerButtonStyle.outline
                    ? BorderSide(color: bgColor)
                    : BorderSide.none,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fgColor,
                      ),
                    )
                  : Row(
                      key: const ValueKey('content'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon),
                          const SizedBox(width: 8),
                        ],
                        Text(text),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case OslerButtonStyle.primary:
        return AyurezeTheme.healingGreenFill;
      case OslerButtonStyle.secondary:
        return AyurezeTheme.healingGreen10;
      case OslerButtonStyle.outline:
      case OslerButtonStyle.ghost:
        return Colors.transparent;
    }
  }

  /// Label/icon colour for [bgColor]. Transparent (outline, ghost) buttons
  /// sit on the page, so they use the dark-aware text token; filled ones
  /// get whichever of white or the dark brand ink contrasts more with the
  /// fill, so a [customColor] can't silently produce an unreadable label.
  Color _getForegroundColor(Color bgColor) {
    if (bgColor.a == 0) return AyurezeTheme.textPrimary;
    const light = Colors.white;
    const dark = AyurezeTheme.healingGreen100;
    return _contrast(light, bgColor) >= _contrast(dark, bgColor) ? light : dark;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}

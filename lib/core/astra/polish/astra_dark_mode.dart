import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:hugeicons/hugeicons.dart';

/// Astra Dark Mode Support
///
/// Provides dark mode theming for Astra AI components.
/// Uses Material 3 dynamic color when available.
class AstraDarkMode {
  AstraDarkMode._();

  /// Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get Astra green color for dark mode
  static Color healingGreen50Dark(BuildContext context) {
    return isDarkMode(context)
        ? const Color(0xFF81C784) // Lighter green for dark bg
        : const Color(0xFF4CAF50);
  }

  /// Get text color for dark mode
  static Color textPrimaryDark(BuildContext context) {
    return isDarkMode(context)
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF212121);
  }

  /// Get secondary text color for dark mode
  static Color textSecondaryDark(BuildContext context) {
    return isDarkMode(context)
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF757575);
  }

  /// Get surface color for dark mode
  static Color surfaceDark(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;
  }

  /// Get background color for dark mode
  static Color backgroundDark(BuildContext context) {
    return isDarkMode(context)
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
  }

  /// Get card color for dark mode
  static Color cardDark(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF2D2D2D) : Colors.white;
  }

  /// Get border color for dark mode
  static Color borderDark(BuildContext context) {
    return isDarkMode(context)
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE0E0E0);
  }

  /// Get error color
  static Color errorDark(BuildContext context) {
    return isDarkMode(context)
        ? const Color(0xFFEF5350)
        : const Color(0xFFD32F2F);
  }
}

/// Dark mode aware container
class AstraDarkModeContainer extends StatelessWidget {
  final Widget child;
  final Widget? darkChild;

  const AstraDarkModeContainer({
    super.key,
    required this.child,
    this.darkChild,
  });

  @override
  Widget build(BuildContext context) {
    if (darkChild != null && AstraDarkMode.isDarkMode(context)) {
      return darkChild!;
    }
    return child;
  }
}

/// Dark mode aware text
class AstraDarkModeText extends StatelessWidget {
  final String text;
  final TextStyle? lightStyle;
  final TextStyle? darkStyle;

  const AstraDarkModeText({
    super.key,
    required this.text,
    this.lightStyle,
    this.darkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style = AstraDarkMode.isDarkMode(context) ? darkStyle : lightStyle;
    return Text(text, style: style);
  }
}

/// Dark mode aware icon color
class AstraDarkModeIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final double? size;
  final Color? lightColor;
  final Color? darkColor;

  const AstraDarkModeIcon({
    super.key,
    required this.icon,
    this.size,
    this.lightColor,
    this.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (AstraDarkMode.isDarkMode(context)) {
      color = darkColor ?? Colors.white70;
    } else {
      color = lightColor ?? Colors.black87;
    }
    return HugeIcon(icon: icon, size: size ?? 24.0, color: color);
  }
}

/// Dark mode aware card
class AstraDarkModeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;

  const AstraDarkModeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: AstraDarkMode.cardDark(context),
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
        border: Border.all(
          color: AstraDarkMode.borderDark(context),
        ),
        boxShadow: AstraDarkMode.isDarkMode(context)
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

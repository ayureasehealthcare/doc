import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Responsive Helpers
///
/// Provides responsive layout utilities for tablet and desktop support.
class AstraResponsive {
  AstraResponsive._();

  /// Check if current device is a phone
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  /// Check if current device is a tablet
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 && shortestSide < 900;
  }

  /// Check if current device is a desktop/large tablet
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 900;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return phone;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsive(
      context,
      phone: const EdgeInsets.all(AyurezeTheme.spaceLg),
      tablet: const EdgeInsets.all(AyurezeTheme.space2xl),
      desktop: const EdgeInsets.all(AyurezeTheme.space3xl),
    );
  }

  /// Get max content width (for desktop centering)
  static double maxContentWidth(BuildContext context) {
    return responsive(
      context,
      phone: double.infinity,
      tablet: 720,
      desktop: 1200,
    );
  }
}

/// Responsive builder widget
class AstraResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;
  final Widget? phone;
  final Widget? tablet;
  final Widget? desktop;

  const AstraResponsiveBuilder({
    super.key,
    required this.builder,
    this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = AstraResponsive.isDesktop(context)
        ? ScreenType.desktop
        : (AstraResponsive.isTablet(context)
            ? ScreenType.tablet
            : ScreenType.phone);

    if (phone != null && screenType == ScreenType.phone) {
      return phone!;
    }
    if (tablet != null && screenType == ScreenType.tablet) {
      return tablet!;
    }
    if (desktop != null && screenType == ScreenType.desktop) {
      return desktop!;
    }

    return builder(context, screenType);
  }
}

/// Screen type enum
enum ScreenType {
  phone,
  tablet,
  desktop,
}

/// Adaptive layout widget for master-detail views on tablets
class AstraMasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final double masterWidth;
  final bool showDetail;

  const AstraMasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterWidth = 320,
    this.showDetail = true,
  });

  @override
  Widget build(BuildContext context) {
    final isWide =
        AstraResponsive.isDesktop(context) || AstraResponsive.isTablet(context);

    if (isWide && detail != null && showDetail) {
      return Row(
        children: [
          SizedBox(width: masterWidth, child: master),
          const VerticalDivider(width: 1),
          Expanded(child: detail!),
        ],
      );
    }

    return master;
  }
}

/// Responsive grid
class AstraResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int phoneColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const AstraResponsiveGrid({
    super.key,
    required this.children,
    this.phoneColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = AstraResponsive.responsive(
      context,
      phone: phoneColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        final availableWidth =
            MediaQuery.of(context).size.width - (spacing * (columns + 1));
        final itemWidth = availableWidth / columns;
        return SizedBox(
          width: itemWidth,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Responsive text styles
class AstraResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? phoneStyle;
  final TextStyle? tabletStyle;
  final TextStyle? desktopStyle;

  const AstraResponsiveText({
    super.key,
    required this.text,
    this.phoneStyle,
    this.tabletStyle,
    this.desktopStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style = AstraResponsive.responsive(
          context,
          phone: phoneStyle,
          tablet: tabletStyle,
          desktop: desktopStyle,
        ) ??
        const TextStyle();

    return Text(text, style: style);
  }
}

/// Constrain width for large screens
class AstraConstrainedWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AstraConstrainedWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

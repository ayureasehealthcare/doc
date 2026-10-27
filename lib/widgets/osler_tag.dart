import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:hugeicons/hugeicons.dart';

enum OslerTagStyle { primary, secondary, success, warning, danger, info }

class OslerTag extends StatelessWidget {
  final String label;
  final OslerTagStyle style;
  final List<List<dynamic>>? icon;

  const OslerTag({
    super.key,
    required this.label,
    this.style = OslerTagStyle.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceMd, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            HugeIcon(icon: icon!, size: 14, color: _getForegroundColor()),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _getForegroundColor(),
                ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case OslerTagStyle.primary:
        return AyurezeTheme.healingGreen10;
      case OslerTagStyle.secondary:
        return AyurezeTheme.oslerGray10;
      case OslerTagStyle.success:
        return AyurezeTheme.healingGreen10;
      case OslerTagStyle.warning:
        return AyurezeTheme.sunshineYellow10;
      case OslerTagStyle.danger:
        return AyurezeTheme.remoteRed10;
      case OslerTagStyle.info:
        return AyurezeTheme.connectivityBlue10;
    }
  }

  Color _getForegroundColor() {
    switch (style) {
      case OslerTagStyle.primary:
        return AyurezeTheme.healingGreen100;
      case OslerTagStyle.secondary:
        return AyurezeTheme.oslerGray100;
      case OslerTagStyle.success:
        return AyurezeTheme.healingGreen100;
      case OslerTagStyle.warning:
        return AyurezeTheme.sunshineYellow100;
      case OslerTagStyle.danger:
        return AyurezeTheme.remoteRed100;
      case OslerTagStyle.info:
        return AyurezeTheme.connectivityBlue100;
    }
  }
}

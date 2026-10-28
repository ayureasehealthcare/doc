import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:hugeicons/hugeicons.dart';

enum OslerToastType { success, error, warning, info }

class OslerToast {
  static void show({
    required BuildContext context,
    required String message,
    OslerToastType type = OslerToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final Color backgroundColor;
    final Color textColor;
    final List<List<dynamic>> icon;

    switch (type) {
      case OslerToastType.success:
        backgroundColor = AyurezeTheme.healingGreen100;
        textColor = Colors.white;
        icon = HugeIcons.strokeRoundedCheckmarkCircle02;
        break;
      case OslerToastType.error:
        backgroundColor = AyurezeTheme.remoteRed100;
        textColor = Colors.white;
        icon = HugeIcons.strokeRoundedAlertCircle;
        break;
      case OslerToastType.warning:
        backgroundColor = AyurezeTheme.sunshineYellow100;
        textColor = Colors.black87;
        icon = HugeIcons.strokeRoundedAlert02;
        break;
      case OslerToastType.info:
        // Neutral sage ink, inverted in dark mode like a Material
        // snackbar: blue sat outside the Serene Herbalist palette.
        final dark = Theme.of(context).brightness == Brightness.dark;
        backgroundColor =
            dark ? AyurezeTheme.darkTextPrimary : AyurezeTheme.oslerGray100;
        textColor = dark ? AyurezeTheme.oslerGray100 : Colors.white;
        icon = HugeIcons.strokeRoundedInformationCircle;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            HugeIcon(icon: icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd)),
        duration: duration,
        margin: const EdgeInsets.all(AyurezeTheme.spaceLg),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context: context, message: message, type: OslerToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context: context, message: message, type: OslerToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context: context, message: message, type: OslerToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context: context, message: message, type: OslerToastType.info);
  }
}

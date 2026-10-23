import 'package:doctro/theme/ayureze_theme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// OslerModal — Animated, modern dialog system for the Ayureze app.
/// Supports danger, info, and confirmation modes.
class OslerModal {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String primaryText = 'OK',
    String? secondaryText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool isDanger = false,
    Widget? icon,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'OslerModal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: AyurezeTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AyurezeTheme.radius2xl),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: Column(
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isDanger
                        ? AyurezeTheme.remoteRed10
                        : AyurezeTheme.healingGreen10),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: isDanger
                        ? HugeIcons.strokeRoundedAlert01
                        : HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: isDanger
                        ? AyurezeTheme.remoteRed50
                        : AyurezeTheme.healingGreen50,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AyurezeTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AyurezeTheme.textSecondary,
                ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          actions: [
            if (secondaryText != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: secondaryAction ?? () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDanger
                        ? AyurezeTheme.remoteRed50
                        : AyurezeTheme.textPrimary,
                    side: BorderSide(
                      color: isDanger
                          ? AyurezeTheme.remoteRed50
                          : AyurezeTheme.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AyurezeTheme.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    secondaryText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: primaryAction ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDanger
                      ? AyurezeTheme.remoteRedFill
                      : AyurezeTheme.healingGreen100,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(
                  primaryText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show a simple success dialog
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      primaryText: 'Great!',
      primaryAction: onClose ?? () => Navigator.pop(context),
    );
  }

  /// Show a simple error dialog
  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      primaryText: 'Close',
      isDanger: true,
      primaryAction: onClose ?? () => Navigator.pop(context),
    );
  }

  /// Show a confirmation dialog with two actions
  static void showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      primaryText: cancelText,
      secondaryText: confirmText,
      primaryAction: () => Navigator.pop(context),
      secondaryAction: () {
        Navigator.pop(context);
        onConfirm();
      },
      isDanger: isDanger,
    );
  }
}

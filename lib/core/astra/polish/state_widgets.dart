import 'package:flutter/material.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Loading State Widget
///
/// Displays a consistent loading indicator throughout the app.
class AstraLoadingState extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const AstraLoadingState({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 48,
            height: size ?? 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                color ?? AyurezeTheme.healingGreen50,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AyurezeTheme.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline loading indicator
class AstraInlineLoading extends StatelessWidget {
  final String? message;
  final double size;

  const AstraInlineLoading({
    super.key,
    this.message,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              AyurezeTheme.healingGreen50,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message!,
            style: TextStyle(
              color: AyurezeTheme.textSecondary,
              fontSize: AyurezeTheme.textMd,
            ),
          ),
        ],
      ],
    );
  }
}

/// Error State Widget
///
/// Displays user-friendly error messages with retry option.
class AstraErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final List<List<dynamic>>? icon;
  final Color? iconColor;

  const AstraErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.onDismiss,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AyurezeTheme.space2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon ?? HugeIcons.strokeRoundedAlertCircle,
              size: 64,
              color: iconColor ?? Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AyurezeTheme.textLg,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AyurezeTheme.textMd,
                  color: AyurezeTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDismiss != null)
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                if (onRetry != null) ...[
                  if (onDismiss != null) const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: HugeIcon(icon: AppIcons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AyurezeTheme.healingGreenFill,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty State Widget
///
/// Displays when there's no data to show.
class AstraEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final List<List<dynamic>>? icon;
  final Widget? action;

  const AstraEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AyurezeTheme.space2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon ?? HugeIcons.strokeRoundedInbox,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AyurezeTheme.textLg,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AyurezeTheme.textMd,
                  color: AyurezeTheme.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Network Error State
class AstraNetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const AstraNetworkError({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AstraErrorState(
      message: 'Connection Error',
      details: 'Please check your internet connection and try again.',
      icon: HugeIcons.strokeRoundedWifiOff01,
      iconColor: Colors.orange,
      onRetry: onRetry,
    );
  }
}

/// Timeout Error State
class AstraTimeoutError extends StatelessWidget {
  final VoidCallback? onRetry;

  const AstraTimeoutError({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AstraErrorState(
      message: 'Request Timeout',
      details: 'The server is taking too long to respond. Please try again.',
      icon: HugeIcons.strokeRoundedTimerOff,
      iconColor: Colors.orange,
      onRetry: onRetry,
    );
  }
}

/// Server Error State
class AstraServerError extends StatelessWidget {
  final int? statusCode;
  final VoidCallback? onRetry;

  const AstraServerError({
    super.key,
    this.statusCode,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AstraErrorState(
      message: 'Server Error',
      details: statusCode != null
          ? 'Something went wrong (Error $statusCode). Please try again later.'
          : 'Something went wrong. Please try again later.',
      icon: HugeIcons.strokeRoundedCloudOff,
      iconColor: Colors.red.shade400,
      onRetry: onRetry,
    );
  }
}

/// Offline Banner
class AstraOfflineBanner extends StatelessWidget {
  const AstraOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AyurezeTheme.spaceSm, horizontal: AyurezeTheme.spaceLg),
      color: Colors.orange.shade700,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const HugeIcon(
                icon: HugeIcons.strokeRoundedWifiOff01,
                color: Colors.white,
                size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'You are offline',
                style: TextStyle(
                    color: Colors.white, fontSize: AyurezeTheme.textMd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

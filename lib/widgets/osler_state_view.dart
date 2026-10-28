import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_loader.dart';
import 'package:doctro/widgets/swastu.dart';

/// Swastu thinking over a small spinner, with an optional message, for
/// whenever a screen or section is waiting on data. The spinner stays so
/// progress is explicit; Swastu matches the patient app's loading state.
class OslerLoadingView extends StatelessWidget {
  final String? message;

  const OslerLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Swastu(mood: SwastuMood.thinking, size: 88, named: false),
          const SizedBox(height: AyurezeTheme.spaceSm),
          const OslerLoader(size: 24, strokeWidth: 2.5),
          if (message != null) ...[
            const SizedBox(height: AyurezeTheme.spaceLg),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AyurezeTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Whether an [OslerStateView] reads as a neutral "nothing here yet" state
/// or a "something went wrong" state. Sets Swastu's mood and the badge tint.
enum OslerStateTone { neutral, error, muted }

/// Swastu + title + message (+ optional action button): the pattern for
/// every empty and error state across the app, matching the patient app's
/// Swastu states (idle when empty, concerned on error). [icon] still shows,
/// as a small badge beside Swastu, so the state keeps its context.
/// [ErrorUtilityScreen] is the dedicated full-screen version of this same
/// idea (with a status badge and back button) for app-level states like 404;
/// this widget is for in-page/in-tab states.
class OslerStateView extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String? message;
  final OslerStateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Overrides the mood picked from [tone] (e.g. happy for "all done").
  final SwastuMood? mood;

  const OslerStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = OslerStateTone.neutral,
    this.actionLabel,
    this.onAction,
    this.mood,
  });

  SwastuMood get _mood =>
      mood ??
      switch (tone) {
        OslerStateTone.error => SwastuMood.concerned,
        OslerStateTone.muted || OslerStateTone.neutral => SwastuMood.idle,
      };

  @override
  Widget build(BuildContext context) {
    final (tint, foreground) = switch (tone) {
      OslerStateTone.error => (
          AyurezeTheme.remoteRed10,
          AyurezeTheme.remoteRed100
        ),
      OslerStateTone.muted => (
          AyurezeTheme.oslerGray10,
          AyurezeTheme.oslerGray100
        ),
      OslerStateTone.neutral => (
          AyurezeTheme.healingGreen10,
          AyurezeTheme.healingGreen100
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AyurezeTheme.space3xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Swastu(mood: _mood, size: 112, named: false),
                Positioned(
                  right: -AyurezeTheme.spaceXs,
                  bottom: AyurezeTheme.spaceXs,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AyurezeTheme.surface, width: 2),
                    ),
                    child: HugeIcon(icon: icon, color: foreground, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AyurezeTheme.spaceLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: AyurezeTheme.spaceSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AyurezeTheme.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AyurezeTheme.spaceLg),
              OslerButton(text: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }

  /// Convenience factory for the most common error case: something failed
  /// to load and the user can retry.
  factory OslerStateView.error({
    String title = "Couldn't Load Data",
    String? message,
    VoidCallback? onRetry,
  }) =>
      OslerStateView(
        icon: HugeIcons.strokeRoundedCloudOff,
        title: title,
        message: message,
        tone: OslerStateTone.error,
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );
}

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/swastu.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_tag.dart';

/// The five full-screen states from the Osler kit's "Error & Utility
/// Screens" page: a shared illustration + status badge + "Take Me Home"
/// pattern, differing only in icon, copy and badge.
enum ErrorUtilityKind {
  notFound,
  noInternet,
  internalError,
  maintenance,
  notAllowed
}

class ErrorUtilityScreen extends StatelessWidget {
  final ErrorUtilityKind kind;

  /// Overrides the badge label (e.g. a live "come back in Xh Ym" countdown
  /// for [ErrorUtilityKind.maintenance]). Falls back to each kind's default.
  final String? badgeLabel;

  /// Called when the primary action ("Take Me Home" / "Please refresh" /
  /// "Contact Support") is tapped. Defaults to popping back to the login
  /// home route.
  final VoidCallback? onAction;

  const ErrorUtilityScreen({
    super.key,
    required this.kind,
    this.badgeLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(kind);
    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AyurezeTheme.spaceXl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).pop()
                      : null,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: AyurezeTheme.iconPrimary,
                  ),
                ),
              ),
              const Spacer(),
              // Swastu carries the state, with the kind's icon as a badge -
              // the same moods the patient app uses (offline: sleepy,
              // errors: concerned).
              ScreenEntrance(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Swastu(mood: _moodFor(kind), size: 150, named: false),
                    Positioned(
                      right: -AyurezeTheme.spaceXs,
                      bottom: AyurezeTheme.spaceSm,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: spec.tint,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AyurezeTheme.surface, width: 2),
                        ),
                        child: HugeIcon(
                          icon: spec.icon,
                          color: spec.foreground,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AyurezeTheme.space3xl),
              ScreenEntrance(
                index: 1,
                child: Text(
                  spec.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AyurezeTheme.spaceSm),
              ScreenEntrance(
                index: 2,
                child: Text(
                  spec.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AyurezeTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AyurezeTheme.spaceLg),
              ScreenEntrance(
                index: 3,
                child: OslerTag(
                  label: badgeLabel ?? spec.badgeLabel,
                  style: OslerTagStyle.danger,
                  icon: HugeIcons.strokeRoundedAlert02,
                ),
              ),
              const Spacer(),
              ScreenEntrance(
                index: 4,
                child: OslerButton(
                  text: 'Take Me Home',
                  icon: null,
                  onPressed: onAction ??
                      () => Navigator.of(context).pushNamedAndRemoveUntil(
                          'loginHome', (route) => false),
                ),
              ),
              const SizedBox(height: AyurezeTheme.spaceLg),
            ],
          ),
        ),
      ),
    );
  }

  _ErrorUtilitySpec _specFor(ErrorUtilityKind kind) {
    switch (kind) {
      case ErrorUtilityKind.notFound:
        return _ErrorUtilitySpec(
          icon: HugeIcons.strokeRoundedFileNotFound,
          title: 'Not Found',
          message: "Whoops! Dr. O can't find this page :(",
          badgeLabel: 'Status Code: 404',
          tint: AyurezeTheme.remoteRed10,
          foreground: AyurezeTheme.remoteRed100,
        );
      case ErrorUtilityKind.noInternet:
        return _ErrorUtilitySpec(
          icon: HugeIcons.strokeRoundedWifiDisconnected01,
          title: 'No Internet',
          message: "It seems you don't have active internet.",
          badgeLabel: 'Please refresh or try again!',
          tint: AyurezeTheme.remoteRed10,
          foreground: AyurezeTheme.remoteRed100,
        );
      case ErrorUtilityKind.internalError:
        return _ErrorUtilitySpec(
          icon: HugeIcons.strokeRoundedServerCrash,
          title: 'Internal Error',
          message: 'Whoops! Our server seems to error.',
          badgeLabel: 'Contact Support',
          tint: AyurezeTheme.remoteRed10,
          foreground: AyurezeTheme.remoteRed100,
        );
      case ErrorUtilityKind.maintenance:
        return _ErrorUtilitySpec(
          icon: HugeIcons.strokeRoundedWrench01,
          title: 'Maintenance',
          message: "We're undergoing maintenance :(.",
          badgeLabel: 'Come back later',
          tint: AyurezeTheme.sunshineYellow10,
          foreground: AyurezeTheme.sunshineYellow100,
        );
      case ErrorUtilityKind.notAllowed:
        return _ErrorUtilitySpec(
          icon: HugeIcons.strokeRoundedSecurityLock,
          title: 'Not Allowed',
          message: "Hey! You don't have permission.",
          badgeLabel: 'Contact Support',
          tint: AyurezeTheme.remoteRed10,
          foreground: AyurezeTheme.remoteRed100,
        );
    }
  }
}

SwastuMood _moodFor(ErrorUtilityKind kind) => switch (kind) {
      ErrorUtilityKind.noInternet ||
      ErrorUtilityKind.maintenance =>
        SwastuMood.sleepy,
      ErrorUtilityKind.internalError ||
      ErrorUtilityKind.notAllowed =>
        SwastuMood.concerned,
      ErrorUtilityKind.notFound => SwastuMood.thinking,
    };

class _ErrorUtilitySpec {
  final List<List<dynamic>> icon;
  final String title;
  final String message;
  final String badgeLabel;
  final Color tint;
  final Color foreground;

  const _ErrorUtilitySpec({
    required this.icon,
    required this.title,
    required this.message,
    required this.badgeLabel,
    required this.tint,
    required this.foreground,
  });
}

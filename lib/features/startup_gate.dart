import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/features/authentication/SignIn.dart';
import 'package:doctro/features/shell/app_shell.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/swastu.dart';

/// Picks the first screen the app shows: the dashboard when a session is
/// already stored, sign-in otherwise.
///
/// `SharedPreferences` is initialized in `main()` before `runApp`, so the
/// session flag can be read synchronously here. That is what lets the app
/// decide where to go with no wait: the destination below is resolved once,
/// in `initState`, before anything is drawn.
///
/// A short branded animation plays over that destination for [_introDuration]
/// - not a wait on anything (the destination is already mounted underneath
/// and loading its own data the whole time), just a fixed, catchy beat before
/// the logo reveal fades away. This is deliberately not the old timed splash
/// screen it replaces: nothing here blocks on the network, and removing this
/// widget never changes which screen the user lands on.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  static const _introDuration = Duration(milliseconds: 900);

  /// Resolved once, in `initState`. A later rebuild of the gate (a locale
  /// change, for instance) must not move a signed-in user to sign-in, or the
  /// reverse.
  late final bool _isLoggedIn = _readSession();

  bool _showIntro = true;

  bool _readSession() {
    try {
      return SharedPreferenceHelper.getBoolean(Preferences.is_logged_in);
    } catch (e) {
      // Storage initialization is the only thing that can fail here. Fall back
      // to sign-in: the dashboard needs a token before it can load anything,
      // so an unrecognized session is not usable anyway.
      debugPrint('StartupGate: could not read the session flag: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(_introDuration, () {
      if (mounted) setState(() => _showIntro = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _isLoggedIn ? const AppShell() : const SignIn();
    if (!_showIntro) return destination;
    // The destination is mounted underneath from the first frame, so its own
    // startup work (view model init, API calls) runs during the intro
    // instead of being pushed back by it.
    return Stack(
      children: [
        destination,
        const _BrandIntro(),
      ],
    );
  }
}

/// The animated logo reveal painted over [StartupGate]'s destination for its
/// first ~900ms. Opaque while visible - the destination underneath is not
/// meant to be interactive yet - and removed from the tree entirely once
/// [_StartupGateState._showIntro] flips, not merely faded to invisible.
class _BrandIntro extends StatelessWidget {
  const _BrandIntro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Same opening as the patient app: Swastu waking on the cream canvas
    // under a soft sage halo, with the serif AyurEze name.
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AyurezeTheme.canvas,
          gradient: RadialGradient(
            radius: 0.7,
            colors: [
              AyurezeTheme.healingGreen10.withValues(alpha: 0.9),
              AyurezeTheme.canvas,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Swastu(mood: SwastuMood.waking, size: 132)
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 450.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 350.ms),
              const SizedBox(height: AyurezeTheme.spaceLg),
              Text(
                'AyurEze',
                style: textTheme.headlineLarge
                    ?.copyWith(color: AyurezeTheme.iconPrimary),
              ),
              const SizedBox(height: AyurezeTheme.spaceXs),
              Text(
                'Calm, connected Ayurvedic practice',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AyurezeTheme.textSecondary),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),
      ),
    ).animate().fadeOut(delay: 500.ms, duration: 400.ms);
  }
}

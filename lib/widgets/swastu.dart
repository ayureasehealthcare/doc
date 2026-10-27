import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:doctro/theme/ayureze_theme.dart';

/// Swastu - AyurEze's companion character, shared with the patient app
/// (lib/features/swastu/ui/swastu_kit.dart there). In the patient app it is
/// the face of Astra; here it fronts the same Astra surfaces plus the
/// app's empty, error and loading moments, so doctors and patients meet
/// one consistent character.
///
/// Art lives in `assets/swastu/swastu_<mood>.png`, one pose per mood.
enum SwastuMood {
  idle,
  waking,
  greeting,
  listening,
  thinking,
  talking,
  happy,
  celebrating,
  concerned,
  sleepy,
  breathing,
  urgent,
}

/// Swastu with its always-on idle life: slow breathing and a gentle float.
/// A tap gives a soft squish; mood changes cross-fade. Calm-down states
/// (urgent, concerned) stay still, and so does everything when the device
/// asks for reduced motion.
///
/// Unlike the patient app, taps make no sound: this is a clinical tool.
class Swastu extends StatefulWidget {
  final SwastuMood mood;
  final double size;
  final VoidCallback? onTap;

  /// False when a parent drives Swastu's movement itself.
  final bool idleMotion;

  /// Shows the "Swastu" name tag under the character. Defaults to on when
  /// Swastu stands on its own (100px or larger); small avatars sit in a
  /// labelled bubble or row already.
  final bool? named;

  const Swastu({
    super.key,
    this.mood = SwastuMood.idle,
    this.size = 140,
    this.onTap,
    this.idleMotion = true,
    this.named,
  });

  /// The pose image for [mood].
  static String assetFor(SwastuMood mood) =>
      'assets/swastu/swastu_${mood.name}.png';

  @override
  State<Swastu> createState() => _SwastuState();
}

class _SwastuState extends State<Swastu> with TickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));
  late final AnimationController _squish = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));

  bool get _still =>
      !widget.idleMotion ||
      widget.mood == SwastuMood.urgent ||
      widget.mood == SwastuMood.concerned;

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(Swastu old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.idleMotion != widget.idleMotion) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (_reduceMotion || _still) {
      _breath.stop();
      _breath.value = 0;
    } else if (!_breath.isAnimating) {
      _breath.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _squish.dispose();
    super.dispose();
  }

  void _tap() {
    if (!_reduceMotion && !_still) _squish.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final image = Image.asset(
      Swastu.assetFor(widget.mood),
      key: ValueKey(widget.mood),
      width: size,
      height: size * 1.05,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
    final character = Semantics(
      label: 'Swastu',
      image: true,
      child: GestureDetector(
        onTap: _tap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _squish]),
          builder: (context, child) {
            final b = math.sin(_breath.value * math.pi * 2);
            final amp = widget.mood == SwastuMood.breathing ? 0.06 : 0.02;
            final q = _squish.value;
            final sq = math.sin(q * math.pi * 2) * (1 - q) * 0.1;
            return Transform.translate(
              offset: Offset(0, -b * size * 0.015),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(
                    1 + amp * 0.5 * b + sq, 1 + amp * b - sq, 1),
                child: child,
              ),
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: image,
          ),
        ),
      ),
    );
    if (!(widget.named ?? size >= 100)) return character;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        character,
        SizedBox(height: size * 0.04),
        SwastuNameTag(large: size >= 150),
      ],
    );
  }
}

/// The Swastu wordmark, used wherever the character's name is shown.
class SwastuWordmark extends StatelessWidget {
  final double height;

  const SwastuWordmark({super.key, this.height = 20});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/swastu_wordmark.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Swastu',
      );
}

/// The "Swastu" name tag under the character: the wordmark on a pale pill.
/// The pill stays light in both themes because the wordmark is green ink.
class SwastuNameTag extends StatelessWidget {
  final bool large;

  const SwastuNameTag({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? AyurezeTheme.spaceLg : AyurezeTheme.spaceMd,
          vertical: AyurezeTheme.spaceXs,
        ),
        decoration: BoxDecoration(
          color: AyurezeTheme.lightSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
          border: Border.all(color: AyurezeTheme.healingGreen10),
        ),
        child: SwastuWordmark(height: large ? 24 : 19),
      ),
    );
  }
}

/// Swastu speaking: a small avatar plus a speech bubble on the themed
/// surface. [serif] sets the line in the editorial serif, for greetings.
class SwastuSays extends StatelessWidget {
  final String text;
  final SwastuMood mood;
  final bool serif;

  const SwastuSays(
    this.text, {
    super.key,
    this.mood = SwastuMood.talking,
    this.serif = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Swastu(mood: mood, size: 44),
        const SizedBox(width: AyurezeTheme.spaceSm),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AyurezeTheme.spaceLg,
              AyurezeTheme.spaceSm,
              AyurezeTheme.spaceLg,
              AyurezeTheme.spaceMd,
            ),
            decoration: BoxDecoration(
              color: AyurezeTheme.surface,
              // Speech-bubble tail on the bottom-left, toward Swastu.
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AyurezeTheme.radiusXl),
                topRight: Radius.circular(AyurezeTheme.radiusXl),
                bottomRight: Radius.circular(AyurezeTheme.radiusXl),
                bottomLeft: Radius.circular(AyurezeTheme.radiusXs),
              ),
              border: Border.all(color: AyurezeTheme.border),
              boxShadow: [
                BoxShadow(
                  color: AyurezeTheme.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(child: SwastuNameTag()),
                const SizedBox(height: AyurezeTheme.spaceXs),
                Text(
                  text,
                  style: serif
                      ? t.headlineMedium?.copyWith(
                          fontSize: AyurezeTheme.textXl,
                          color: AyurezeTheme.textPrimary,
                        )
                      : t.bodyLarge?.copyWith(color: AyurezeTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

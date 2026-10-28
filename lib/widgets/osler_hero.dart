import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Standard screen banner: an optional eyebrow pill, a headline and a
/// supporting line, all on the shared [AyurezeTheme.heroDecoration] surface.
///
/// Use this instead of hand-rolling the same banner on each screen so the
/// eyebrow/headline/subtitle rhythm stays identical across the app.
class OslerHero extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;

  const OslerHero({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AyurezeTheme.space2xl),
      decoration: AyurezeTheme.heroDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
              ),
              child: Text(
                eyebrow!,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

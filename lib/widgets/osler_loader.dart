import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';

class OslerLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const OslerLoader({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AyurezeTheme.accent,
      ),
    );
  }
}

class OslerOverlayLoader extends StatelessWidget {
  final String? message;

  const OslerOverlayLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AyurezeTheme.space2xl),
          decoration: BoxDecoration(
            color: AyurezeTheme.surface,
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OslerLoader(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AyurezeTheme.textPrimary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

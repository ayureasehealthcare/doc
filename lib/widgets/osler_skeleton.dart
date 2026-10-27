import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:doctro/theme/ayureze_theme.dart';

class OslerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const OslerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AyurezeTheme.border,
      highlightColor: AyurezeTheme.surfaceMuted,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class OslerCardSkeleton extends StatelessWidget {
  const OslerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceLg),
      child: Shimmer.fromColors(
        baseColor: AyurezeTheme.border,
        highlightColor: AyurezeTheme.surfaceMuted,
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          ),
          padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 140, height: 16, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

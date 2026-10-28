import 'dart:math' as math;

import 'package:doctro/theme/ayureze_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative luminance for an sRGB colour.
double _luminance(double r, double g, double b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

/// WCAG contrast ratio between two opaque colours, 1.0 .. 21.0.
double contrastRatio(int a, int b) {
  double lum(int argb) => _luminance(
        ((argb >> 16) & 0xFF) / 255,
        ((argb >> 8) & 0xFF) / 255,
        (argb & 0xFF) / 255,
      );
  final double la = lum(a);
  final double lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('WCAG helper', () {
    test('black on white is the maximum 21:1', () {
      expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21.0, 0.01));
    });

    test('a colour against itself is 1:1', () {
      expect(contrastRatio(0xFF3D3D3D, 0xFF3D3D3D), closeTo(1.0, 0.001));
    });
  });

  group('body text meets WCAG AA (4.5:1) on its surface', () {
    test('light theme primary text', () {
      expect(
        contrastRatio(
          AyurezeTheme.lightTextPrimary.toARGB32(),
          AyurezeTheme.lightSurface.toARGB32(),
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('light theme secondary text on both light surfaces', () {
      for (final int surface in [
        AyurezeTheme.lightSurface.toARGB32(),
        AyurezeTheme.lightSurfaceMuted.toARGB32(),
      ]) {
        expect(
          contrastRatio(AyurezeTheme.lightTextSecondary.toARGB32(), surface),
          greaterThanOrEqualTo(4.5),
          reason: 'lightTextSecondary is unreadable on surface $surface',
        );
      }
    });

    test('dark theme primary text', () {
      expect(
        contrastRatio(
          AyurezeTheme.darkTextPrimary.toARGB32(),
          AyurezeTheme.darkSurface.toARGB32(),
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    // Regression guard: darkTextSecondary was #A0A0A0, which scored only
    // 4.15:1 on darkSurfaceMuted and failed AA.
    test('dark theme secondary text on both dark surfaces', () {
      for (final int surface in [
        AyurezeTheme.darkSurface.toARGB32(),
        AyurezeTheme.darkSurfaceMuted.toARGB32(),
      ]) {
        expect(
          contrastRatio(AyurezeTheme.darkTextSecondary.toARGB32(), surface),
          greaterThanOrEqualTo(4.5),
          reason: 'darkTextSecondary is unreadable on surface $surface',
        );
      }
    });
  });

  group('filled controls carrying a white glyph', () {
    // Regression guard: these used healingGreen50 (#10B981), which is only
    // 2.54:1 against white and failed in BOTH light and dark mode. The
    // healingGreenFill token exists for exactly this role.
    test('healingGreenFill is legible under white', () {
      expect(
        contrastRatio(
          AyurezeTheme.healingGreenFill.toARGB32(),
          const Color(0xFFFFFFFF).toARGB32(),
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('healingGreen50 is NOT a valid white-glyph fill', () {
      // Documents why the token exists: this pairing must stay below AA so
      // nobody quietly swaps it back in.
      expect(
        contrastRatio(
          AyurezeTheme.healingGreen50.toARGB32(),
          const Color(0xFFFFFFFF).toARGB32(),
        ),
        lessThan(4.5),
      );
    });

    test('both reds are legible under white', () {
      // The old rose remoteRed50 (#F43F5E) was 3.67:1 under white, which is
      // why remoteRedFill exists. The Serene Herbalist clay red clears AA
      // too, so a white label is safe on either.
      for (final red in [
        AyurezeTheme.remoteRedFill,
        AyurezeTheme.remoteRed50
      ]) {
        expect(
          contrastRatio(red.toARGB32(), const Color(0xFFFFFFFF).toARGB32()),
          greaterThanOrEqualTo(4.5),
          reason: '$red',
        );
      }
    });
  });

  group('ink drawn straight on the page', () {
    // forestDeep/healingGreen100 were used as icon and text colour on
    // canvas/surface across 20+ screens: 12-14:1 in light mode but
    // 1.06-1.35:1 in dark mode. iconPrimary/textPrimary are the
    // replacement; they must clear AA on every page surface in both modes.
    for (final dark in [false, true]) {
      test(
          'iconPrimary and textPrimary on page surfaces '
          '(${dark ? 'dark' : 'light'})', () {
        AyurezeTheme.updateThemeMode(dark);
        addTearDown(() => AyurezeTheme.updateThemeMode(false));
        for (final ink in [
          AyurezeTheme.iconPrimary,
          AyurezeTheme.textPrimary
        ]) {
          for (final bg in [
            AyurezeTheme.canvas,
            AyurezeTheme.surface,
            AyurezeTheme.surfaceMuted,
          ]) {
            expect(contrastRatio(ink.toARGB32(), bg.toARGB32()),
                greaterThanOrEqualTo(4.5),
                reason: '$ink on $bg');
          }
        }
      });
    }

    test('forestDeep is NOT valid ink on the dark-mode page', () {
      // Documents why screens must not draw it straight on canvas/surface.
      expect(
        contrastRatio(AyurezeTheme.forestDeep.toARGB32(),
            AyurezeTheme.darkCanvas.toARGB32()),
        lessThan(3),
      );
    });
  });

  group('error ink', () {
    // Form errors and "Not in store" draw colorScheme.error straight on the
    // page. The dark theme used the light theme's deep red: 2.5:1.
    for (final dark in [false, true]) {
      test('colorScheme.error on page surfaces (${dark ? 'dark' : 'light'})',
          () {
        AyurezeTheme.updateThemeMode(dark);
        addTearDown(() => AyurezeTheme.updateThemeMode(false));
        final scheme =
            (dark ? AyurezeTheme.darkTheme() : AyurezeTheme.lightTheme())
                .colorScheme;
        for (final bg in [
          AyurezeTheme.canvas,
          AyurezeTheme.surface,
          AyurezeTheme.surfaceMuted,
        ]) {
          expect(contrastRatio(scheme.error.toARGB32(), bg.toARGB32()),
              greaterThanOrEqualTo(4.5),
              reason: '${scheme.error} on $bg');
        }
        expect(
            contrastRatio(scheme.onError.toARGB32(), scheme.error.toARGB32()),
            greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('page accent', () {
    for (final dark in [false, true]) {
      test(
          'accent is visible on every page surface '
          '(${dark ? 'dark' : 'light'})', () {
        AyurezeTheme.updateThemeMode(dark);
        addTearDown(() => AyurezeTheme.updateThemeMode(false));
        for (final bg in [
          AyurezeTheme.canvas,
          AyurezeTheme.surface,
          AyurezeTheme.surfaceMuted,
        ]) {
          // 3:1 is the WCAG threshold for UI components like spinners.
          expect(contrastRatio(AyurezeTheme.accent.toARGB32(), bg.toARGB32()),
              greaterThanOrEqualTo(3),
              reason: 'accent on $bg');
        }
      });
    }
  });

  group('in-call surfaces (always dark)', () {
    test('callForeground clears AA on both ends of the waiting gradient', () {
      // The waiting text used textPrimary, which is dark ink in light mode:
      // 1.45:1 on teal-900.
      for (final stop in AyurezeTheme.callWaitingGradient.colors) {
        expect(
          contrastRatio(
              AyurezeTheme.callForeground.toARGB32(), stop.toARGB32()),
          greaterThanOrEqualTo(4.5),
          reason: 'on $stop',
        );
      }
      expect(
        contrastRatio(AyurezeTheme.callForeground.toARGB32(),
            AyurezeTheme.callBackground.toARGB32()),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('type scale', () {
    test('the textTheme is built on the size tokens, in both modes', () {
      for (final raw in [
        AyurezeTheme.lightTheme(),
        AyurezeTheme.darkTheme(),
      ]) {
        // As Theme.of(context) sees it: sizes the theme leaves unset
        // (bodySmall, labelSmall) come from the typography geometry.
        final theme = ThemeData.localize(
            raw, raw.typography.geometryThemeFor(ScriptCategory.englishLike));
        final t = theme.textTheme;
        expect(t.headlineLarge!.fontSize, AyurezeTheme.text3xl);
        expect(t.headlineMedium!.fontSize, AyurezeTheme.text2xl);
        expect(t.headlineSmall!.fontFamily, AyurezeTheme.serifFamily);
        expect(t.headlineMedium!.fontFamily, AyurezeTheme.serifFamily);
        expect(t.titleLarge!.fontSize, AyurezeTheme.textXl);
        expect(t.titleMedium!.fontSize, AyurezeTheme.textLg);
        expect(t.bodyLarge!.fontSize, AyurezeTheme.textBase);
        expect(t.bodyMedium!.fontSize, AyurezeTheme.textMd);
        expect(t.bodySmall!.fontSize, AyurezeTheme.textSm);
        expect(t.labelSmall!.fontSize, AyurezeTheme.textXs);
      }
    });

    test('app bar titles are the same size in light and dark mode', () {
      // Were 22 (light) vs 18 (dark), so titles jumped on a theme switch.
      expect(AyurezeTheme.lightTheme().appBarTheme.titleTextStyle!.fontSize,
          AyurezeTheme.darkTheme().appBarTheme.titleTextStyle!.fontSize);
    });
  });

  group('brand accent pairs (shade 100 foreground on shade 10 tint)', () {
    const List<List<Object>> pairs = [
      [
        'primary/success',
        AyurezeTheme.healingGreen10,
        AyurezeTheme.healingGreen100
      ],
      ['secondary', AyurezeTheme.oslerGray10, AyurezeTheme.oslerGray100],
      [
        'warning',
        AyurezeTheme.sunshineYellow10,
        AyurezeTheme.sunshineYellow100
      ],
      ['danger', AyurezeTheme.remoteRed10, AyurezeTheme.remoteRed100],
      [
        'info',
        AyurezeTheme.connectivityBlue10,
        AyurezeTheme.connectivityBlue100
      ],
    ];

    for (final List<Object> pair in pairs) {
      test('${pair[0]} chip is readable', () {
        expect(
          contrastRatio(
            (pair[2] as Color).toARGB32(),
            (pair[1] as Color).toARGB32(),
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}

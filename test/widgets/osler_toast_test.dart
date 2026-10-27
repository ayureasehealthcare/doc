import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('info toast is sage ink and readable (dark: $dark)',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AyurezeTheme.darkTheme() : AyurezeTheme.lightTheme(),
        home: Scaffold(body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        })),
      ));
      OslerToast.info(ctx, 'Saved for later');
      await tester.pump();

      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      final text = tester.widget<Text>(find.text('Saved for later'));
      // The old navy fill sat outside the Serene Herbalist palette.
      expect(bar.backgroundColor, isNot(AyurezeTheme.connectivityBlue100));
      expect(_contrast(bar.backgroundColor!, text.style!.color!),
          greaterThanOrEqualTo(4.5));
    });
  }
}

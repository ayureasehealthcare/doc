import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/theme/ayureze_date_picker.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// forestDeep / healingGreen100 (#1A2E05) is near-black. Every remaining use
/// in a screen or shared widget was reviewed as a fill under white content, an accent on its
/// own pale tint, or ink on a fixed bright fill (lime header, lime avatar)
/// - never ink on canvas/surface, where it vanishes in dark mode.
///
/// If this fails because a count went UP, check the new use: if it's text
/// or an icon on a themed page, use AyurezeTheme.iconPrimary/textPrimary
/// instead. If it is genuinely a fill or a tint pair, bump the count. If a
/// count went DOWN, lower it here.
const _reviewed = {
  'lib/features/authentication/sign_in.dart': 1, // decorative glass blob
  'lib/features/authentication/phoneverification.dart': 1, // fill
  'lib/features/authentication/professional_registration_screen.dart':
      1, // date-picker accent (fill)
  'lib/features/authentication/registration_success_screen.dart':
      1, // button fill
  'lib/features/cashfree/payment.dart': 1, // text on lightGreenSoft tint
  'lib/features/consultation/astra_chat/astra_chat_page.dart':
      2, // 'online' status: shade-100 on its shade-10 tint
  'lib/features/consultation/chat/pages/chat_page.dart': 1, // avatar fill
  'lib/features/dashboard/login_home.dart': 1, // icon on lime fill
  'lib/features/dashboard/patient_information.dart': 1, // button fill
  'lib/features/prescription/astra/prescription_screen.dart':
      3, // snackbar + avatar fills + dosage suggestion text (tint pair)
  'lib/features/profile/profile.dart':
      3, // stepper fill, date-picker accent, icon on lime avatar
  'lib/features/search/search_screen.dart':
      6, // fixed lime header + its chips, tint pair
  'lib/features/settings/setting.dart': 1, // switch thumb on lime track
  'lib/widgets/astra_ai_button.dart': 1, // gradient fill, white icon
  'lib/widgets/astra_fill_display.dart':
      2, // chip text, severity pill: shade-100 on shade-10 tints
  'lib/widgets/modern_drawer.dart': 1, // badge text on lime fill
  'lib/widgets/osler_alert.dart': 2, // shade-100 on shade-10 tint
  'lib/widgets/osler_button.dart': 1, // dark ink candidate for fills
  'lib/widgets/osler_modal.dart': 1, // button fill, white label
  'lib/widgets/osler_state_view.dart': 1, // shade-100 on shade-10 tint
  'lib/widgets/osler_tag.dart': 2, // shade-100 on shade-10 tint
  'lib/widgets/osler_toast.dart': 1, // toast fill, white text
  'lib/widgets/osler_tooltip.dart': 1, // tooltip fill, white text
};

void main() {
  test('no unreviewed dark ink in screens or shared widgets', () {
    final pattern = RegExp(r'AyurezeTheme\.(forestDeep|healingGreen100)\b');
    final found = <String, int>{};
    for (final f in [Directory('lib/features'), Directory('lib/widgets')]
        .expand((d) => d.listSync(recursive: true))
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final n = pattern.allMatches(f.readAsStringSync()).length;
      if (n > 0) found[f.path.replaceAll(r'\', '/')] = n;
    }
    expect(found, _reviewed);
  });

  testWidgets('date picker OK button stays legible in dark mode',
      (tester) async {
    AyurezeTheme.updateThemeMode(true);
    addTearDown(() => AyurezeTheme.updateThemeMode(false));

    await tester.pumpWidget(MaterialApp(
      theme: AyurezeTheme.darkTheme(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showAyurezeDatePicker(
            context: context,
            initialDate: DateTime(2026, 10, 15),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final ok = tester
        .renderObject<RenderParagraph>(find.text('OK'))
        .text
        .style!
        .color!;
    final bg = AyurezeTheme.surface;
    final la = ok.computeLuminance(), lb = bg.computeLuminance();
    final ratio = ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
    expect(ratio, greaterThanOrEqualTo(4.5), reason: 'OK = $ok on $bg');
  });
}

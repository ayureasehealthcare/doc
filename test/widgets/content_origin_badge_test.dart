import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/content_origin_badge.dart';
import 'package:doctro/widgets/osler_tag.dart';

void main() {
  group('ContentOrigin.forDraft', () {
    test('unchanged Astra text is an Astra suggestion', () {
      expect(ContentOrigin.forDraft('Possible X', astraDraft: 'Possible X'),
          ContentOrigin.astraSuggestion);
    });

    test('edited or hand-typed text is the doctor\'s', () {
      expect(ContentOrigin.forDraft('Possible X.', astraDraft: 'Possible X'),
          ContentOrigin.doctorApproved);
      expect(ContentOrigin.forDraft('Typed by hand'),
          ContentOrigin.doctorApproved);
    });

    test('an empty field has no origin', () {
      expect(ContentOrigin.forDraft('', astraDraft: 'Possible X'), isNull);
      expect(ContentOrigin.forDraft('   '), isNull);
    });
  });

  testWidgets('renders the same labels as the patient app', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ContentOriginBadge(origin: ContentOrigin.astraSuggestion),
            ContentOriginBadge(origin: ContentOrigin.doctorApproved),
          ],
        ),
      ),
    ));

    expect(find.text('Astra suggestion'), findsOneWidget);
    expect(find.text('Doctor-approved'), findsOneWidget);

    final tags = tester.widgetList<OslerTag>(find.byType(OslerTag)).toList();
    expect(tags[0].style, OslerTagStyle.warning);
    expect(tags[0].icon, HugeIcons.strokeRoundedSparkles);
    expect(tags[1].style, OslerTagStyle.success);
    expect(tags[1].icon, HugeIcons.strokeRoundedCheckmarkBadge01);

    expect(find.bySemanticsLabel('Content origin: Astra suggestion'),
        findsOneWidget);
    expect(find.bySemanticsLabel('Content origin: Doctor-approved'),
        findsOneWidget);
  });

  testWidgets('stays readable in dark mode', (tester) async {
    // OslerTag reads light-only accent constants; this pins that the badge
    // keeps the shade-10/shade-100 pairing instead of a dark-aware text
    // token that would flip to light text on a pale fill.
    AyurezeTheme.updateThemeMode(true);
    addTearDown(() => AyurezeTheme.updateThemeMode(false));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ContentOriginBadge(origin: ContentOrigin.astraSuggestion),
      ),
    ));
    final text = tester.widget<Text>(find.text('Astra suggestion'));
    expect(text.style?.color, AyurezeTheme.sunshineYellow100);
  });
}

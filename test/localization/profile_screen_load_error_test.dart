import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/language_localization.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/features/profile/profile.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When astra's GET doctors/{id} fails, the profile screen shows the error
/// state with astra's message, not an empty form that looks like real data.
/// (One testWidgets per file: see AGENTS.md.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a failed profile load shows the error state with its message',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Swastu in the error state idles forever without reduced motion.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'current_language_code': 'en',
      'name': 'Test Doctor',
      'is_filled': 1,
      'image': '',
      'doctorId': 'doc-123',
    });
    await SharedPreferenceHelper.initWithPreferences(
        await SharedPreferences.getInstance());

    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        fetchDoctor: (id) async =>
            throw AstraApiException('Doctor not found', 404),
      ),
      locale: const Locale('en', 'US'),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        LanguageLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(OslerStateView), findsOneWidget);
    expect(find.text("Couldn't load your profile"), findsOneWidget);
    expect(find.text('Doctor not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

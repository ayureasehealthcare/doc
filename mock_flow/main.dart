// Mock flow harness - NOT part of the app. Runs the four companion
// features' real widgets against in-memory mock services, because the
// astra endpoints they target don't exist yet.
//
//   flutter run -d chrome -t mock_flow/main.dart
//   flutter build web -t mock_flow/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/language_localization.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/navigator_key.dart';
import 'package:doctro/features/authentication/SignIn.dart';
import 'package:doctro/features/cashfree/payment.dart';
import 'package:doctro/features/consultation/astra_chat/astra_chat_page.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:doctro/features/schedule/ScheduleTimings.dart';
import 'package:doctro/theme/theme_provider.dart';

import 'package:doctro/features/autopilot/review_queue_screen.dart';
import 'package:doctro/features/errors/error_utility_screen.dart';
import 'package:doctro/features/prescription/astra/prescription_screen.dart';
import 'package:doctro/features/prescription/pending_prescriptions_screen.dart';
import 'package:doctro/models/autopilot_action.dart';
import 'package:doctro/models/patient_wellness.dart';
import 'package:doctro/models/sharing_consent.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/astra_fill_display.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/widgets/patient_wellness_section.dart';
import 'package:doctro/widgets/sharing_consent_guard.dart';

const _astraFill = {
  'chief_complaint': 'Persistent dry cough and mild fever',
  'duration': '6 days',
  'extracted_symptoms': ['dry cough', 'mild fever', 'fatigue'],
  'severity_score': 5,
  'sleep': 'Disturbed by coughing',
  'appetite': 'Reduced',
  'timestamp': '2026-10-17T09:30:00Z',
};

PatientWellness _mockWellness() {
  final today = DateTime.now();
  return PatientWellness(
    entries: [
      for (var i = 0; i < 9; i++)
        WellnessEntry(
          dateKey: WellnessEntryKey.of(today.subtract(Duration(days: i))),
          sleepHours: const [6.5, 7.0, 5.5, 8.0, 7.5, 6.0, 7.0, 6.5, 8.0][i],
          movementMinutes: [20, 35, 0, 45, 30, 15, 25, 40, 10][i],
          relaxationMinutes: i.isEven ? 15 : null,
          mood: [4, 3, 2, 5, 4, 3, 4, 3, 5][i],
        ),
    ],
    goals: const [
      WellnessGoal(id: 'g1', title: 'Sleep 7+ hours'),
      WellnessGoal(id: 'g2', title: 'Walk 30 minutes daily'),
      WellnessGoal(id: 'g3', title: 'Morning pranayama', achieved: true),
    ],
  );
}

extension WellnessEntryKey on WellnessEntry {
  static String of(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// In-memory review queue. The item whose id is 'fail' is rejected by the
/// "server" so the error path can be seen.
class _MockQueue {
  final List<AutopilotAction> items = [
    AutopilotAction(
      id: 'gap-1',
      kind: AutopilotActionKind.careGap,
      title: 'No symptom check-in for 5 days',
      detail: 'Patient has missed daily check-ins since starting the '
          'prescribed course.',
      patientName: 'Demo Patient A',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      requiresSignOff: true,
    ),
    AutopilotAction(
      id: 'fu-1',
      kind: AutopilotActionKind.followUp,
      title: 'Suggest a 2-week follow-up',
      detail: 'Course ends in 3 days; Astra suggests a review consultation.',
      patientName: 'Demo Patient B',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    const AutopilotAction(
      id: 'fail',
      kind: AutopilotActionKind.other,
      title: 'Mock: the server rejects this item',
      detail: 'Acknowledging or dismissing this one fails on purpose, to '
          'show that it stays in the queue.',
      patientName: 'Demo Patient C',
    ),
  ];

  Future<List<AutopilotAction>> load(String _) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.of(items);
  }

  Future<bool> resolve(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (id == 'fail') return false;
    items.removeWhere((a) => a.id == id);
    return true;
  }
}

/// Build with --dart-define=MOCK_DARK=true to run the flow in dark mode.
const _dark = bool.fromEnvironment('MOCK_DARK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AyurezeTheme.updateThemeMode(_dark);
  // A stored doctor profile, so the real dashboard renders as it does
  // after login. API calls fail (no backend here) and screens show their
  // empty/error states, which is part of what this harness checks.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', true);
  await prefs.setString('current_language_code', 'en');
  await prefs.setString('name', 'Asha Rao');
  await prefs.setString('doctorId', 'demo-doctor');
  await prefs.setString('Currency Symbol', '₹');
  await SharedPreferenceHelper.initWithPreferences(prefs);
  runApp(const MockFlowApp());
}

class MockFlowApp extends StatelessWidget {
  const MockFlowApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          title: 'Doctor app - mock flow',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: _dark ? AyurezeTheme.darkTheme() : AyurezeTheme.lightTheme(),
          locale: const Locale('en', 'US'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            LanguageLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _Home(),
        ),
      );
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    void go(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    Widget tile(String key, String title, String subtitle, Widget page) =>
        ListTile(
          key: Key(key),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => go(page),
        );

    final queue = _MockQueue();
    return Scaffold(
      appBar: AppBar(title: const Text('Mock flow')),
      body: ListView(
        children: [
          tile(
              'case-full',
              '1. Patient case - full sharing',
              'Mock consent: full. Wellness log visible.',
              const _PatientCase(consent: SharingConsent.full)),
          tile(
              'case-limited',
              '2. Patient case - limited sharing',
              'Mock consent: limited. Banner, wellness withheld.',
              const _PatientCase(consent: SharingConsent.limited)),
          tile(
              'case-stub',
              '3. Patient case - today\'s stubs',
              'Real AstraApiService stubs: consent unknown.',
              const _PatientCase(consent: null)),
          tile(
              'rx',
              '4. Prescription - Astra-drafted diagnosis',
              'Badge flips when the doctor edits the diagnosis.',
              const PrescriptionScreen(
                patientId: 'demo-1',
                patientName: 'Demo Patient A',
                doctorId: 'demo-doctor',
                astraFillData: _astraFill,
              )),
          tile(
              'queue-mock',
              '5. Review queue - mock backend',
              'Acknowledge / dismiss; the third item fails on purpose.',
              ReviewQueueScreen(
                doctorId: 'demo-doctor',
                loader: queue.load,
                onAcknowledge: queue.resolve,
                onDismiss: queue.resolve,
              )),
          tile(
              'queue-stub',
              '6. Review queue - today\'s stubs',
              'Real AstraApiService stub: empty list.',
              const ReviewQueueScreen(doctorId: 'demo-doctor')),
          tile(
              'states',
              '7. Empty, error and loading states',
              'The shared kit states, now carried by Swastu.',
              const _StatesGallery()),
          tile(
              'offline',
              '8. Full-screen error page (offline)',
              'ErrorUtilityScreen with a sleepy Swastu.',
              const ErrorUtilityScreen(kind: ErrorUtilityKind.noInternet)),
          // The real screens, mounted without a backend.
          tile('signin', '9. Sign-in', 'Real SignIn screen.', SignIn()),
          tile('dashboard', '10. Dashboard', 'Real LoginHomeScreen.',
              const LoginHomeScreen(chat: '')),
          tile('astra', '11. Astra chat', 'Real AstraChatPage.',
              const AstraChatPage(patientName: 'Demo Patient A')),
          tile('schedule', '12. Schedule timings', 'Real ScheduleTimings.',
              const ScheduleTimings()),
          tile('payments', '13. Payments', 'Real PaymentScreen.',
              const PaymentScreen()),
          tile(
              'rx-queue',
              '14. Prescriptions to approve',
              'Real PendingPrescriptionsScreen.',
              const PendingPrescriptionsScreen()),
        ],
      ),
    );
  }
}

/// Stand-in for the patient detail screen: the same guard and sections,
/// without the Laravel appointment API the real screen needs.
class _PatientCase extends StatelessWidget {
  /// null = use the real (stubbed) AstraApiService.
  final SharingConsent? consent;

  const _PatientCase({required this.consent});

  @override
  Widget build(BuildContext context) {
    final mocked = consent != null;
    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(title: const Text('Demo Patient A')),
      body: SharingConsentGuard(
        patientId: 'demo-1',
        doctorId: 'demo-doctor',
        loader: mocked
            ? (_, __) async {
                await Future<void>.delayed(const Duration(milliseconds: 500));
                return consent!;
              }
            : null,
        child: ListView(
          padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
          children: [
            const AstraFillDisplayWidget(
              patientId: 'demo-1',
              preloadedData: _astraFill,
            ),
            const SizedBox(height: AyurezeTheme.spaceLg),
            PatientWellnessSection(
              patientId: 'demo-1',
              loader: mocked
                  ? (_) async => _mockWellness()
                  : AstraApiService().getPatientWellness,
            ),
          ],
        ),
      ),
    );
  }
}

/// The shared empty / error / loading views side by side.
class _StatesGallery extends StatelessWidget {
  const _StatesGallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(title: const Text('States')),
      body: ListView(
        children: [
          const OslerStateView(
            icon: HugeIcons.strokeRoundedVideo01,
            title: 'No calls yet',
            message: 'Video consultations you take will appear here.',
          ),
          OslerStateView.error(
            title: "Couldn't load call history",
            message: 'Check your connection and try again.',
            onRetry: () {},
          ),
          const SizedBox(
            height: 220,
            child: OslerLoadingView(message: 'Loading review queue…'),
          ),
        ],
      ),
    );
  }
}

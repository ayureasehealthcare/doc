import 'package:doctro/features/prescription/astra/prescription_screen.dart';
import 'package:doctro/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // PatientDetailsScreen requires a live Firebase/Firestore platform channel
  // (Firebase.initializeApp -> pigeon host API), which isn't available in a
  // pure widget test. Its build path is instead covered by the integration
  // build (flutter build web) and the existing view-model unit tests.

  testWidgets('PrescriptionScreen renders header', (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: MaterialApp(
        home: PrescriptionScreen(
          patientId: '123',
          patientName: 'Test Patient',
          patientPhone: '1234567890',
          doctorId: 'DOC1',
          astraFillData: const {
            'extracted_symptoms': ['fever', 'cough'],
          },
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Prescription'), findsOneWidget);
    expect(find.text('Test Patient'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

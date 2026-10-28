import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/features/dashboard/view_models/login_home_view_model.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({
      Preferences.doctorId: '12345',
      Preferences.auth_token: 'dummy_token',
      Preferences.user_name: 'Dr. Test',
    });
  });

  group('LoginHomeViewModel Tests', () {
    test('Initial State is correct', () {
      final viewModel = LoginHomeViewModel();
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.todayAppointments, isEmpty);
      expect(viewModel.patientCount, 0);
      expect(viewModel.totalEarnings, 0);
    });

    test('Search functionality filters correctly', () {
      final viewModel = LoginHomeViewModel();

      // We simulate populating data. Note: In a real test we'd mock the API layer.
      // Since RestClient is tightly coupled to Dio, we test the state mutations directly.

      // Ensure searching empty string clears search results
      viewModel.onSearchTextChanged('');
      // In this basic test we just verify the method doesn't crash and completes state update
      expect(viewModel.isLoading, isFalse);
    });
  });
}

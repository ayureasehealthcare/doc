import 'package:flutter/material.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/models/astra_doctor_mapper.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/services/astra_api_service.dart';

class SettingsViewModel extends ChangeNotifier {
  bool isCallEnable = false;
  bool isDarkMode = false;
  bool isNotificationEnabled = true;
  bool isLoading = false;

  void loadSettings() {
    isDarkMode = SharedPreferenceHelper.getBoolean(Preferences.is_dark_mode);
    isNotificationEnabled =
        SharedPreferenceHelper.getBoolean(Preferences.is_notification_enabled);
    notifyListeners();
  }

  void setDarkMode(bool val) {
    isDarkMode = val;
    notifyListeners();
  }

  void setNotificationEnabled(bool val) {
    isNotificationEnabled = val;
    SharedPreferenceHelper.setBoolean(Preferences.is_notification_enabled, val);
    notifyListeners();
  }

  Future<void> fetchDoctorProfile(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      // astra's doctor record (GET doctors/{id}) has no documented
      // patient_vcall field; the toggle only changes if the record happens
      // to carry one. With no stored doctor id there is nothing to fetch.
      final doctorId =
          SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
      if (doctorId != null) {
        final doctor = AstraDoctor.fromResponse(
            await AstraApiService().getDoctorProfile(doctorId));
        if (doctor.patientVCall != null) {
          isCallEnable = doctor.patientVCall == 1;
        }
      }
    } catch (error) {
      // The toggle keeps its current value; the settings screen still works
      // without the server's copy.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVCall(BuildContext context, bool val) async {
    isCallEnable = val;
    notifyListeners();

    int vCallData = val ? 1 : 0;
    Map<String, dynamic> body = {"patient_vcall": vCallData};
    try {
      final response = await RestClient(await RetroApi().dioData(context))
          .updatePatientVcallRequest(body);
      if (response.success == true) {
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }
}

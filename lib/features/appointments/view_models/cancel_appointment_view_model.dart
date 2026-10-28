import 'package:flutter/material.dart';
import 'package:doctro/models/cancel_appointment.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/pref_constant.dart';

class CancelAppointmentViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? dName;
  String? dFullImage;
  String? phone;
  int? subscription;

  final List<AppointmentCancel> _cancelAppointmentReq = [];
  List<AppointmentCancel> get cancelAppointmentReq => _cancelAppointmentReq;

  final List<AppointmentCancel> _searchResult = [];
  List<AppointmentCancel> get searchResult => _searchResult;

  final List<AppointmentCancel> _userCancel = [];

  TextEditingController searchController = TextEditingController();

  CancelAppointmentViewModel(BuildContext context) {
    _init(context);
    searchController.addListener(_onSearchTextChanged);
  }

  void _init(BuildContext context) async {
    dName = SharedPreferenceHelper.getString(Preferences.name);
    dFullImage = SharedPreferenceHelper.getString(Preferences.image);
    phone = SharedPreferenceHelper.getString(Preferences.phone_no);
    subscription =
        SharedPreferenceHelper.getInt(Preferences.subscription_status);
    await cancelAppointmentRequest(context);
  }

  Future<void> cancelAppointmentRequest(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      _cancelAppointmentReq.clear();
      _userCancel.clear();
      var response = await RestClient(await RetroApi().dioData(context))
          .cancelAppointmentRequest();

      if (response.data != null) {
        _cancelAppointmentReq.addAll(response.data!);
        _userCancel.addAll(response.data!);
      }
    } catch (error) {
      // Handle error if needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onSearchTextChanged() {
    String text = searchController.text;
    _searchResult.clear();
    if (text.isEmpty) {
      notifyListeners();
      return;
    }
    for (var cancelAppointmentData in _cancelAppointmentReq) {
      if ((cancelAppointmentData.patientName ?? "")
          .toLowerCase()
          .contains(text.toLowerCase())) {
        _searchResult.add(cancelAppointmentData);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

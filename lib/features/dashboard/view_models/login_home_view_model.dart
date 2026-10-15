import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/models/today_appointment.dart';
import 'package:doctro/models/payment.dart';
import 'package:doctro/models/review.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/utils/logger.dart';
import 'package:doctro/network/network_api.dart';

class LoginHomeViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = "";

  String? dName;
  String? dFullImage;
  int? isFilled;
  int? subscription;
  String? phone;

  List<Today> todayAppointments = [];
  List<Tomorrow> tomorrowAppointments = [];
  List<Upcoming> upcomingAppointments = [];

  List<Today> searchResult = [];
  List<Tomorrow> tomorrowSearchResult = [];
  List<Upcoming> upcomingSearchResult = [];

  double totalEarnings = 0;
  int reviewCount = 0;
  int patientCount = 0;

  void initializeData(BuildContext context) {
    Future.delayed(Duration.zero, () {
      // The caller passes the widget's context into create(), and this callback
      // is deferred, so the widget may already be gone.
      if (!context.mounted) return;
      final isLoggedIn =
          SharedPreferenceHelper.getBoolean(Preferences.is_logged_in);

      if (isLoggedIn) {
        settingRequest(context);
        fetchAppointments(context);
      }

      // getStringOrNull, not getString: an unset or blank name must reach
      // the UI as null so its "Dr. ${dName ?? 'Doctor'}" fallback fires,
      // rather than rendering the raw 'N_A' sentinel or a bare "Dr.".
      dName = SharedPreferenceHelper.getStringOrNull(Preferences.name);
      dFullImage = SharedPreferenceHelper.getString(Preferences.image);
      isFilled = SharedPreferenceHelper.getInt(Preferences.is_filled);
      subscription =
          SharedPreferenceHelper.getInt(Preferences.subscription_status);
      phone = SharedPreferenceHelper.getString(Preferences.phone_no);
      notifyListeners();
    });
  }

  Future<void> fetchAppointments(BuildContext context) async {
    isLoading = true;
    hasError = false;
    errorMessage = "";
    notifyListeners();

    try {
      todayAppointments.clear();
      tomorrowAppointments.clear();
      upcomingAppointments.clear();
      totalEarnings = 0;

      final client = RestClient(await RetroApi().dioData(context));

      // Fetch appointments + auxiliary data in parallel. Payments/reviews are
      // best-effort: a failure there should not blank out the whole screen.
      final results = await Future.wait<dynamic>([
        client.todayAppointments(),
        client
            .paymentRequest()
            .catchError((_) => Payment(success: false, paymentData: [])),
        client
            .reviewRequest()
            .catchError((_) => Review(success: false, data: [])),
      ]);

      final TodayAppointment response = results[0] as TodayAppointment;
      final Payment payments = results[1] as Payment;
      final Review reviews = results[2] as Review;

      if (payments.paymentData != null) {
        for (var p in payments.paymentData!) {
          totalEarnings += double.tryParse(p.amount.toString()) ?? 0;
        }
      }

      if (reviews.data != null) {
        reviewCount = reviews.data!.length;
      }

      if (response.data?.today != null && response.data!.today!.isNotEmpty) {
        response.data!.today!.sort((a, b) => DateFormat("yyyy-MM-dd h:mm a")
            .parse(
                "${DateTime.now().toString().split(" ")[0]} ${(a.time ?? "00:00 AM").toUpperCase()}")
            .compareTo(DateFormat("yyyy-MM-dd h:mm a").parse(
                "${DateTime.now().toString().split(" ")[0]} ${(b.time ?? "00:00 AM").toUpperCase()}")));
        todayAppointments.addAll(response.data!.today!);
      }

      if (response.data?.tomorrow != null &&
          response.data!.tomorrow!.isNotEmpty) {
        response.data!.tomorrow!.sort((a, b) => DateFormat("yyyy-MM-dd h:mm a")
            .parse(
                "${DateTime.now().toString().split(" ")[0]} ${(a.time ?? "00:00 AM").toUpperCase()}")
            .compareTo(DateFormat("yyyy-MM-dd h:mm a").parse(
                "${DateTime.now().toString().split(" ")[0]} ${(b.time ?? "00:00 AM").toUpperCase()}")));
        tomorrowAppointments.addAll(response.data!.tomorrow!);
      }

      if (response.data?.upcoming != null &&
          response.data!.upcoming!.isNotEmpty) {
        response.data!.upcoming!.sort((a, b) => DateFormat("yyyy-MM-dd h:mm a")
            .parse(
                "${DateTime.now().toString().split(" ")[0]} ${(a.time ?? "00:00 AM").toUpperCase()}")
            .compareTo(DateFormat("yyyy-MM-dd h:mm a").parse(
                "${DateTime.now().toString().split(" ")[0]} ${(b.time ?? "00:00 AM").toUpperCase()}")));
        upcomingAppointments.addAll(response.data!.upcoming!);
      }

      Set<String> uniquePatients = {};
      for (var a in todayAppointments) {
        if (a.patientName != null) uniquePatients.add(a.patientName!);
      }
      for (var a in tomorrowAppointments) {
        if (a.patientName != null) uniquePatients.add(a.patientName!);
      }
      for (var a in upcomingAppointments) {
        if (a.patientName != null) uniquePatients.add(a.patientName!);
      }
      patientCount = uniquePatients.length;
    } catch (error) {
      hasError = true;
      errorMessage = ServerError.withError(error: error).getErrorMessage();
      if (errorMessage.isEmpty) {
        errorMessage = "Failed to load appointments. Please try again.";
      }
      logger.e("fetchAppointments failed: $error");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> settingRequest(BuildContext context) async {
    try {
      final response =
          await RestClient(await RetroApi().dioData(context)).settingRequest();
      if (response.data?.agoraAppId != null) {
        SharedPreferenceHelper.setString(
            Preferences.agoraAppId, response.data!.agoraAppId!);
      }
      if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
        if (response.data!.currencySymbol != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_symbol, response.data!.currencySymbol!);
        }
        if (response.data!.currencyCode != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_code, response.data!.currencyCode!);
        }
        if (response.data!.doctorAppId != null) {
          SharedPreferenceHelper.setString(
              Preferences.doctorAppId, response.data!.doctorAppId!);
        }
      }
    } catch (error) {
      // error handling
    }
  }

  void onSearchTextChanged(String text) {
    searchResult.clear();
    tomorrowSearchResult.clear();
    upcomingSearchResult.clear();
    if (text.isEmpty) {
      notifyListeners();
      return;
    }

    for (var appointmentData in todayAppointments) {
      if ((appointmentData.patientName ?? "")
          .toLowerCase()
          .contains(text.toLowerCase())) {
        searchResult.add(appointmentData);
      }
    }

    for (var tomorrowData in tomorrowAppointments) {
      if ((tomorrowData.patientName ?? "")
          .toLowerCase()
          .contains(text.toLowerCase())) {
        tomorrowSearchResult.add(tomorrowData);
      }
    }

    for (var upcomingData in upcomingAppointments) {
      if ((upcomingData.patientName ?? "")
          .toLowerCase()
          .contains(text.toLowerCase())) {
        upcomingSearchResult.add(upcomingData);
      }
    }

    notifyListeners();
  }
}

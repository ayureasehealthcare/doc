import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/models/today_appointment.dart';
import 'package:doctro/models/payment.dart';
import 'package:doctro/models/review.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/services/astra_api_service.dart';
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

  // The legacy today/tomorrow/upcoming split (Apis.appointment, via
  // RestClient.todayAppointments()) is permanently dead - confirmed 404 on
  // the real backend. The real source is AstraApiService.getMyAppointments()
  // (GET /api/v1/appointments/my), which only recently started accepting a
  // doctor token at all (previously 403 "Insufficient role" - fixed
  // server-side 2026-10-14) and returns a flat, unsorted list of raw
  // `consultations` rows with no today/tomorrow/upcoming grouping and no
  // patient name (only patient_id) - both done here instead.
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
        AstraApiService().getMyAppointments(),
        client
            .paymentRequest()
            .catchError((_) => Payment(success: false, paymentData: [])),
        client
            .reviewRequest()
            .catchError((_) => Review(success: false, data: [])),
      ]);

      final appointments = (results[0] as Map<String, dynamic>)['appointments']
              as List<dynamic>? ??
          [];
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

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // (parsed local date/time, raw row) per bucket, so each bucket can be
      // sorted by the real DateTime before being converted into the display
      // model - the legacy sort above reparsed a formatted time string
      // against today's date even for tomorrow/upcoming items, which this
      // avoids entirely.
      final todayRows = <(DateTime, Map<String, dynamic>)>[];
      final tomorrowRows = <(DateTime, Map<String, dynamic>)>[];
      final upcomingRows = <(DateTime, Map<String, dynamic>)>[];

      for (final raw in appointments) {
        final map = raw as Map<String, dynamic>;
        if (map['status'] == 'cancelled') continue;
        final rawDate = map['appointment_date'] as String?;
        if (rawDate == null) continue;
        DateTime parsed;
        try {
          parsed = DateTime.parse(rawDate).toLocal();
        } catch (_) {
          continue;
        }
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day == today) {
          todayRows.add((parsed, map));
        } else if (day == tomorrow) {
          tomorrowRows.add((parsed, map));
        } else if (day.isAfter(tomorrow)) {
          upcomingRows.add((parsed, map));
        }
      }

      todayRows.sort((a, b) => a.$1.compareTo(b.$1));
      tomorrowRows.sort((a, b) => a.$1.compareTo(b.$1));
      upcomingRows.sort((a, b) => a.$1.compareTo(b.$1));

      String? addressFor(Map<String, dynamic> map) {
        final type = map['consultation_type'] as String?;
        if (type == null || type.isEmpty) return null;
        return '${type[0].toUpperCase()}${type.substring(1)} Consultation';
      }

      for (final (parsed, map) in todayRows) {
        todayAppointments.add(Today(
          time: DateFormat('h:mm a').format(parsed),
          date: DateFormat('yyyy-MM-dd').format(parsed),
          patientAddress: addressFor(map),
        ));
      }
      for (final (parsed, map) in tomorrowRows) {
        tomorrowAppointments.add(Tomorrow(
          time: DateFormat('h:mm a').format(parsed),
          date: DateFormat('yyyy-MM-dd').format(parsed),
          patientAddress: addressFor(map),
        ));
      }
      for (final (parsed, map) in upcomingRows) {
        upcomingAppointments.add(Upcoming(
          time: DateFormat('h:mm a').format(parsed),
          date: DateFormat('yyyy-MM-dd').format(parsed),
          patientAddress: addressFor(map),
        ));
      }

      final uniquePatients = <String>{};
      for (final raw in appointments) {
        final patientId = (raw as Map<String, dynamic>)['patient_id'];
        if (patientId != null) uniquePatients.add(patientId.toString());
      }
      patientCount = uniquePatients.length;
    } catch (error) {
      hasError = true;
      // ServerError.withError() only handles DioException (every other call
      // site in this app routes through RestClient/Dio, which only ever
      // throws that); getMyAppointments() instead throws AstraApiException,
      // so it needs its own branch rather than an unguarded cast.
      if (error is AstraApiException) {
        errorMessage = error.message;
      } else {
        errorMessage = ServerError.withError(error: error).getErrorMessage();
      }
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

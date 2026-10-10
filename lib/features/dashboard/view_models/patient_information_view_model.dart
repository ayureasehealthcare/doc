import 'package:flutter/material.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/models/appointment_details.dart';
import 'package:doctro/models/DoctorStatusChange.dart';
import 'package:doctro/models/AllMedicines.dart';
import 'package:doctro/services/astra_service.dart';
import 'package:intl/intl.dart';

class DateUtil {
  static const DATE_FORMAT = 'dd-MM-yyyy';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

class PatientInformationViewModel extends ChangeNotifier {
  final int? id;
  final BuildContext context;

  PatientInformationViewModel(this.id, this.context) {
    init();
  }

  // Astra Fill Data (Health intake from patient's app)
  final AstraService _astraService = AstraService();
  Map<String, dynamic>? astraFillData;
  bool isLoadingAstraFill = false;

  //Pdf Pass Data
  String? valueDays;
  bool? alertValueFirst = false;
  bool? alertValueSecond = false;
  bool? alertValueThird = false;

  //Set List for Report Image
  List<String> reportImages = [];

  //set hide show approve and cancel button
  bool hideButton = true;

  //Show Signal Appointment Details
  int? userId;
  int? age;
  double? amount;
  String? phoneNo = "";
  String? name = "";
  String? appointmentId = "";
  String? patientAddress = "";
  String date = "";
  String? illness = "";
  String? note = "";
  String? drugEffect = "";
  String? time = "";
  String? fullImage = "";
  String? appointment = "";
  String? appointmentType = "";
  String? appointmentStatus = "";
  String? pdf = "";
  int isInsured = 0;
  String policyInsurerName = "";
  String policyNumber = "";
  String? astraCaseId;

  bool isLoading = true;

  List<String> medicineReq = [];

  void init() {
    appointmentDetails();
  }

  Future<void> loadAstraFillData(
      {String? patientId, String? searchPhone}) async {
    final targetId = patientId ?? userId?.toString();
    final targetPhone = searchPhone ?? phoneNo;

    if (targetId == null && targetPhone == null) return;

    isLoadingAstraFill = true;
    notifyListeners();

    try {
      Map<String, dynamic> data = {};

      // 1. Try loading by ID if available
      if (targetId != null) {
        data = await _astraService.getLatestAstraFill(targetId);
      }

      // 2. Fallback: If no data or loading by ID failed, try searching by phone in Astra
      if ((data.isEmpty) && targetPhone != null && targetPhone.isNotEmpty) {
        // Clean phone number (remove +, spaces, etc. for search)
        String cleanPhone = targetPhone.replaceAll(RegExp(r'\D'), '');
        final searchResults = await _astraService.searchPatients(cleanPhone);

        if (searchResults.isNotEmpty) {
          // Found matching patient in Astra! Use their Astra ID
          final astraPatient = searchResults[0];
          final astraId =
              astraPatient['id']?.toString() ?? astraPatient['uid']?.toString();
          if (astraId != null) {
            data = await _astraService.getLatestAstraFill(astraId);
          }
        }
      }

      astraFillData = data;
      isLoadingAstraFill = false;
      notifyListeners();
    } catch (e) {
      isLoadingAstraFill = false;
      notifyListeners();
    }
  }

  Future<BaseModel<DoctorStatusChange>> statusChangeRequest(
      String status) async {
    Map<String, dynamic> body = {"id": id, "status": status};

    DoctorStatusChange response;

    try {
      response = await RestClient(await RetroApi().dioData(context))
          .doctorStatusChangeRequest(body);

      if (status == 'approve') {
        appointmentStatus = 'approve';
      } else if (status == 'complete') {
        appointmentStatus = 'complete';
      } else {
        appointmentStatus = 'cancel';
      }

      hideButton = false;
      notifyListeners();

      return BaseModel()..data = response;
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
  }

  Future<BaseModel<AllMedicines>> allMedicinesRequest() async {
    AllMedicines response;

    try {
      medicineReq.clear();

      response =
          await RestClient(await RetroApi().dioData(context)).allMedicines();

      for (int i = 0; i < response.data!.length; i++) {
        medicineReq.add(response.data![i].name.toString());
      }
      notifyListeners();

      return BaseModel()..data = response;
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
  }

  Future<void> appointmentDetails() async {
    isLoading = true;
    notifyListeners();
    try {
      AppointmentDetails response =
          await RestClient(await RetroApi().dioData(context))
              .appointmentDetails(id);

      name = response.data!.patientName;
      age = response.data!.age;
      amount = double.parse(response.data!.amount!);
      date = DateUtil().formattedDate(DateTime.parse(response.data!.date!));
      phoneNo = response.data!.phoneNo;
      patientAddress = response.data!.patientAddress;
      illness = response.data!.illnessInformation;
      note = response.data!.note;
      appointmentId = response.data!.appointmentId;
      drugEffect = response.data!.drugEffect;
      time = response.data!.time;
      fullImage = response.data!.user!.fullImage;
      appointment = response.data!.appointmentFor;
      appointmentType = response.data!.appointmentType;
      appointmentStatus = response.data!.appointmentStatus;
      userId = response.data!.userId;
      pdf = response.data!.pdf;
      reportImages.addAll(response.data!.reportImage!);
      isInsured = response.data!.isInsured!;
      policyInsurerName = response.data!.policyInsurerName ?? "";
      policyNumber = response.data!.policyNumber ?? "";
      astraCaseId = response.data!.astraCaseId;

      appointmentStatus == 'Approve' ? hideButton = false : hideButton = true;
      appointmentStatus == 'pending' ? hideButton = true : hideButton = false;

      isLoading = false;
      notifyListeners();

      // After loading appointment details, refresh Astra Fill data with resolved IDs
      loadAstraFillData(patientId: userId.toString(), searchPhone: phoneNo);
    } catch (error) {
      isLoading = false;
      notifyListeners();
    }
  }
}

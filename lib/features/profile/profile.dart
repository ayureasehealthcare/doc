import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/ayureze_date_picker.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/EducationCertificate.dart';
import 'package:doctro/models/EducationModel.dart';
import 'package:doctro/models/Treatment.dart';
import 'package:doctro/models/categories.dart';
import 'package:doctro/models/astra_doctor_mapper.dart';
import 'package:doctro/models/expertise.dart';
import 'package:doctro/models/hospital.dart';
import 'package:doctro/models/update_profile_image.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/services/doctor_id_resolver.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_dropdown.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.fetchDoctor});

  /// Loads the doctor record; defaults to [AstraApiService.getDoctorProfile].
  /// Tests pass a fake so the screen can render without a server.
  final Future<Map<String, dynamic>> Function(String doctorId)? fetchDoctor;

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

//profile image
String? name = "";
String? msg = "";

//Choose Images
String? image;

class _ProfileScreen extends State<ProfileScreen> {
  Future? doctorLoader;

  /// Why the profile couldn't be loaded, shown instead of an empty form.
  String? _loadError;

  /// Values of the fields astra can't store, as loaded. [updateProfile]
  /// diffs against these to tell the doctor which edits were not saved.
  Map<String, String> _unsupportedAtLoad = const {};

  //Add List Data
  List<EducationModel> educationList = [];
  List<EducationCertificate> certificateList = [];

  bool oldPassword = false;

  //alertdialog
  final TextEditingController _degree = TextEditingController();
  final TextEditingController _college = TextEditingController();
  final TextEditingController _completeYear = TextEditingController();
  final TextEditingController _certificate = TextEditingController();
  final TextEditingController _year = TextEditingController();

  String callDegree = '';
  String callCollege = '';
  String callYear = '';
  String callCertificate = '';
  String callCertificateYear = '';
  String valueDegree = '';
  String valueCollege = '';
  String valueYear = '';
  String certificate = '';
  String certificateYear = '';

  //Select Dob
  DateTime? _selectedDate;
  String newDateApiPass = "";
  String? showFormat = '';
  String? temp;
  List<String> selectedHospitals = [];

  //Set Stepper
  int _currentStep = 0;
  StepperType stepperType = StepperType.horizontal;

  //Doctor Profile Controller
  final TextEditingController _pDegree = TextEditingController();
  final TextEditingController _pExperience = TextEditingController();
  final TextEditingController _pStartTime = TextEditingController();
  final TextEditingController _pEndTime = TextEditingController();
  final TextEditingController _pTimeSlot = TextEditingController();
  final TextEditingController _vAppointmentFees = TextEditingController();
  final TextEditingController _aAppointmentFees = TextEditingController();
  final TextEditingController _pName = TextEditingController();
  final TextEditingController _pDob = TextEditingController();
  final TextEditingController _pDesc = TextEditingController();
  final TextEditingController _pCollege = TextEditingController();
  final TextEditingController _pCollegeYear = TextEditingController();
  final TextEditingController _pCertificate = TextEditingController();
  final TextEditingController _pCertificateYear = TextEditingController();
  final TextEditingController _pBasedOn = TextEditingController();

  //Set Open Drawer
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<FormState> _step1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _step2 = GlobalKey<FormState>();

  //Set List Data Hospital
  List<HospitalName> hospitalReq = [];

  //Set List Data Treatment
  List<TreatmentData> treatmentReq = [];

  //Set List Data Category
  List<CategoriesData> categoryReq = [];
  CategoriesData? _valueCategories;

  //Set List Data Expertise
  List<Expert> expertReq = [];

  //update user image
  File? proImage;
  final picker = ImagePicker();

  //Set DropDown Popular Field
  List<String> popular = [];
  String? _selectedPopular;

  //Set DropDown For Male/Female
  List<String> gender = [];
  String? _genderSelect;

  int? isFilled;

  //Set MediaQuery Height / Width
  double? width;
  late double height;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gender = [
      "male",
      "female",
    ];

    popular = [
      getTranslated(context, AppString.popular_yes).toString(),
      getTranslated(context, AppString.popular_no).toString(),
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      setState(() {
        doctorLoader = Future.wait([treatment(), doctorProfile()]);
        name = SharedPreferenceHelper.getString(Preferences.name);
        isFilled = SharedPreferenceHelper.getInt(Preferences.is_filled);
        image = SharedPreferenceHelper.getString(Preferences.image);
      });
      hospital();
    });
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: PreferredSize(
        preferredSize: Size(width! * 0.3, 220),
        child: _ProfileHeader(
          width: width!,
          proImage: proImage,
          onBack: () {
            if (_currentStep == 0) Navigator.pop(context);
            if (_currentStep == 1) cancel();
            if (_currentStep == 2) cancel();
          },
          onChooseImage: chooseProfileImage,
        ),
      ),
      body: FutureBuilder(
          future: doctorLoader,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _loadError != null) {
              return OslerStateView.error(
                title: "Couldn't load your profile",
                message: _loadError,
                onRetry: () => setState(() => doctorLoader = doctorProfile()),
              );
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AyurezeTheme.forestDeep,
                        secondary: AyurezeTheme.healingGreen50,
                      ),
                ),
                child: Container(
                  width: width,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AyurezeTheme.spaceSm,
                      vertical: AyurezeTheme.spaceSm),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stepper(
                          type: stepperType,
                          physics: ScrollPhysics(),
                          onStepCancel: null,
                          currentStep: _currentStep,
                          onStepTapped: (step) => tapped(step),
                          onStepContinue: continued,
                          steps: <Step>[
                            // Step 1 //
                            Step(
                              title: SizedBox(
                                width: 64,
                                child: Text(
                                  getTranslated(
                                          context,
                                          AppString
                                              .profile_personal_information)
                                      .toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              content: _ProfileStep1PersonalInfo(
                                formKey: _step1,
                                width: width!,
                                nameController: _pName,
                                dobController: _pDob,
                                descriptionController: _pDesc,
                                genderValue: _genderSelect,
                                genderOptions: gender,
                                onGenderChanged: (value) =>
                                    _genderSelect = value,
                                onDobTap: () => _selectDate(context),
                              ),
                              isActive: _currentStep >= 0,
                              state: _currentStep >= 0
                                  ? StepState.complete
                                  : StepState.disabled,
                            ),
                            // Step 2 //
                            Step(
                              title: SizedBox(
                                width: 64,
                                child: Text(
                                  getTranslated(
                                          context,
                                          AppString
                                              .profile_education_information)
                                      .toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              content: _ProfileStep2Education(
                                formKey: _step2,
                                width: width!,
                                height: height,
                                degreeController: _pDegree,
                                collegeController: _pCollege,
                                collegeYearController: _pCollegeYear,
                                certificateController: _pCertificate,
                                certificateYearController: _pCertificateYear,
                                onAddEducation: _showAddEducationDialog,
                                onAddCertificate: _showAddCertificateDialog,
                              ),
                              isActive: _currentStep >= 0,
                              state: _currentStep >= 1
                                  ? StepState.complete
                                  : StepState.disabled,
                            ),
                            // Step 3 //
                            Step(
                              title: SizedBox(
                                width: 64,
                                child: Text(
                                  getTranslated(context,
                                          AppString.profile_other_information)
                                      .toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              content: _ProfileStep3ProfessionalDetails(
                                formKey: _formkey,
                                width: width!,
                                experienceController: _pExperience,
                                videoFeeController: _vAppointmentFees,
                                audioFeeController: _aAppointmentFees,
                                timeSlotController: _pTimeSlot,
                                basedOnController: _pBasedOn,
                                startTimeController: _pStartTime,
                                endTimeController: _pEndTime,
                                selectedPopular: _selectedPopular,
                                popularOptions: popular,
                                onBasedOnChanged: onBasedOnChanged,
                                onPopularChanged: onPopularChanged,
                                onPickStartTime: onPickStartTime,
                                onPickEndTime: onPickEndTime,
                              ),
                              isActive: _currentStep >= 0,
                              state: _currentStep >= 2
                                  ? StepState.complete
                                  : StepState.disabled,
                            ),
                          ],
                          controlsBuilder:
                              (BuildContext context, ControlsDetails controls) {
                            return Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SizedBox(),
                                SizedBox(),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(
                  color: AyurezeTheme.iconPrimary,
                ),
              );
            }
          }),
      bottomNavigationBar: Container(
        color: AyurezeTheme.canvas,
        padding: const EdgeInsets.fromLTRB(AyurezeTheme.spaceLg,
            AyurezeTheme.spaceSm, AyurezeTheme.spaceLg, AyurezeTheme.spaceLg),
        height: width! * 0.18,
        child: OslerButton(
          text: _currentStep < 2
              ? getTranslated(context, AppString.profile_continue_button)
                  .toString()
              : getTranslated(context, AppString.profile_submit_button)
                  .toString(),
          onPressed: () {
            if (_currentStep == 0 && _step1.currentState!.validate()) {
              selectedHospitals.clear();
              for (int i = 0; i < hospitalReq.length; i++) {
                if (hospitalReq[i].isSelected == true) {
                  selectedHospitals.add(hospitalReq[i].id.toString());
                }
              }
              if (selectedHospitals.isEmpty) {
                selectedHospitals.add("1");
              }
              continued();
            } else if (_currentStep == 1 && _step2.currentState!.validate()) {
              List<String> degree = [];
              List<String> college = [];
              List<String> year = [];
              List<String> certificate = [];
              List<String> certificateYear = [];

              degree = _pDegree.text.toString().split(",");
              college = _pCollege.text.toString().split(',');
              year = _pCollegeYear.text.toString().split(',');
              certificate = _pCertificate.text.toString().split(',');
              certificateYear = _pCertificateYear.text.toString().split(',');

              educationList.clear();
              certificateList.clear();

              for (int i = 0; i < degree.length; i++) {
                EducationModel education = EducationModel();
                education.degree = degree[i];
                education.college = college[i];
                education.year = year[i];
                educationList.add(education);
              }

              for (int i = 0; i < certificate.length; i++) {
                EducationCertificate certificateData = EducationCertificate();
                certificateData.certificate = certificate[i];
                certificateData.certificateYear = certificateYear[i];
                certificateList.add(certificateData);
              }

              continued();
            } else {
              if (_currentStep == 2 && _formkey.currentState!.validate()) {
                updateProfile();
              }
            }
          },
        ),
      ),
    );
  }

  /// The fields of this screen that astra's doctor update
  /// (UpdateDoctorRequest) can't store, keyed by the label shown to the
  /// doctor. Only name, video call fee and description are saved.
  Map<String, String> _unsupportedFields() => {
        "Date of birth": _pDob.text,
        "Gender": _genderSelect ?? "",
        "Education":
            [_pDegree.text, _pCollege.text, _pCollegeYear.text].join("|"),
        "Certificates": [_pCertificate.text, _pCertificateYear.text].join("|"),
        "Experience": _pExperience.text,
        "Audio call fee": _aAppointmentFees.text,
        "Time slot": _pTimeSlot.text,
        "Working hours": "${_pStartTime.text}|${_pEndTime.text}",
        "Revenue model": _pBasedOn.text,
        "Popular": _selectedPopular ?? "",
        "Hospitals": [
          for (final h in hospitalReq)
            if (h.isSelected == true) h.id.toString()
        ].join(","),
      };

  Future<void> updateProfile() async {
    final doctorId =
        SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    if (doctorId == null) {
      OslerToast.error(context,
          "We couldn't find your doctor ID. Please sign in again, then save your profile.");
      return;
    }
    // PUT doctors/{id} accepts name, phone, specialization,
    // consultation_fee, available_days, available_times and bio. This screen
    // has name, description (bio) and the video call fee (the app's
    // consultations are video calls, so that fee is consultation_fee).
    // Everything else is diffed below and reported as not saved.
    final unsaved = AstraDoctorMapper.changedFields(
        _unsupportedAtLoad, _unsupportedFields());
    try {
      await AstraApiService().updateDoctorProfile(
        doctorId,
        AstraDoctorMapper.updateBody(
          name: _pName.text,
          fee: _vAppointmentFees.text,
          bio: _pDesc.text,
        ),
      );
      // The preference write is a side effect, not a UI action, so it stays
      // outside the guard. Only the context uses need mounted.
      SharedPreferenceHelper.setInt(Preferences.is_filled, 1);
      SharedPreferenceHelper.setString(Preferences.name, _pName.text);
      if (mounted) {
        Navigator.pushNamed(context, "loginHome");
        if (unsaved.isEmpty) {
          OslerToast.success(context, "Profile saved");
        } else {
          OslerToast.info(context, AstraDoctorMapper.unsavedMessage(unsaved));
        }
      }
    } on AstraApiException catch (e) {
      if (mounted) OslerToast.error(context, e.message);
    } catch (e) {
      if (mounted) {
        OslerToast.error(
            context, "Couldn't save your profile. Please try again.");
      }
    }
  }

  // The legacy REST endpoint this used to call (GET doctor_profile) is
  // permanently dead - confirmed 404 on the real backend. The real doctor
  // record lives at GET /api/v1/api/doctors/{doctor_id} (AstraApiService.
  // getDoctorProfile). Its response schema is undocumented; an earlier
  // check (2026-10-13, a real test account) saw name/email/phone/gender/
  // dob/specialization/photo_url/certificate_url/is_face_verified under
  // `data`. AstraDoctor.fromResponse reads it defensively. Fields with no
  // astra counterpart (hospital, education/certificate lists, audio fee,
  // timeslot, hours, based-on, popularity) stay at their empty defaults.
  Future<void> doctorProfile() async {
    final doctorId =
        SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    if (doctorId == null) {
      _loadError =
          "We couldn't find your doctor ID. Please sign in again to load your profile.";
      return;
    }
    try {
      final fetch = widget.fetchDoctor ?? AstraApiService().getDoctorProfile;
      Map<String, dynamic> record;
      try {
        record = await fetch(doctorId);
      } on AstraApiException catch (e) {
        // The stored id can be one astra doesn't know (see
        // DoctorIdResolver); find the right one and try once more.
        if (e.statusCode != 404 || widget.fetchDoctor != null) rethrow;
        final resolved = await DoctorIdResolver.ensure();
        if (resolved == null) {
          _loadError = "Your doctor profile isn't set up on the Astra server "
              "yet. Please contact support to have it created.";
          return;
        }
        record = await fetch(resolved);
      }
      final doctor = AstraDoctor.fromResponse(record);
      if (!mounted) return;

      _pName.text = doctor.name ?? _pName.text;
      final gender = doctor.gender?.toLowerCase();
      if (gender != null && this.gender.contains(gender)) {
        _genderSelect = gender;
      }
      _pDesc.text = doctor.bio ?? _pDesc.text;
      if (doctor.experienceYears != null) {
        _pExperience.text = doctor.experienceText;
      }
      if (doctor.consultationFee != null) {
        _vAppointmentFees.text = doctor.feeText;
      }

      final rawDob = doctor.dob;
      if (rawDob != null && rawDob.isNotEmpty) {
        showFormat = rawDob;
        try {
          if (rawDob.contains("-") && rawDob.indexOf("-") == 4) {
            DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(rawDob);
            _pDob.text = DateFormat('dd-MM-yyyy').format(parsedDate);
            _selectedDate = parsedDate;
          } else {
            _pDob.text = rawDob;
            try {
              _selectedDate = DateFormat('dd-MM-yyyy').parse(rawDob);
            } catch (_) {
              // Legacy date format: fall back to the raw text if it cannot be parsed.
            }
          }
        } catch (e) {
          _pDob.text = rawDob;
        }
      }

      _unsupportedAtLoad = _unsupportedFields();
      setState(() => _loadError = null);
    } on AstraApiException catch (e) {
      _loadError = e.message;
    } catch (_) {
      _loadError = "Check your connection and try again.";
    }
  }

  Future<BaseModel<Hospitals>> hospital() async {
    Hospitals response;
    try {
      hospitalReq.clear();
      response =
          await RestClient(await RetroApi().dioData(context)).hospitalRequest();
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        for (int i = 0; i < response.data!.length; i++) {
          hospitalReq.add(response.data![i]);
        }
      });
    } catch (error) {
      // print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<ImageUpload>> uploadImage() async {
    Map<String, dynamic> body = {
      "image": image,
    };
    ImageUpload response;
    try {
      response =
          await RestClient(await RetroApi().dioData(context)).uploadImage(body);
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        msg = response.data;
        SharedPreferenceHelper.setString(Preferences.image, response.data!);
      });
    } catch (error) {
      // print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  void proImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    setState(() {
      if (pickedFile != null) {
        SharedPreferenceHelper.setString(Preferences.image, pickedFile.path);
        proImage = File(SharedPreferenceHelper.getString(Preferences.image));
        List<int> imageBytes = proImage!.readAsBytesSync();
        image = base64Encode(imageBytes);
        uploadImage();
      } else {
        // print('No image selected.');
      }
    });
  }

  void proImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    setState(() {
      if (pickedFile != null) {
        SharedPreferenceHelper.setString(Preferences.image, pickedFile.path);
        proImage = File(SharedPreferenceHelper.getString(Preferences.image));
        List<int> imageBytes = proImage!.readAsBytesSync();
        image = base64Encode(imageBytes);
        uploadImage();
      } else {
        // print('No image selected.');
      }
    });
  }

  void chooseProfileImage() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: HugeIcon(icon: AppIcons.photo),
                  title: Text(
                    getTranslated(context, AppString.choose_image_gallery)
                        .toString(),
                  ),
                  onTap: () {
                    proImageFromGallery();
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: HugeIcon(icon: AppIcons.camera),
                title: Text(
                  getTranslated(context, AppString.choose_image_camera)
                      .toString(),
                ),
                onTap: () {
                  proImageFromCamera();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<BaseModel> treatment() async {
    Treatment response;
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .treatmentRequest();
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        for (int i = 0; i < response.data!.length; i++) {
          treatmentReq.add(response.data![i]);
        }
      });
    } catch (error) {
      // print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<Categories>> category(
      id, categoryId, int? expertiseId) async {
    Categories response;
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .categoryRequest(id);
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        for (int i = 0; i < response.categoriesData!.length; i++) {
          categoryReq.add(response.categoriesData![i]);
        }

        if (categoryReq.isNotEmpty) {
          for (int i = 0; i < categoryReq.length; i++) {
            if (categoryId == categoryReq[i].id) {
              _valueCategories = categoryReq[i];
              expertise(_valueCategories!.id, expertiseId);
            }
          }
        }
      });
    } catch (error) {
      // print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<Expertise>> expertise(id, expertiseId) async {
    Expertise response;
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .expertiseRequest(id);
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        for (int i = 0; i < response.expertiseData!.length; i++) {
          expertReq.add(response.expertiseData![i]);
        }
      });
    } catch (error) {
      // print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  _selectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showAyurezeDatePicker(
      context: context,
      initialDate: _selectedDate != null
          ? _selectedDate!
          : DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950, 1),
      lastDate: DateTime.now(),
      accentColor: AyurezeTheme.healingGreen100,
    );
    if (newSelectedDate != null) {
      _selectedDate = newSelectedDate;
      _pDob
        ..text = DateFormat('dd-MM-yyyy').format(_selectedDate!)
        ..selection = TextSelection.fromPosition(
          TextPosition(
              offset: _pDob.text.length, affinity: TextAffinity.upstream),
        );
    }
  }

  tapped(int step) {
    setState(() => _currentStep = step);
  }

  continued() {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    }
  }

  cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _showAddEducationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: EdgeInsets.all(AyurezeTheme.spaceMd),
            title: Text(
                getTranslated(context, AppString.profile_education_certificate)
                    .toString()),
            content: SizedBox(
              height: height * 0.3,
              width: width! * 1.0,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        valueDegree = value;
                      });
                    },
                    controller: _degree,
                    decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_dialog_degree_hint)
                            .toString()),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        valueCollege = value;
                      });
                    },
                    controller: _college,
                    decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_dialog_education)
                            .toString()),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        valueYear = value;
                      });
                    },
                    controller: _completeYear,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                    decoration: InputDecoration(
                        hintText: getTranslated(context,
                                AppString.profile_dialog_year_of_completion)
                            .toString()),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              OutlinedButton(
                child: Text(
                    getTranslated(context, AppString.profile_dialog_ok_button)
                        .toString()),
                onPressed: () {
                  setState(() {
                    if (_degree.text.isNotEmpty &&
                        _college.text.isNotEmpty &&
                        _completeYear.text.isNotEmpty) {
                      String addDegree = "";
                      String addCollege = "";
                      String addYear = "";
                      callDegree = valueDegree;
                      callCollege = valueCollege;
                      callYear = valueYear;
                      addDegree = "${_pDegree.text},${_degree.text}";
                      addCollege = "${_pCollege.text},${_college.text}";
                      addYear = "${_pCollegeYear.text},${_completeYear.text}";

                      _pDegree.text = addDegree;
                      _pCollege.text = addCollege;
                      _pCollegeYear.text = addYear;
                      _degree.clear();
                      _college.clear();
                      _completeYear.clear();
                      Navigator.pop(context);
                    } else {
                      OslerToast.warning(
                          context,
                          getTranslated(context, AppString.please_fill_data)
                              .toString());
                    }
                  });
                },
              ),
            ],
          );
        });
  }

  void _showAddCertificateDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: EdgeInsets.all(AyurezeTheme.spaceMd),
            title: Text(
                getTranslated(context, AppString.profile_dialog_certificate)
                    .toString()),
            content: SizedBox(
              height: height * 0.2,
              width: width! * 1.0,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        certificate = value;
                      });
                    },
                    controller: _certificate,
                    decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_dialog_certificate)
                            .toString()),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        certificateYear = value;
                      });
                    },
                    controller: _year,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                    decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_dialog_year)
                            .toString()),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              OutlinedButton(
                child: Text(
                    getTranslated(context, AppString.profile_dialog_ok_button)
                        .toString()),
                onPressed: () {
                  setState(() {
                    if (_certificate.text.isNotEmpty && _year.text.isNotEmpty) {
                      String addCertificate = "";
                      String addCertificateYear = "";
                      callCertificate = certificate;
                      callCertificateYear = certificateYear;

                      addCertificate =
                          "${_pCertificate.text},${_certificate.text}";
                      addCertificateYear =
                          "${_pCertificateYear.text},${_year.text}";
                      _pCertificate.text = addCertificate;
                      _pCertificateYear.text = addCertificateYear;

                      _certificate.clear();
                      _year.clear();
                      Navigator.pop(context);
                    } else {
                      OslerToast.warning(
                          context,
                          getTranslated(context, AppString.please_fill_data)
                              .toString());
                    }
                  });
                },
              ),
            ],
          );
        });
  }

  void onBasedOnChanged(String? newValue) {
    setState(() {
      _pBasedOn.text = newValue!;
    });
  }

  void onPopularChanged(dynamic newValue) {
    setState(() {
      _selectedPopular = newValue;
    });
  }

  Future<void> onPickStartTime(BuildContext context) async {
    final TimeOfDay? result = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                // Using 12-Hour format
                alwaysUse24HourFormat: false,
              ),
              // If you want 24-Hour format, just change alwaysUse24HourFormat to true
              child: child!);
        });
    if (result != null) {
      setState(() {
        String data = result.format(context).toLowerCase();
        String str;
        List<String> parts;
        String? startPart;

        int checkData;
        str = data;
        parts = str.split(":");
        startPart = parts[0].trim();
        checkData = int.parse(startPart);
        if (checkData > 9) {
          _pStartTime.text = result.format(context).toLowerCase();
        } else {
          _pStartTime.text = "0${result.format(context).toLowerCase()}";
        }
      });
    }
  }

  Future<void> onPickEndTime(BuildContext context) async {
    final TimeOfDay? result = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  // Using 12-Hour format
                  alwaysUse24HourFormat: false),
              // If you want 24-Hour format, just change alwaysUse24HourFormat to true
              child: child!);
        });
    if (result != null) {
      setState(() {
        String data = result.format(context).toLowerCase();
        String str;
        List<String> parts;
        String? startPart;

        int checkData;
        str = data;
        parts = str.split(":");
        startPart = parts[0].trim();
        checkData = int.parse(startPart);
        if (checkData > 9) {
          _pEndTime.text = result.format(context).toLowerCase();
        } else {
          _pEndTime.text = "0${result.format(context).toLowerCase()}";
        }
      });
    }
  }
}

/// Step 1 of the profile Stepper: name, date of birth, gender and
/// description. Extracted out of [_ProfileScreen]'s build method as a
/// structural-only split - no behavior or styling changed.
///
/// The gender dropdown keeps its own local state (mirroring the
/// `StatefulBuilder` this replaced) so picking a value only rebuilds this
/// widget, not the whole step; [onGenderChanged] still writes the choice
/// back to [_ProfileScreen]'s field for validation and submission.
class _ProfileStep1PersonalInfo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final double width;
  final TextEditingController nameController;
  final TextEditingController dobController;
  final TextEditingController descriptionController;
  final String? genderValue;
  final List<String> genderOptions;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onDobTap;

  const _ProfileStep1PersonalInfo({
    required this.formKey,
    required this.width,
    required this.nameController,
    required this.dobController,
    required this.descriptionController,
    required this.genderValue,
    required this.genderOptions,
    required this.onGenderChanged,
    required this.onDobTap,
  });

  @override
  State<_ProfileStep1PersonalInfo> createState() =>
      _ProfileStep1PersonalInfoState();
}

class _ProfileStep1PersonalInfoState extends State<_ProfileStep1PersonalInfo> {
  late String? _genderSelect = widget.genderValue;

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: width * 0.01),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.profile_doctor_name)
                          .toString(),
                      style: TextStyle(
                          fontSize: width * 0.04,
                          color: AyurezeTheme.textSecondary),
                    ),
                    TextFormField(
                      controller: widget.nameController,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                      ],
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AyurezeTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_enter_name_hint)
                            .toString(),
                        hintStyle: TextStyle(
                            fontSize: width * 0.035,
                            color: AyurezeTheme.textSecondary),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return getTranslated(context,
                                  AppString.please_enter_profile_valid_name)
                              .toString();
                        } else if (value.trim().isEmpty) {
                          return getTranslated(
                                  context, AppString.please_enter_valid_name)
                              .toString();
                        }
                        return null;
                      },
                      onSaved: (String? name) {},
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: width * 0.01),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.profile_date_of_birth)
                          .toString(),
                      style: TextStyle(
                          fontSize: width * 0.04,
                          color: AyurezeTheme.textSecondary),
                    ),
                    TextFormField(
                      textCapitalization: TextCapitalization.words,
                      enableInteractiveSelection: false,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AyurezeTheme.textSecondary,
                          ),
                      controller: widget.dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_date_of_birth_hint)
                            .toString(),
                        hintStyle: TextStyle(
                          fontSize: width * 0.04,
                          color: AyurezeTheme.textSecondary,
                        ),
                      ),
                      // Optional: astra can't store this field yet.
                      onTap: widget.onDobTap,
                    ),
                  ],
                ),
              ),
              const SizedBox.shrink(),
              Divider(
                height: 4,
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: width * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.profile_gender)
                          .toString(),
                      style: TextStyle(
                          fontSize: width * 0.038,
                          color: AyurezeTheme.textSecondary),
                    ),
                    OslerDropdown(
                      label: '',
                      hint:
                          getTranslated(context, AppString.profile_gender_hint)
                              .toString(),
                      value: _genderSelect,
                      items: widget.genderOptions,
                      onChanged: (value) {
                        setState(() => _genderSelect = value);
                        widget.onGenderChanged(value);
                      },
                      // Optional: astra can't store this field yet.
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: width * 0.02),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.profile_description)
                          .toString(),
                      style: TextStyle(
                          fontSize: width * 0.04,
                          color: AyurezeTheme.textSecondary),
                    ),
                    TextFormField(
                      controller: widget.descriptionController,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp("[a-zA-Z &.,]")),
                      ],
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AyurezeTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: getTranslated(
                                context, AppString.profile_description_hint)
                            .toString(),
                        hintStyle: TextStyle(
                            fontSize: width * 0.035,
                            color: AyurezeTheme.textSecondary),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return getTranslated(
                                  context, AppString.please_enter_description)
                              .toString();
                        } else if (value.trim().isEmpty) {
                          return getTranslated(context,
                                  AppString.please_enter_valid_description)
                              .toString();
                        }
                        return null;
                      },
                      onSaved: (String? name) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2 of the profile Stepper: degree/college/year of completion, plus
/// certificates - each with an "Add More" dialog that appends a
/// comma-joined entry onto the corresponding controller's text. Extracted
/// out of [_ProfileScreen]'s build method as a structural-only split - no
/// behavior or styling changed. The two "Add" dialogs themselves stay as
/// [_ProfileScreen] methods ([onAddEducation]/[onAddCertificate]) since
/// they need that State's own setState and dialog-local controllers.
class _ProfileStep2Education extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final double width;
  final double height;
  final TextEditingController degreeController;
  final TextEditingController collegeController;
  final TextEditingController collegeYearController;
  final TextEditingController certificateController;
  final TextEditingController certificateYearController;
  final void Function(BuildContext) onAddEducation;
  final void Function(BuildContext) onAddCertificate;

  const _ProfileStep2Education({
    required this.formKey,
    required this.width,
    required this.height,
    required this.degreeController,
    required this.collegeController,
    required this.collegeYearController,
    required this.certificateController,
    required this.certificateYearController,
    required this.onAddEducation,
    required this.onAddCertificate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.01),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_degree).toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    controller: degreeController,
                    keyboardType: TextInputType.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          getTranslated(context, AppString.profile_degree_hint)
                              .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.01),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_college)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    controller: collegeController,
                    keyboardType: TextInputType.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          getTranslated(context, AppString.profile_college_hint)
                              .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.01),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_year_of_completion)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    controller: collegeYearController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          getTranslated(context, AppString.profile_year_hint)
                              .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                onAddEducation(context);
              },
              child: Container(
                margin: EdgeInsets.only(top: height * 0.01),
                height: width * 0.10,
                width: width * 0.35,
                child: Row(
                  children: [
                    Card(
                      color: AyurezeTheme.border,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AyurezeTheme.radiusPill)),
                      child: HugeIcon(
                          icon: AppIcons.add,
                          size: width * 0.06,
                          color: AyurezeTheme.actionButtonPrimary),
                    ),
                    Text(getTranslated(
                            context, AppString.profile_add_more_button)
                        .toString())
                  ],
                ),
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.03),
              child: Column(
                children: [
                  Text(
                    getTranslated(context, AppString.profile_dialog_certificate)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  )
                ],
              ),
            ),
            TextFormField(
              controller: certificateController,
              keyboardType: TextInputType.text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AyurezeTheme.textPrimary),
              decoration: InputDecoration(
                hintText: getTranslated(
                        context, AppString.profile_dialog_certificate_hint)
                    .toString(),
                hintStyle: TextStyle(
                    fontSize: width * 0.035, color: AyurezeTheme.textSecondary),
              ),
              // Optional: astra can't store this field yet.
              onSaved: (String? name) {},
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                children: [
                  Text(
                    getTranslated(
                            context, AppString.profile_dialog_certificate_year)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  )
                ],
              ),
            ),
            TextFormField(
              controller: certificateYearController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[0-9]"))
              ],
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AyurezeTheme.textPrimary),
              decoration: InputDecoration(
                hintText: getTranslated(
                        context, AppString.profile_dialog_certificate_year_hint)
                    .toString(),
                hintStyle: TextStyle(
                    fontSize: width * 0.035, color: AyurezeTheme.textSecondary),
              ),
              // Optional: astra can't store this field yet.
              onSaved: (String? name) {},
            ),
            Container(
              margin: EdgeInsets.only(top: height * 0.02),
              height: width * 0.10,
              width: width * 0.35,
              child: GestureDetector(
                onTap: () {
                  onAddCertificate(context);
                },
                child: Row(
                  children: [
                    Card(
                      color: AyurezeTheme.border,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AyurezeTheme.radiusPill)),
                      child: HugeIcon(
                          icon: AppIcons.add,
                          size: width * 0.06,
                          color: AyurezeTheme.actionButtonPrimary),
                    ),
                    Text(getTranslated(
                            context, AppString.profile_add_more_button)
                        .toString())
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 3 of the profile Stepper: experience, fees, time slot, revenue
/// model, availability hours and the "popular" flag. Extracted out of
/// [_ProfileScreen]'s build method as a structural-only split - no
/// behavior or styling changed. The revenue-model/popular dropdowns and
/// the two time pickers stay as [_ProfileScreen] methods since they call
/// that State's own setState.
class _ProfileStep3ProfessionalDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final double width;
  final TextEditingController experienceController;
  final TextEditingController videoFeeController;
  final TextEditingController audioFeeController;
  final TextEditingController timeSlotController;
  final TextEditingController basedOnController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final String? selectedPopular;
  final List<String> popularOptions;
  final ValueChanged<String?> onBasedOnChanged;
  final ValueChanged<dynamic> onPopularChanged;
  final void Function(BuildContext) onPickStartTime;
  final void Function(BuildContext) onPickEndTime;

  const _ProfileStep3ProfessionalDetails({
    required this.formKey,
    required this.width,
    required this.experienceController,
    required this.videoFeeController,
    required this.audioFeeController,
    required this.timeSlotController,
    required this.basedOnController,
    required this.startTimeController,
    required this.endTimeController,
    required this.selectedPopular,
    required this.popularOptions,
    required this.onBasedOnChanged,
    required this.onPopularChanged,
    required this.onPickStartTime,
    required this.onPickEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_experience)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    enableInteractiveSelection: false,
                    controller: experienceController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: getTranslated(
                              context, AppString.profile_experience_hint)
                          .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Video call fee",
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    enableInteractiveSelection: false,
                    controller: videoFeeController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: getTranslated(
                              context, AppString.profile_appointment_fees_hint)
                          .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    validator: (String? value) {
                      if (value!.isEmpty) {
                        return getTranslated(context,
                                AppString.please_enter_appointment_fees)
                            .toString();
                      }
                      return null;
                    },
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Audio call fee",
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    enableInteractiveSelection: false,
                    controller: audioFeeController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: getTranslated(
                              context, AppString.profile_appointment_fees_hint)
                          .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_time_slot)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    enableInteractiveSelection: false,
                    controller: timeSlotController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: getTranslated(
                              context, AppString.profile_time_slot_hint)
                          .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.revenue_model).toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue:
                        ["Commission"].contains(basedOnController.text)
                            ? basedOnController.text
                            : null,
                    hint: Text(
                        getTranslated(context, AppString.revenue_model_hint)
                            .toString()),
                    items: ["Commission"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: onBasedOnChanged,
                    // Optional: astra can't store this field yet.
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_start_time)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    enableInteractiveSelection: false,
                    controller: startTimeController,
                    readOnly: true,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: getTranslated(
                              context, AppString.profile_start_time_hint)
                          .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    onTap: () => onPickStartTime(context),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_end_time)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  TextFormField(
                    enableInteractiveSelection: false,
                    controller: endTimeController,
                    readOnly: true,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AyurezeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: getTranslated(
                              context, AppString.profile_end_time_hint)
                          .toString(),
                      hintStyle: TextStyle(
                          fontSize: width * 0.035,
                          color: AyurezeTheme.textSecondary),
                    ),
                    onTap: () => onPickEndTime(context),
                    // Optional: astra can't store this field yet.
                    onSaved: (String? name) {},
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated(context, AppString.profile_popular)
                        .toString(),
                    style: TextStyle(
                        fontSize: width * 0.038,
                        color: AyurezeTheme.textSecondary),
                  ),
                  DropdownButton(
                    hint: Text(getTranslated(context, AppString.profile_popular)
                        .toString()),
                    value: selectedPopular == '0'
                        ? getTranslated(context, AppString.popular_no)
                            .toString()
                        : getTranslated(context, AppString.popular_yes)
                            .toString(),
                    isExpanded: true,
                    iconSize: 35,
                    onChanged: onPopularChanged,
                    items: popularOptions.map((popular) {
                      return DropdownMenuItem(
                        value: popular,
                        child: Text(popular),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The profile screen's app bar: back/cancel control, avatar (with a
/// pending local pick taking priority over the saved network image) and
/// the doctor's name. Extracted out of [_ProfileScreen]'s 2000+ line build
/// method as a structural-only split - no behavior or styling changed.
class _ProfileHeader extends StatelessWidget {
  final double width;
  final File? proImage;
  final VoidCallback onBack;
  final VoidCallback onChooseImage;

  const _ProfileHeader({
    required this.width,
    required this.proImage,
    required this.onBack,
    required this.onChooseImage,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AyurezeTheme.spaceLg,
            AyurezeTheme.spaceSm, AyurezeTheme.spaceLg, 0),
        child: Container(
          decoration: AyurezeTheme.heroDecoration(),
          padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: HugeIcon(
                      icon: AppIcons.back,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AyurezeTheme.spaceSm,
                      vertical: AyurezeTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AyurezeTheme.radiusPill),
                    ),
                    child: Text(
                      "Profile workspace",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: Stack(
                      children: [
                        proImage != null
                            ? Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AyurezeTheme.healingGreen50,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AyurezeTheme.radiusPill),
                                  child: Image.file(
                                    proImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AyurezeTheme.healingGreen50,
                                    width: 2,
                                  ),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: SharedPreferenceHelper.getString(
                                      Preferences.image),
                                  imageBuilder: (context, imageProvider) =>
                                      CircleAvatar(
                                    backgroundColor: AyurezeTheme.surface,
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundImage: imageProvider,
                                    ),
                                  ),
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                    color: AyurezeTheme.healingGreen50,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset("images/no_image.png"),
                                ),
                              ),
                        Positioned(
                          top: 56,
                          left: 58,
                          child: GestureDetector(
                            onTap: onChooseImage,
                            child: CircleAvatar(
                              backgroundColor: AyurezeTheme.healingGreen50,
                              radius: 14,
                              child: HugeIcon(
                                icon: AppIcons.add,
                                color: AyurezeTheme.forestDeep,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Doctor profile",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$name",
                          style: TextStyle(
                            fontSize: width * 0.047,
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

//Pass Date Like this format  in api
class DateUtilForPass {
  static const DATE_FORMAT = 'yyyy-MM-dd';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

//Show Date like this format in User
class DateUtil {
  static const DATE_FORMAT = 'dd-MM-yyyy';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

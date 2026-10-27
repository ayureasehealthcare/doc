import 'dart:convert';

import 'package:doctro/widgets/osler_hero.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/core/constants/date_util.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/localization/language_model.dart';
import 'package:doctro/models/doctor_profile.dart';
import 'package:doctro/models/UpdateProfile.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/main.dart';
import 'package:image_picker/image_picker.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  Future? languageLoader;
  String? name;

  dynamic convertDegree;
  dynamic eduCertificate;

  final TextEditingController _pDegree = TextEditingController();
  final TextEditingController _pExperience = TextEditingController();
  final TextEditingController _pStartTime = TextEditingController();
  final TextEditingController _pEndTime = TextEditingController();
  final TextEditingController _pTimeSlot = TextEditingController();
  final TextEditingController _pAppointmentFees = TextEditingController();
  final TextEditingController _pName = TextEditingController();
  final TextEditingController _pDob = TextEditingController();
  final TextEditingController _pDesc = TextEditingController();
  final TextEditingController _pCollege = TextEditingController();
  final TextEditingController _pCollegeYear = TextEditingController();
  final TextEditingController _pCertificate = TextEditingController();
  final TextEditingController _pCertificateYear = TextEditingController();
  final TextEditingController _pBasedOn = TextEditingController();

  final picker = ImagePicker();

  List<String> popular = [];
  String? _selectedPopular;

  List<String> gender = [];
  String? _genderSelect;

  int? isFilled;
  int? treatmentId;
  int? categoryId;
  int? expertiseId;
  String? hospitalId;
  String? image;
  String? videoAppointmentFees;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gender = [
      getTranslated(context, AppString.gender_male).toString(),
      getTranslated(context, AppString.gender_female).toString(),
    ];

    popular = [
      getTranslated(context, AppString.popular_yes).toString(),
      getTranslated(context, AppString.popular_no).toString(),
    ];
  }

  @override
  void initState() {
    super.initState();
    languageLoader = doctorProfile();
    name = SharedPreferenceHelper.getString(Preferences.name);
    isFilled = SharedPreferenceHelper.getInt(Preferences.is_filled);
    image = SharedPreferenceHelper.getString(Preferences.image);
  }

  int? value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppIcons.back,
            color: AyurezeTheme.iconPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getTranslated(context, AppString.chang_language).toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AyurezeTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      body: FutureBuilder(
        future: languageLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: AyurezeTheme.iconPrimary),
            );
          }

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: SingleChildScrollView(
              padding: AyurezeTheme.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenEntrance(index: 0, child: _buildHero()),
                  const SizedBox(height: 18),
                  ...List.generate(Language.languageList().length, (index) {
                    value = Language.languageList()[index].languageCode ==
                            SharedPreferenceHelper.getString(
                                Preferences.current_language_code)
                        ? index
                        : null;
                    if (SharedPreferenceHelper.getString(
                            Preferences.current_language_code) ==
                        'N_A') {
                      value = 0;
                    }

                    return ScreenEntrance(
                      index: index % 8,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
                        child: Container(
                          decoration: AyurezeTheme.panelDecoration(),
                          child: RadioGroup<int>(
                            groupValue: value,
                            onChanged: (selected) async {
                              if (selected == null) return;
                              final language =
                                  Language.languageList()[selected];
                              final locale =
                                  await setLocale(language.languageCode);
                              await SharedPreferenceHelper.setString(
                                Preferences.language_name,
                                language.name,
                              );
                              await updateProfile();
                              // Inside build() the `context` parameter shadows State.context,
                              // so the check has to be context.mounted rather than mounted.
                              if (!context.mounted) return;
                              setState(() => value = selected);
                              MyApp.setLocale(context, locale);
                              Navigator.popAndPushNamed(context, "loginHome");
                            },
                            child: RadioListTile<int>(
                              value: index,
                              controlAffinity: ListTileControlAffinity.trailing,
                              title: Text(
                                Language.languageList()[index].name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AyurezeTheme.textPrimary,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero() {
    return const OslerHero(
      eyebrow: 'Language preferences',
      title: 'Choose how your Ayureze workspace speaks to you.',
      subtitle:
          'Pick the language that fits your workflow best. The app will switch as soon as the preference is saved.',
    );
  }

  Future<BaseModel<DoctorProfile>> doctorProfile() async {
    DoctorProfile response;

    try {
      response =
          await RestClient(await RetroApi().dioData(context)).doctorProfile();
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        if (response.data!.education != null) {
          convertDegree = json.decode(response.data!.education!);
        }

        if (response.data!.certificate != null) {
          eduCertificate = json.decode(response.data!.certificate!);
        }

        _pName.text = response.data!.name!;
        final showFormat = response.data!.dob;
        final newDateApiPass =
            DateUtil().formattedDate(DateTime.parse('$showFormat'));
        _pDob.text = newDateApiPass;

        _genderSelect = response.data!.gender!;

        if (convertDegree != null) {
          for (int i = 0; i < convertDegree.length; i++) {
            _pDegree.text = _pDegree.text.isEmpty
                ? _pDegree.text + convertDegree[i]['degree']
                : '${_pDegree.text},${convertDegree[i]['degree']}';
            _pCollege.text = _pCollege.text.isEmpty
                ? _pCollege.text + convertDegree[i]['college']
                : '${_pCollege.text},${convertDegree[i]['college']}';
            _pCollegeYear.text = _pCollegeYear.text.isEmpty
                ? _pCollegeYear.text + convertDegree[i]['year']
                : '${_pCollegeYear.text},${convertDegree[i]['year']}';
          }
        }

        if (eduCertificate != null) {
          for (int i = 0; i < eduCertificate.length; i++) {
            _pCertificate.text = _pCertificate.text.isEmpty
                ? _pCertificate.text + eduCertificate[i]['certificate']
                : '${_pCertificate.text},${eduCertificate[i]['certificate']}';

            _pCertificateYear.text = _pCertificateYear.text.isEmpty
                ? _pCertificateYear.text + eduCertificate[i]['certificate_year']
                : '${_pCertificateYear.text},${eduCertificate[i]['certificate_year']}';
          }
        }

        _pExperience.text = response.data!.experience!;
        _pAppointmentFees.text = response.data!.appointmentFees!;
        _pTimeSlot.text = response.data!.timeslot!;
        _pStartTime.text = response.data!.startTime!;
        _pEndTime.text = response.data!.endTime!;
        _pBasedOn.text = response.data!.basedOn!;
        _pDesc.text = response.data!.desc!;

        _selectedPopular = response.data!.isPopular.toString();

        treatmentId = response.data!.treatmentId!;
        categoryId = response.data!.categoryId;
        expertiseId = response.data!.expertiseId;
        hospitalId = response.data!.hospitalId;
        videoAppointmentFees = response.data!.videoAppointmentFees;
      });
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<UpdateProfile>> updateProfile() async {
    UpdateProfile response;
    Map<String, dynamic> body = {
      "name": _pName.text,
      "dob": _pDob.text,
      "gender": _genderSelect,
      "education":
          convertDegree != null ? json.encode(convertDegree) : _pDegree.text,
      "certificate":
          eduCertificate != null ? json.encode(eduCertificate) : null,
      "video_appointment_fees": videoAppointmentFees,
      "experience": _pExperience.text,
      "appointment_fees": _pAppointmentFees.text,
      "timeslot": _pTimeSlot.text,
      "start_time": _pStartTime.text,
      "end_time": _pEndTime.text,
      "based_on": _pBasedOn.text,
      "desc": _pDesc.text,
      "treatment_id": treatmentId,
      "category_id": categoryId,
      "expertise_id": expertiseId,
      "hospital_id": hospitalId,
      "is_popular": _selectedPopular,
      "language": SharedPreferenceHelper.getString(Preferences.language_name),
    };
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .updateProfile(body);
      // The screen can be disposed while the request is in flight, and a
      // toast on a dead context throws. Guarded, not returned, because the
      // caller still needs the response.
      if (mounted) {
        OslerToast.success(context, response.msg!);
      }
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}

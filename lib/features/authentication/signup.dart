import 'dart:core';
import 'package:hugeicons/hugeicons.dart';

import 'package:country_picker/country_picker.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/ayureze_date_picker.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/features/authentication/professional_registration_screen.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_input.dart';
import 'package:doctro/widgets/osler_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateAccount extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  const CreateAccount({super.key, this.prefillData});
  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  late double width;
  late double height;

  bool _isHidden = true;

  List<String> gender = ["Male", "Female"];
  String? _genderSelect;

  @override
  void initState() {
    super.initState();
    if (widget.prefillData != null) {
      _name.text = widget.prefillData!['name'] ?? "";
      _email.text = widget.prefillData!['email'] ?? "";
    }

    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      setState(() {
        gender = [
          getTranslated(context, AppString.gender_male).toString(),
          getTranslated(context, AppString.gender_female).toString(),
        ];
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _dob.dispose();
    _phone.dispose();
    _password.dispose();
    _phoneCode.dispose();
    super.dispose();
  }

  DateTime? _selectedDate;

  final _formkey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phoneCode = TextEditingController(text: "+91");

  // Sign-up has no request of its own: the button below hands these fields
  // to ProfessionalRegistrationScreen, which registers the doctor with astra
  // (POST doctors/register). The old callApiForRegister here posted to the
  // dead legacy register route and had no caller, so it was removed.

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AyurezeTheme.textPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -80,
            child: GlassBlob(size: 220, color: AyurezeTheme.healingGreen50),
          ),
          Positioned(
            bottom: 120,
            left: -90,
            child: GlassBlob(size: 220, color: AyurezeTheme.sunshineYellow50),
          ),
          GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AyurezeTheme.spaceXl, 0,
                  AyurezeTheme.spaceXl, AyurezeTheme.space2xl),
              child: Form(
                key: _formkey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AyurezeTheme.space2xl),
                      decoration: AyurezeTheme.heroDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslated(context, AppString.register_heading)
                                .toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Join the world's most advanced Ayurveda platform",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassSurface(
                      padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
                      child: Column(
                        children: [
                          OslerInput(
                            label: getTranslated(
                                    context, AppString.register_full_name)
                                .toString(),
                            hint: "Enter your full name",
                            controller: _name,
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp("[a-zA-Z ]"))
                            ],
                            textCapitalization: TextCapitalization.words,
                            prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedUserCircle02,
                                size: 20,
                                color: AyurezeTheme.iconPrimary),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context,
                                        AppString.please_enter_full_name)
                                    .toString();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          OslerInput(
                            label: getTranslated(
                                    context, AppString.register_email_hint)
                                .toString(),
                            hint: "Enter your email",
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedMailAtSign01,
                                size: 20,
                                color: AyurezeTheme.iconPrimary),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(
                                        context, AppString.please_enter_email)
                                    .toString();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: OslerInput(
                                  label: "Code",
                                  hint: "+91",
                                  controller: _phoneCode,
                                  readOnly: true,
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      showPhoneCode: true,
                                      onSelect: (Country country) => setState(
                                          () => _phoneCode.text =
                                              "+${country.phoneCode}"),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: OslerInput(
                                  label: getTranslated(
                                          context, AppString.register_phone_no)
                                      .toString(),
                                  hint: "Enter phone number",
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10)
                                  ],
                                  prefixIcon: HugeIcon(
                                      icon: HugeIcons.strokeRoundedSmartPhone01,
                                      size: 20,
                                      color: AyurezeTheme.iconPrimary),
                                  validator: (String? value) {
                                    if (value!.isEmpty) {
                                      return getTranslated(context,
                                              AppString.please_enter_phone_no)
                                          .toString();
                                    }
                                    if (value.length != 10) {
                                      return getTranslated(
                                              context,
                                              AppString
                                                  .please_enter_valid_number)
                                          .toString();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OslerInput(
                            label: getTranslated(
                                    context, AppString.register_birth_date_hint)
                                .toString(),
                            hint: "Select your DOB",
                            controller: _dob,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                size: 20,
                                color: AyurezeTheme.iconPrimary),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context,
                                        AppString.please_select_birth_date)
                                    .toString();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          OslerDropdown(
                            label: '',
                            hint: getTranslated(context,
                                    AppString.register_select_gender_hint)
                                .toString(),
                            value: _genderSelect,
                            items: gender,
                            prefixIcon: HugeIcons.strokeRoundedUserGroup,
                            onChanged: (newValue) =>
                                setState(() => _genderSelect = newValue),
                            validator: (value) => value == null
                                ? getTranslated(
                                        context, AppString.please_select_gender)
                                    .toString()
                                : null,
                          ),
                          const SizedBox(height: 14),
                          OslerInput(
                            label: getTranslated(
                                    context, AppString.register_password_hint)
                                .toString(),
                            hint: "••••••••",
                            controller: _password,
                            isPassword: _isHidden,
                            prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedSquareLock01,
                                size: 20,
                                color: AyurezeTheme.iconPrimary),
                            suffixIcon: IconButton(
                              icon: HugeIcon(
                                  icon: _isHidden
                                      ? HugeIcons.strokeRoundedViewOff
                                      : HugeIcons.strokeRoundedView,
                                  size: 20,
                                  color: AyurezeTheme.iconPrimary),
                              onPressed: () =>
                                  setState(() => _isHidden = !_isHidden),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context,
                                        AppString.please_enter_password)
                                    .toString();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          OslerButton(
                            text: getTranslated(
                                    context, AppString.register_button)
                                .toString(),
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
                                Map<String, dynamic> personalData = {
                                  "name": _name.text,
                                  "email": _email.text,
                                  "dob": _dob.text,
                                  "gender": _genderSelect,
                                  "phone": _phone.text,
                                  "password": _password.text,
                                  "phone_code": _phoneCode.text,
                                };
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfessionalRegistrationScreen(
                                            personalData: personalData),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassSurface(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AyurezeTheme.spaceXl,
                          vertical: AyurezeTheme.spaceSm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            getTranslated(context,
                                    AppString.register_all_ready_account)
                                .toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AyurezeTheme.textSecondary),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, 'SignIn'),
                            child: Text(
                              getTranslated(context, AppString.register_sign_in)
                                  .toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AyurezeTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      getTranslated(context, AppString.register_description)
                          .toString(),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AyurezeTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _selectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showAyurezeDatePicker(
      context: context,
      initialDate: _selectedDate != null
          ? _selectedDate!
          : DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950, 1),
      lastDate: DateTime.now(),
      accentColor: AyurezeTheme.actionButtonPrimary,
    );
    if (newSelectedDate != null) {
      _selectedDate = newSelectedDate;
      _dob
        ..text = DateFormat('dd-MM-yyyy').format(_selectedDate!)
        ..selection = TextSelection.fromPosition(
          TextPosition(
              offset: _dob.text.length, affinity: TextAffinity.upstream),
        );
    }
  }
}

class DateUtilForPass {
  static const DATE_FORMAT = 'yyyy-MM-dd';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

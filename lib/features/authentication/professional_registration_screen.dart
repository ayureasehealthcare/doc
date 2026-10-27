import 'dart:io';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/ayureze_date_picker.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/network_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doctro/features/authentication/registration_success_screen.dart';
import 'package:doctro/services/supabase_service.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/models/register.dart';
import 'package:intl/intl.dart';

class ProfessionalRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? personalData;

  const ProfessionalRegistrationScreen({super.key, this.personalData});

  @override
  State<ProfessionalRegistrationScreen> createState() =>
      _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState
    extends State<ProfessionalRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _feesController = TextEditingController();
  final TextEditingController _videoFeesController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  String? _genderSelect;
  String? _selectedRevenueModel;
  final List<String> _revenueModels = ["Commission"];
  final List<String> _genders = ["Male", "Female", "Other"];

  File? _certificateImage;
  String? _existingCertificateUrl;
  File? _idProofImage;
  String? _existingIdProofUrl;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String? _selectedTreatmentId = "1";
  String? _selectedCategoryId = "1";

  final SupabaseService _supabaseService = SupabaseService();
  final AstraApiService _astraApiService = AstraApiService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    _fetchTreatments();

    if (widget.personalData != null) {
      String rawDob = widget.personalData!['dob'] ?? "";
      if (rawDob.isNotEmpty) {
        try {
          if (rawDob.contains("-") && rawDob.indexOf("-") == 4) {
            DateTime d = DateFormat('yyyy-MM-dd').parse(rawDob);
            _dobController.text = DateFormat('dd-MM-yyyy').format(d);
          } else {
            _dobController.text = rawDob;
          }
        } catch (e) {
          _dobController.text = rawDob;
        }
      }
      _nameController.text = widget.personalData!['name'] ?? "";
      _emailController.text = widget.personalData!['email'] ?? "";
      _phoneController.text = widget.personalData!['phone'] ?? "";
      _genderSelect = widget.personalData!['gender'];
    }

    if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in)) {
      _fetchProfileDetails();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _licenseController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _feesController.dispose();
    _videoFeesController.dispose();
    _descController.dispose();
    _languageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileDetails() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await RestClient(await RetroApi().dioData(context)).doctorProfile();
      if (response.success == true && response.data != null) {
        if (!mounted) return;
        final data = response.data!;
        setState(() {
          _nameController.text = data.name ?? "";
          _emailController.text = data.email ?? "";
          _phoneController.text = data.phone ?? "";

          if (data.dob != null && data.dob!.contains("-")) {
            try {
              if (data.dob!.indexOf("-") == 4) {
                _dobController.text = DateFormat('dd-MM-yyyy')
                    .format(DateFormat('yyyy-MM-dd').parse(data.dob!));
              } else {
                _dobController.text = data.dob!;
              }
            } catch (e) {
              _dobController.text = data.dob!;
            }
          } else {
            _dobController.text = data.dob ?? "";
          }
          _genderSelect = data.gender;

          _licenseController.text = data.hospitalId ?? "";
          _educationController.text = data.education ?? "";
          _experienceController.text = data.experience ?? "";
          _feesController.text = data.appointmentFees ?? "";
          _videoFeesController.text = data.videoAppointmentFees ?? "";
          _descController.text = data.desc ?? "";
          _languageController.text = data.language ?? "";
          _selectedTreatmentId = data.treatmentId?.toString();
          _selectedCategoryId = data.categoryId?.toString();
          _existingCertificateUrl = data.certificate;
        });

        if (_selectedTreatmentId != null) {
          _fetchCategories(_selectedTreatmentId!);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTreatments() async {}
  Future<void> _fetchCategories(String id) async {}

  Future<void> _pickImage(bool isCertificate) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      setState(() {
        if (isCertificate) {
          _certificateImage = File(image.path);
          _existingCertificateUrl = null;
        } else {
          _idProofImage = File(image.path);
          _existingIdProofUrl = null;
        }
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() ||
        _licenseController.text.isEmpty ||
        _videoFeesController.text.isEmpty) {
      OslerToast.warning(context, "Please fill all required fields");
      return;
    }

    if ((_certificateImage == null && _existingCertificateUrl == null) ||
        (_idProofImage == null && _existingIdProofUrl == null)) {
      OslerToast.warning(
          context, "Both Medical Certificate and ID Proof are required");
      return;
    }

    Map<String, dynamic> combinedData =
        widget.personalData != null ? Map.from(widget.personalData!) : {};

    final int safeTreatmentId = int.tryParse(_selectedTreatmentId ?? "") ?? 1;
    final int safeCategoryId = int.tryParse(_selectedCategoryId ?? "") ?? 1;
    final String safeLanguage = _languageController.text.trim().isEmpty
        ? "English"
        : _languageController.text.trim();

    combinedData.addAll({
      "name": _nameController.text,
      "email": _emailController.text,
      "phone": _phoneController.text,
      "dob": _dobController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd-MM-yyyy').parse(_dobController.text))
          : "",
      "gender": _genderSelect,
      "treatment_id": safeTreatmentId,
      "category_id": safeCategoryId,
      "treatment": safeTreatmentId.toString(),
      "category": safeCategoryId.toString(),
      "education": _educationController.text,
      "experience": _experienceController.text,
      "appointment_fees": _feesController.text,
      "clinic_fee": _feesController.text,
      "video_appointment_fees": _videoFeesController.text,
      "video_fee": _videoFeesController.text,
      "hospital_id": "1",
      "license_number": _licenseController.text,
      "based_on": _selectedRevenueModel ?? "",
      "language": safeLanguage,
      "desc": _descController.text,
      "certificate": _existingCertificateUrl ?? "",
      "id_proof": _existingIdProofUrl ?? "",
    });

    if (_certificateImage != null) {
      combinedData["certificate_path"] = _certificateImage!.path;
    }
    if (_idProofImage != null) {
      combinedData["id_proof_path"] = _idProofImage!.path;
    }

    if (widget.personalData != null) {
      _finalizeRegistration(combinedData);
    } else {
      _updateProfile(combinedData);
    }
  }

  Future<void> _finalizeRegistration(Map<String, dynamic> combinedData) async {
    setState(() => _isLoading = true);
    try {
      String uniqueId = _supabaseService.generateDoctorID();

      String? certUrl;
      String? idUrl;

      if (combinedData['certificate_path'] != null) {
        certUrl = await _supabaseService.uploadProfilePhoto(
            File(combinedData['certificate_path']), "${uniqueId}_cert");
      }
      if (combinedData['id_proof_path'] != null) {
        idUrl = await _supabaseService.uploadProfilePhoto(
            File(combinedData['id_proof_path']), "${uniqueId}_idproof");
      }

      Map<String, dynamic> finalData = Map.from(combinedData);
      finalData.addAll({
        "unique_id": uniqueId,
        "is_face_verified": 1,
        "certificate": certUrl ?? "",
        "id_proof": idUrl ?? "",
        "is_filled": 1,
      });

      if (!mounted) return;
      final response = await RestClient(await RetroApi().dioData(context))
          .registerRequest(finalData);

      if (!mounted) return;

      if (response.success == true) {
        try {
          await _supabaseService.saveDoctorProfile(
            doctorId: uniqueId,
            name: combinedData['name'] ?? '',
            email: combinedData['email'] ?? '',
            phone: combinedData['phone'] ?? '',
            gender: combinedData['gender'] ?? '',
            dob: combinedData['dob'] ?? '',
            photoUrl: "",
            isFaceVerified: true,
          );
        } catch (_) {
          // Supabase mirror is best-effort; the API registration already succeeded.
        }

        try {
          await _astraApiService.registerDoctor({
            "unique_id": uniqueId,
            "name": combinedData['name'] ?? '',
            "email": combinedData['email'] ?? '',
            "phone": combinedData['phone'] ?? '',
            "gender": combinedData['gender'] ?? '',
            "dob": combinedData['dob'] ?? '',
            "education": combinedData['education'] ?? '',
            "experience": combinedData['experience'] ?? '',
            "language": combinedData['language'] ?? '',
            "desc": combinedData['desc'] ?? '',
            "appointment_fees": combinedData['appointment_fees'] ?? '',
            "video_appointment_fees":
                combinedData['video_appointment_fees'] ?? '',
            "license_number": combinedData['license_number'] ?? '',
            "certificate": finalData['certificate'] ?? '',
            "id_proof": finalData['id_proof'] ?? '',
          });
        } catch (_) {
          // Astra directory sync is best-effort; the primary registration
          // already succeeded and must not be blocked by it.
        }

        if (!mounted) return;
        _savePreferences(response);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationSuccessScreen(
              doctorName: combinedData['name'] ?? '',
              doctorId: response.data?.uniqueId ?? uniqueId,
              email: combinedData['email'] ?? '',
            ),
          ),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        OslerToast.error(context, response.msg ?? "Registration failed");
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        String errorMsg = "Registration failed";
        if (e.response?.data is Map) {
          errorMsg = e.response?.data['msg'] ??
              e.response?.data['message'] ??
              errorMsg;
        }
        OslerToast.error(context, errorMsg);
      } else {
        OslerToast.error(context, "An unexpected error occurred: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _savePreferences(Register response) {
    if (response.data == null) return;
    final data = response.data!;

    SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
    SharedPreferenceHelper.setString(
        Preferences.auth_token, response.token ?? "");
    SharedPreferenceHelper.setString(
        Preferences.refresh_token, response.refreshToken ?? "");
    SharedPreferenceHelper.setString(Preferences.name, data.name ?? "");
    SharedPreferenceHelper.setString(Preferences.email, data.email ?? "");
    SharedPreferenceHelper.setString(Preferences.phone_no, data.phone ?? "");
    SharedPreferenceHelper.setString(Preferences.gender, data.gender ?? "");
    SharedPreferenceHelper.setString(Preferences.dob, data.dob ?? "");
    SharedPreferenceHelper.setString(Preferences.uniqueId, data.uniqueId ?? "");
    SharedPreferenceHelper.setString(Preferences.image, data.image ?? "");
    SharedPreferenceHelper.setString(
        Preferences.doctorId, data.id?.toString() ?? "");
  }

  Future<void> _updateProfile(Map<String, dynamic> profileData) async {
    setState(() => _isLoading = true);
    try {
      String doctorId = SharedPreferenceHelper.getString(Preferences.uniqueId);
      if (doctorId == 'N_A' || doctorId.isEmpty) {
        doctorId = SharedPreferenceHelper.getString(Preferences.doctorId);
      }
      if (doctorId == 'N_A' || doctorId.isEmpty) {
        doctorId = _supabaseService.generateDoctorID();
      }

      String? certUrl = _existingCertificateUrl;
      String? idProofUrl = _existingIdProofUrl;

      if (_certificateImage != null) {
        certUrl = await _supabaseService.uploadProfilePhoto(
            _certificateImage!, "${doctorId}_cert");
      }
      if (_idProofImage != null) {
        idProofUrl = await _supabaseService.uploadProfilePhoto(
            _idProofImage!, "${doctorId}_idproof");
      }

      Map<String, dynamic> body = Map.from(profileData);
      body["certificate"] = certUrl ?? "";
      body["id_proof"] = idProofUrl ?? "";
      body["is_filled"] = 1;

      // The legacy REST API (Apis.baseUrl) is permanently dead - confirmed
      // 404 on every route, including this one. Astra and Supabase are the
      // real, live backends, so they must not be gated behind the legacy
      // call succeeding; it is attempted only for whatever installs still
      // depend on it, and never blocks a real profile update.
      bool astraSynced = false;
      try {
        await _astraApiService.registerDoctor({
          "unique_id": doctorId,
          "name": body['name'] ?? '',
          "email": body['email'] ?? '',
          "phone": body['phone'] ?? '',
          "gender": body['gender'] ?? '',
          "dob": body['dob'] ?? '',
          "education": body['education'] ?? '',
          "experience": body['experience'] ?? '',
          "language": body['language'] ?? '',
          "desc": body['desc'] ?? '',
          "appointment_fees": body['appointment_fees'] ?? '',
          "video_appointment_fees": body['video_appointment_fees'] ?? '',
          "license_number": body['license_number'] ?? '',
          "certificate": body['certificate'] ?? '',
          "id_proof": body['id_proof'] ?? '',
        });
        astraSynced = true;
      } catch (_) {
        // Reported to the user below via legacySynced/astraSynced check.
      }

      try {
        await _supabaseService.saveDoctorProfile(
          doctorId: doctorId,
          name: body['name'] ?? '',
          email: body['email'] ?? '',
          phone: body['phone'] ?? '',
          gender: body['gender'] ?? '',
          dob: body['dob'] ?? '',
          photoUrl: "",
          isFaceVerified: true,
        );
      } catch (_) {
        // Supabase mirror is best-effort and must not block a real update.
      }

      if (!mounted) return;
      bool legacySynced = false;
      try {
        final response = await RestClient(await RetroApi().dioData(context))
            .updateProfile(body);
        legacySynced = response.success == true;
      } catch (_) {
        // Legacy endpoint is dead; astraSynced is the real signal below.
      }

      if (!mounted) return;
      if (astraSynced || legacySynced) {
        SharedPreferenceHelper.setString(Preferences.uniqueId, doctorId);
        OslerToast.success(context, "Clinical Profile Updated");
        Navigator.pop(context);
      } else {
        OslerToast.error(context, "Update failed");
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        String errorMsg = "Profile update failed";
        if (e.response?.data is Map) {
          errorMsg = e.response?.data['msg'] ??
              e.response?.data['message'] ??
              errorMsg;
        }
        OslerToast.error(context, errorMsg);
      } else {
        OslerToast.error(context, "An error occurred: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        title: Text("Clinical Profile",
            style: textTheme.titleLarge?.copyWith(
                color: AyurezeTheme.textPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: AyurezeTheme.surface,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: AyurezeTheme.textPrimary,
                size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AyurezeTheme.iconPrimary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AyurezeTheme.spaceXl, vertical: 25),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                  "Personal Information", AppIcons.person),
                              const SizedBox(height: 15),
                              widget.personalData != null
                                  ? _buildPersonalSummaryCard()
                                  : Column(
                                      children: [
                                        _buildTextField("Full Name",
                                            _nameController, AppIcons.badge),
                                        _buildTextField("Email Address",
                                            _emailController, AppIcons.email),
                                        _buildTextField("Phone Number",
                                            _phoneController, AppIcons.phone,
                                            isNumber: true),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildLabel("Gender"),
                                                  _buildGenericDropdown(
                                                      _genders,
                                                      (val) => setState(() =>
                                                          _genderSelect = val),
                                                      _genderSelect),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                                child: _buildTextField(
                                                    "Date of Birth",
                                                    _dobController,
                                                    AppIcons.cake,
                                                    isReadOnly: true,
                                                    onTap: () =>
                                                        _selectDate(context))),
                                          ],
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 35),
                              _buildSectionHeader(
                                  "Professional Credentials", AppIcons.badge),
                              const SizedBox(height: 15),
                              _buildTextField(
                                  "Medical Registration / License Number",
                                  _licenseController,
                                  AppIcons.verifiedUser),
                              _buildTextField(
                                  "Medical Education (e.g. BAMS, MD)",
                                  _educationController,
                                  AppIcons.school),
                              _buildTextField("Years of Experience",
                                  _experienceController, AppIcons.history,
                                  isNumber: true),
                              const SizedBox(height: 35),
                              _buildSectionHeader(
                                  "Consultation Rates", AppIcons.wallet),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildTextField(
                                          "Audio call fee (₹)",
                                          _feesController,
                                          AppIcons.phone,
                                          isNumber: true)),
                                  const SizedBox(width: 15),
                                  Expanded(
                                      child: _buildTextField(
                                          "Video call fee (₹)",
                                          _videoFeesController,
                                          AppIcons.videoCall,
                                          isNumber: true)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildLabel("Revenue Model"),
                              _buildGenericDropdown(
                                  _revenueModels,
                                  (val) => setState(
                                      () => _selectedRevenueModel = val),
                                  _selectedRevenueModel),
                              const SizedBox(height: 35),
                              _buildSectionHeader(
                                  "Practice Details", AppIcons.description),
                              const SizedBox(height: 15),
                              _buildTextField(
                                  "Languages Spoken (e.g. English, Hindi)",
                                  _languageController,
                                  AppIcons.language),
                              _buildTextField("Professional Bio / Description",
                                  _descController, AppIcons.description,
                                  maxLines: 3),
                              const SizedBox(height: 35),
                              _buildSectionHeader("Verification Documents",
                                  AppIcons.cloudUpload),
                              const SizedBox(height: 15),
                              _buildLabel("Medical Degree / Certificate"),
                              _buildUploadBox(
                                onTap: () => _pickImage(true),
                                file: _certificateImage,
                                url: _existingCertificateUrl,
                                placeholder: "Upload Medical Certificate",
                              ),
                              const SizedBox(height: 25),
                              _buildLabel(
                                  "Identification Proof (Aadhar / PAN / DL)"),
                              _buildUploadBox(
                                onTap: () => _pickImage(false),
                                file: _idProofImage,
                                url: _existingIdProofUrl,
                                placeholder: "Upload ID Proof",
                              ),
                              const SizedBox(height: 45),
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: OslerButton(
                                  text: widget.personalData != null
                                      ? "Complete Registration"
                                      : "Save Profile Details",
                                  onPressed: _submitData,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUploadBox(
      {required VoidCallback onTap,
      File? file,
      String? url,
      required String placeholder}) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AyurezeTheme.surface,
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          border: Border.all(
              color: AyurezeTheme.healingGreen50.withValues(alpha: 0.35),
              width: 2),
          boxShadow: [
            BoxShadow(
                color: AyurezeTheme.shadow.withValues(alpha: 0.08),
                blurRadius: 10,
                spreadRadius: 0)
          ],
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
                child: Image.file(file, fit: BoxFit.cover),
              )
            : url != null && url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
                    child: Image.network(url, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                          icon: HugeIcons.strokeRoundedCameraAdd01,
                          size: 40,
                          color: AyurezeTheme.healingGreen50
                              .withValues(alpha: 0.65)),
                      const SizedBox(height: 10),
                      Text(placeholder,
                          style: textTheme.labelLarge?.copyWith(
                              color: AyurezeTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("Tap to select image/PDF",
                          style: textTheme.bodySmall
                              ?.copyWith(color: AyurezeTheme.textSecondary)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, List<List<dynamic>> icon) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        HugeIcon(icon: icon, color: AyurezeTheme.iconPrimary, size: 22),
        const SizedBox(width: 10),
        Text(title,
            style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: AyurezeTheme.textPrimary)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
          bottom: AyurezeTheme.spaceSm, left: AyurezeTheme.spaceXs),
      child: Text(label,
          style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700, color: AyurezeTheme.textSecondary)),
    );
  }

  Widget _buildGenericDropdown(
      List<String> items, Function(String?) onChanged, String? value) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: AyurezeTheme.spaceXs),
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceXl),
      decoration: BoxDecoration(
        color: AyurezeTheme.surface,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
        border: Border.all(color: AyurezeTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: AyurezeTheme.shadow.withValues(alpha: 0.06),
              blurRadius: 5,
              spreadRadius: 0)
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: AyurezeTheme.textSecondary),
          hint: Text("Select",
              style: textTheme.bodyMedium
                  ?.copyWith(color: AyurezeTheme.textSecondary)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item,
                  style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AyurezeTheme.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, List<List<dynamic>> icon,
      {bool isNumber = false,
      int maxLines = 1,
      bool isReadOnly = false,
      VoidCallback? onTap}) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: isReadOnly,
            onTap: onTap,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, color: AyurezeTheme.textPrimary),
            decoration: InputDecoration(
              prefixIcon: HugeIcon(
                  icon: icon, color: AyurezeTheme.textSecondary, size: 20),
              filled: true,
              fillColor: AyurezeTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 18, horizontal: AyurezeTheme.spaceXl),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
                  borderSide: BorderSide(
                      color: AyurezeTheme.border.withValues(alpha: 0.6))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
                  borderSide:
                      BorderSide(color: AyurezeTheme.iconPrimary, width: 1.5)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
                  borderSide: BorderSide(color: AyurezeTheme.remoteRed50)),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showAyurezeDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateFormat('dd-MM-yyyy').parse(_dobController.text)
          : DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      accentColor: AyurezeTheme.healingGreen100,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Widget _buildPersonalSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      decoration: BoxDecoration(
        // Dark-aware: healingGreen10 is a light-only constant, so it left a
        // pale card behind dark-mode text.
        color: AyurezeTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
        border: Border.all(
            color: AyurezeTheme.healingGreen50.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(AppIcons.person, "Name", _nameController.text),
          const Divider(height: 20),
          _buildSummaryRow(AppIcons.email, "Email", _emailController.text),
          const Divider(height: 20),
          _buildSummaryRow(AppIcons.cake, "DOB", _dobController.text),
          const Divider(height: 20),
          _buildSummaryRow(
              AppIcons.gender, "Gender", _genderSelect ?? "Not selected"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      List<List<dynamic>> icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        HugeIcon(icon: icon, size: 18, color: AyurezeTheme.iconPrimary),
        const SizedBox(width: 12),
        Text("$label: ",
            style: textTheme.bodySmall
                ?.copyWith(color: AyurezeTheme.textSecondary)),
        Text(value,
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold, color: AyurezeTheme.textPrimary)),
      ],
    );
  }
}

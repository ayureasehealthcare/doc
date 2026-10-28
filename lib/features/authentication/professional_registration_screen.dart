import 'dart:io';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/ayureze_date_picker.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doctro/features/authentication/registration_success_screen.dart';
import 'package:doctro/services/supabase_service.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/models/astra_doctor_mapper.dart';
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

  final String _selectedTreatmentId = "1";
  final String _selectedCategoryId = "1";

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

  /// Values of the fields astra can't store, as loaded. [_submitData] diffs
  /// against these to tell the doctor which edits were not saved.
  Map<String, String> _unsupportedAtLoad = const {};

  /// The fields of this form that neither astra's register nor its update
  /// route stores (see AstraDoctorMapper), keyed by the label shown to the
  /// doctor. [forUpdate] adds the ones only registration accepts.
  Map<String, String> _unsupportedFields({required bool forUpdate}) => {
        "Licence number": _licenseController.text,
        "Clinic fee": _feesController.text,
        "Revenue model": _selectedRevenueModel ?? "",
        "Medical certificate": _certificateImage?.path ?? "",
        "ID proof": _idProofImage?.path ?? "",
        if (forUpdate) "Email": _emailController.text,
        if (forUpdate) "Education": _educationController.text,
        if (forUpdate) "Experience": _experienceController.text,
        if (forUpdate) "Languages": _languageController.text,
      };

  /// [raw] matched case-insensitively to one of [options] (the dropdowns
  /// assert their value is an item), or [fallback].
  static String? _matchOption(
      List<String> options, String? raw, String? fallback) {
    if (raw == null) return fallback;
    for (final option in options) {
      if (option.toLowerCase() == raw.trim().toLowerCase()) return option;
    }
    return fallback;
  }

  Future<void> _fetchProfileDetails() async {
    final doctorId =
        SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    if (doctorId == null) {
      // Called from initState: wait for a frame before showing a toast.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        OslerToast.error(context,
            "We couldn't find your doctor ID. Please sign in again to load your profile.");
      });
      _unsupportedAtLoad = _unsupportedFields(forUpdate: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // GET doctors/{id}; the response shape is unconfirmed, see
      // AstraDoctor.fromResponse.
      final doctor = AstraDoctor.fromResponse(
          await _astraApiService.getDoctorProfile(doctorId));
      if (!mounted) return;
      setState(() {
        _nameController.text = doctor.name ?? _nameController.text;
        _emailController.text = doctor.email ?? _emailController.text;
        _phoneController.text = doctor.phone ?? _phoneController.text;

        final dob = doctor.dob;
        if (dob != null && dob.contains("-")) {
          try {
            if (dob.indexOf("-") == 4) {
              _dobController.text = DateFormat('dd-MM-yyyy')
                  .format(DateFormat('yyyy-MM-dd').parse(dob));
            } else {
              _dobController.text = dob;
            }
          } catch (e) {
            _dobController.text = dob;
          }
        } else if (dob != null) {
          _dobController.text = dob;
        }
        _genderSelect = _matchOption(_genders, doctor.gender, _genderSelect);

        if (doctor.qualifications.isNotEmpty) {
          _educationController.text = doctor.qualifications.join(', ');
        }
        if (doctor.experienceYears != null) {
          _experienceController.text = doctor.experienceText;
        }
        // astra has one consultation_fee; this app's consultations are video
        // calls, so it fills the video fee. The clinic fee has no field.
        if (doctor.consultationFee != null) {
          _videoFeesController.text = doctor.feeText;
        }
        _descController.text = doctor.bio ?? _descController.text;
        if (doctor.languages.isNotEmpty) {
          _languageController.text = doctor.languages.join(', ');
        }
        _existingCertificateUrl =
            doctor.certificateUrl ?? _existingCertificateUrl;
      });
    } on AstraApiException catch (e) {
      if (mounted) OslerToast.error(context, e.message);
    } catch (e) {
      if (mounted) {
        OslerToast.error(
            context, "Couldn't load your profile. Please try again.");
      }
    } finally {
      _unsupportedAtLoad = _unsupportedFields(forUpdate: true);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTreatments() async {}

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

    final int safeTreatmentId = int.tryParse(_selectedTreatmentId) ?? 1;
    final int safeCategoryId = int.tryParse(_selectedCategoryId) ?? 1;
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

      if (combinedData['certificate_path'] != null) {
        await _supabaseService.uploadProfilePhoto(
            File(combinedData['certificate_path']), "${uniqueId}_cert");
      }
      if (combinedData['id_proof_path'] != null) {
        await _supabaseService.uploadProfilePhoto(
            File(combinedData['id_proof_path']), "${uniqueId}_idproof");
      }

      // POST doctors/register (RegisterDoctorRequest). This used to post to
      // the legacy register route, which 404s, and only then try astra
      // best-effort with keys astra doesn't read. Fields with no place in
      // RegisterDoctorRequest are listed to the doctor below.
      final response = await _astraApiService.registerDoctor(
        AstraDoctorMapper.registerBody(
          name: combinedData['name'] ?? '',
          email: combinedData['email'],
          // Sign-up keeps the dialling code separately ("+91").
          phone: AstraDoctorMapper.withDialCode(
              combinedData['phone_code'], combinedData['phone']),
          qualifications: combinedData['education'],
          experience: combinedData['experience'],
          fee: combinedData['video_appointment_fees'],
          languages: combinedData['language'],
          bio: combinedData['desc'],
        ),
      );

      // Gender and date of birth are kept in the Supabase mirror only.
      bool mirrored = false;
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
        mirrored = true;
      } catch (_) {
        // Supabase mirror is best-effort; the astra registration succeeded.
      }

      if (!mounted) return;
      final loggedIn = _savePreferences(response, combinedData, uniqueId);
      final unsaved = [
        for (final e in _unsupportedFields(forUpdate: false).entries)
          if (e.value.trim().isNotEmpty) e.key,
        if (!mirrored) ...["Gender", "Date of birth"],
      ];
      if (unsaved.isNotEmpty) {
        OslerToast.info(context, AstraDoctorMapper.unsavedMessage(unsaved));
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationSuccessScreen(
            doctorName: combinedData['name'] ?? '',
            doctorId: AstraDoctorMapper.doctorIdFrom(response) ?? uniqueId,
            email: combinedData['email'] ?? '',
            // Without a session token from astra the doctor isn't signed in
            // yet, so continue to sign-in rather than the dashboard.
            onContinue: loggedIn
                ? null
                : () => Navigator.pushNamedAndRemoveUntil(
                    context, 'SignIn', (route) => false),
          ),
        ),
        (route) => false,
      );
    } on AstraApiException catch (e) {
      if (!mounted) return;
      OslerToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      OslerToast.error(context, "Registration failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Stores the new doctor's details after astra registration. Returns
  /// whether the doctor is now signed in, which needs a session token in
  /// [response] - astra documents none (see AstraDoctorMapper).
  bool _savePreferences(Map<String, dynamic> response,
      Map<String, dynamic> combinedData, String uniqueId) {
    SharedPreferenceHelper.setString(
        Preferences.name, combinedData['name'] ?? "");
    SharedPreferenceHelper.setString(
        Preferences.email, combinedData['email'] ?? "");
    SharedPreferenceHelper.setString(
        Preferences.phone_no, combinedData['phone'] ?? "");
    SharedPreferenceHelper.setString(
        Preferences.gender, combinedData['gender'] ?? "");
    SharedPreferenceHelper.setString(
        Preferences.dob, combinedData['dob'] ?? "");
    SharedPreferenceHelper.setString(Preferences.uniqueId, uniqueId);
    final doctorId = AstraDoctorMapper.doctorIdFrom(response);
    if (doctorId != null) {
      SharedPreferenceHelper.setString(Preferences.doctorId, doctorId);
    }

    final token = AstraDoctorMapper.sessionTokenFrom(response);
    if (token == null) return false;
    SharedPreferenceHelper.setString(Preferences.auth_token, token);
    SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
    return true;
  }

  Future<void> _updateProfile(Map<String, dynamic> profileData) async {
    final doctorId =
        SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    if (doctorId == null) {
      OslerToast.error(context,
          "We couldn't find your doctor ID. Please sign in again, then save your profile.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Re-uploaded documents still go to Supabase storage under the
      // doctor's id, as before; astra's record has no field linking them.
      if (_certificateImage != null) {
        await _supabaseService.uploadProfilePhoto(
            _certificateImage!, "${doctorId}_cert");
      }
      if (_idProofImage != null) {
        await _supabaseService.uploadProfilePhoto(
            _idProofImage!, "${doctorId}_idproof");
      }

      // PUT doctors/{id} (UpdateDoctorRequest) with the fields it accepts.
      // This used to call astra's *register* (creating a new doctor on every
      // save) alongside the dead legacy update route.
      await _astraApiService.updateDoctorProfile(
        doctorId,
        AstraDoctorMapper.updateBody(
          name: profileData['name'],
          phone: profileData['phone'],
          fee: profileData['video_appointment_fees'],
          bio: profileData['desc'],
        ),
      );

      // Gender and date of birth are kept in the Supabase mirror only.
      bool mirrored = false;
      try {
        await _supabaseService.saveDoctorProfile(
          doctorId: doctorId,
          name: profileData['name'] ?? '',
          email: profileData['email'] ?? '',
          phone: profileData['phone'] ?? '',
          gender: profileData['gender'] ?? '',
          dob: profileData['dob'] ?? '',
          photoUrl: "",
          isFaceVerified: true,
        );
        mirrored = true;
      } catch (_) {
        // Supabase mirror is best-effort and must not block a real update.
      }

      if (!mounted) return;
      final unsaved = AstraDoctorMapper.changedFields(
          _unsupportedAtLoad, _unsupportedFields(forUpdate: true));
      if (!mirrored) unsaved.addAll(["Gender", "Date of birth"]);
      if (unsaved.isEmpty) {
        OslerToast.success(context, "Clinical Profile Updated");
      } else {
        OslerToast.info(context, AstraDoctorMapper.unsavedMessage(unsaved));
      }
      Navigator.pop(context);
    } on AstraApiException catch (e) {
      if (!mounted) return;
      OslerToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      OslerToast.error(context, "Profile update failed. Please try again.");
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

import 'package:doctro/core/constants/app_string.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/models/resent_otp.dart';
import 'package:doctro/models/otp_verify.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:flutter/material.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:doctro/features/consultation/chat/providers/auth_provider.dart';
import 'package:doctro/features/authentication/professional_registration_screen.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/core/constants/preferences.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final OtpData? data;

  const PhoneVerificationScreen({super.key, this.data});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen>
    with SingleTickerProviderStateMixin {
  int? id = 0;

  final TextEditingController _pinPutController = TextEditingController();
  final FocusNode _pinPutFocusNode = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    id = widget.data?.id ?? 0;
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
  }

  @override
  void dispose() {
    _pinPutController.dispose();
    _pinPutFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AyurezeTheme.iconPrimary,
              size: 20),
          onPressed: () => Navigator.pushNamed(context, 'SignIn'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.space2xl,
              vertical: AyurezeTheme.spaceLg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
                        decoration: BoxDecoration(
                          // Dark-aware: the pale-mint constant made the
                          // forestDeep icon 2.36:1 in dark mode.
                          color: AyurezeTheme.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMailOpen01,
                          size: 48,
                          color: AyurezeTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        getTranslated(context, AppString.otp_verification_title)
                            .toString(),
                        style: textTheme.headlineMedium?.copyWith(
                          color: AyurezeTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getTranslated(
                                context, AppString.phone_enter_your_otp_code)
                            .toString(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AyurezeTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Pinput(
                        length: 4,
                        autofocus: true,
                        focusNode: _pinPutFocusNode,
                        controller: _pinPutController,
                        submittedPinTheme: PinTheme(
                          width: 56,
                          height: 60,
                          textStyle: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AyurezeTheme.radiusMd),
                            color: AyurezeTheme.forestDeep,
                            border: Border.all(
                              color: AyurezeTheme.healingGreen50
                                  .withValues(alpha: .3),
                            ),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 56,
                          height: 60,
                          textStyle: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AyurezeTheme.textPrimary,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AyurezeTheme.radiusMd),
                            color: AyurezeTheme.surface,
                            border: Border.all(
                              color: AyurezeTheme.iconPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        followingPinTheme: PinTheme(
                          width: 56,
                          height: 60,
                          textStyle: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AyurezeTheme.textPrimary,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AyurezeTheme.radiusMd),
                            color: AyurezeTheme.surface,
                            border: Border.all(
                              color: AyurezeTheme.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        getTranslated(context, AppString.phone_otp_not_received)
                            .toString(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AyurezeTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => resentOtpVerify(),
                        child: Text(
                          getTranslated(
                                  context, AppString.phone_resend_new_code)
                              .toString(),
                          style: textTheme.titleSmall?.copyWith(
                            color: AyurezeTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      OslerButton(
                        text: getTranslated(context, AppString.phone_verify_otp)
                            .toString(),
                        onPressed: () => otpVerify(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<OtpVerify>> otpVerify() async {
    Map<String, dynamic> body = {
      "user_id": id,
      "otp": _pinPutController.text,
    };
    OtpVerify response;
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .otpVerifyRequest(body);
      if (!mounted) return BaseModel()..data = response;
      if (response.success == true) {
        _saveUserData(response);

        if (response.data?.isFilled == 0) {
          // New doctor or incomplete profile: Go to Professional Registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfessionalRegistrationScreen(
                personalData: {
                  'name': response.data?.name,
                  'email': response.data?.email,
                  'phone': response.data?.phone,
                  'gender': response.data?.gender,
                  'dob': response.data?.dob,
                },
              ),
            ),
          );
        } else {
          // Complete profile: Go to Dashboard
          Navigator.pushReplacementNamed(context, "loginHome");
        }

        OslerToast.success(context, response.msg!);
      } else {
        OslerToast.error(context, response.msg!);
      }
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<ResentOtp>> resentOtpVerify() async {
    ResentOtp response;
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .resentOtpRequest(id);

      if (!mounted) return BaseModel()..data = response;
      Navigator.pushNamed(context, 'SignIn');
      OslerToast.success(context, response.msg!);
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  void _saveUserData(OtpVerify response) {
    if (response.data == null) return;

    final data = response.data!;
    SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
    SharedPreferenceHelper.setString(Preferences.name, data.name ?? "");
    SharedPreferenceHelper.setString(Preferences.phone_no, data.phone ?? "");
    SharedPreferenceHelper.setString(Preferences.email, data.email ?? "");
    SharedPreferenceHelper.setString(Preferences.image, data.image ?? "");
    SharedPreferenceHelper.setString(
        Preferences.doctorId, data.id?.toString() ?? "");
    SharedPreferenceHelper.setInt(Preferences.is_filled, data.isFilled ?? 0);

    if (data.token != null && data.token!.isNotEmpty) {
      SharedPreferenceHelper.setString(Preferences.auth_token, data.token!);
    }

    // Notify auth provider for chat
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.handleSignIn();
    } catch (_) {
      // Sign-in state sync is best-effort; navigator already moved on.
    }
  }
}

import 'dart:ui' show ImageFilter;
import 'package:country_picker/country_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:core';

import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/swastu.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:doctro/features/authentication/view_models/signin_view_model.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignInViewModel(),
      child: const SignInView(),
    );
  }
}

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  _SignInViewState createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Consumer<SignInViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                // Soft gradient blobs for the glass panels below to refract -
                // a frosted BackdropFilter blurs whatever is painted behind
                // it, so a flat background would make "glass" invisible.
                Positioned(
                  top: -70,
                  left: -60,
                  child: _glassBlob(220, AyurezeTheme.healingGreen50),
                ),
                Positioned(
                  top: 280,
                  right: -90,
                  child: _glassBlob(260, AyurezeTheme.sunshineYellow50),
                ),
                Positioned(
                  bottom: -90,
                  left: 30,
                  child: _glassBlob(240, AyurezeTheme.healingGreen100),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AyurezeTheme.spaceXl,
                        vertical: AyurezeTheme.spaceLg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Form(
                              key: viewModel.formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                        AyurezeTheme.space2xl),
                                    decoration: AyurezeTheme.heroDecoration(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                                AyurezeTheme.radiusPill),
                                          ),
                                          child: Text(
                                            "Doctor workspace",
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    getTranslated(
                                                            context,
                                                            AppString
                                                                .login_heading)
                                                        .toString(),
                                                    style: textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    "Run your practice with a calmer Ayureze-style workflow for visits, patients, and follow-up.",
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                      height: 1.4,
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.85),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Swastu welcomes the doctor, as
                                            // on the patient app's sign-in.
                                            const Swastu(
                                              mood: SwastuMood.greeting,
                                              size: 104,
                                              named: false,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AyurezeTheme.radius2xl),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 20, sigmaY: 20),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                            AyurezeTheme.spaceXl, 22, 20, 20),
                                        decoration:
                                            AyurezeTheme.glassDecoration(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => viewModel
                                                        .toggleOtpLoginMode(
                                                            false),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: !viewModel.isOtpLoginMode
                                                                ? AyurezeTheme
                                                                    .forestDeep
                                                                : Colors
                                                                    .transparent,
                                                            width: 2,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Email Login",
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: !viewModel.isOtpLoginMode
                                                                ? AyurezeTheme
                                                                    .forestDeep
                                                                : AyurezeTheme
                                                                    .textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => viewModel
                                                        .toggleOtpLoginMode(
                                                            true),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: viewModel
                                                                    .isOtpLoginMode
                                                                ? AyurezeTheme
                                                                    .forestDeep
                                                                : Colors
                                                                    .transparent,
                                                            width: 2,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "OTP SMS Login",
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: viewModel
                                                                    .isOtpLoginMode
                                                                ? AyurezeTheme
                                                                    .forestDeep
                                                                : AyurezeTheme
                                                                    .textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            if (!viewModel.isOtpLoginMode) ...[
                                              OslerInput(
                                                label: getTranslated(
                                                        context,
                                                        AppString
                                                            .login_email_hint)
                                                    .toString(),
                                                hint: "example@email.com",
                                                controller: viewModel.email,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                prefixIcon: HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedMailAtSign01,
                                                    size: 20,
                                                    color: AyurezeTheme
                                                        .healingGreen100),
                                                validator: (String? value) {
                                                  if (value!.isEmpty) {
                                                    return getTranslated(
                                                            context,
                                                            AppString
                                                                .login_email_validator)
                                                        .toString();
                                                  }
                                                  if (!RegExp(
                                                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                                      .hasMatch(value)) {
                                                    return getTranslated(
                                                            context,
                                                            AppString
                                                                .login_email_validator2)
                                                        .toString();
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 14),
                                              OslerInput(
                                                label: getTranslated(
                                                        context,
                                                        AppString
                                                            .login_password_hint)
                                                    .toString(),
                                                hint: "••••••••",
                                                controller: viewModel.password,
                                                isPassword: viewModel.isHidden,
                                                prefixIcon: HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedSquareLock01,
                                                    size: 20,
                                                    color: AyurezeTheme
                                                        .healingGreen100),
                                                suffixIcon: IconButton(
                                                  icon: HugeIcon(
                                                      icon: viewModel.isHidden
                                                          ? HugeIcons
                                                              .strokeRoundedViewOff
                                                          : HugeIcons
                                                              .strokeRoundedView,
                                                      size: 20,
                                                      color: AyurezeTheme
                                                          .healingGreen100),
                                                  onPressed: viewModel
                                                      .togglePasswordVisibility,
                                                ),
                                                validator: (String? value) {
                                                  if (value!.isEmpty) {
                                                    return getTranslated(
                                                            context,
                                                            AppString
                                                                .login_password_validator)
                                                        .toString();
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 8),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pushNamed(
                                                          context,
                                                          'ForgotPasswordScreen'),
                                                  child: Text(
                                                    getTranslated(
                                                            context,
                                                            AppString
                                                                .login_forgot_password)
                                                        .toString(),
                                                    style: textTheme.labelMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AyurezeTheme
                                                          .healingGreen100,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              OslerButton(
                                                text: getTranslated(context,
                                                        AppString.login_button)
                                                    .toString(),
                                                onPressed: () {
                                                  if (viewModel
                                                      .formKey.currentState!
                                                      .validate()) {
                                                    viewModel.callApiForLogin(
                                                        context);
                                                  }
                                                },
                                              ),
                                            ] else ...[
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: OslerInput(
                                                      label: "Code",
                                                      hint: "+91",
                                                      controller: viewModel
                                                          .phoneCodeController,
                                                      readOnly: true,
                                                      onTap: () {
                                                        showCountryPicker(
                                                          context: context,
                                                          showPhoneCode: true,
                                                          onSelect: (Country
                                                                  country) =>
                                                              viewModel
                                                                  .updatePhoneCode(
                                                                      "+${country.phoneCode}"),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 5,
                                                    child: OslerInput(
                                                      label: "Phone Number",
                                                      hint:
                                                          "Enter phone number",
                                                      controller: viewModel
                                                          .phoneController,
                                                      keyboardType:
                                                          TextInputType.phone,
                                                      prefixIcon: HugeIcon(
                                                          icon: HugeIcons
                                                              .strokeRoundedSmartPhone01,
                                                          size: 20,
                                                          color: AyurezeTheme
                                                              .healingGreen100),
                                                      validator:
                                                          (String? value) {
                                                        if (value!.isEmpty) {
                                                          return "Please enter phone number";
                                                        }
                                                        if (value.length < 8) {
                                                          return "Please enter a valid phone number";
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (viewModel.otpSent) ...[
                                                const SizedBox(height: 14),
                                                OslerInput(
                                                  label:
                                                      "SMS Verification Code",
                                                  hint: "123456",
                                                  controller: viewModel
                                                      .otpCodeController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  prefixIcon: HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedPinLocation01,
                                                      size: 20,
                                                      color: AyurezeTheme
                                                          .healingGreen100),
                                                  validator: (String? value) {
                                                    if (value!.isEmpty) {
                                                      return "Please enter OTP code";
                                                    }
                                                    if (value.length != 6) {
                                                      return "OTP must be 6 digits";
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                              const SizedBox(height: 20),
                                              OslerButton(
                                                text: viewModel.otpSent
                                                    ? "Verify & Login"
                                                    : "Send OTP Verification",
                                                onPressed: () {
                                                  if (viewModel.otpSent) {
                                                    viewModel
                                                        .verifyOtpCode(context);
                                                  } else {
                                                    viewModel.sendOtp(context);
                                                  }
                                                },
                                              ),
                                            ],
                                            const SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Divider(
                                                        color: AyurezeTheme
                                                            .border)),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Text(
                                                    "Or continue with",
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AyurezeTheme
                                                          .textSecondary
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                    child: Divider(
                                                        color: AyurezeTheme
                                                            .border)),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(
                                                    double.infinity, 56),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16)),
                                                side: BorderSide(
                                                    color: AyurezeTheme.border),
                                              ),
                                              onPressed: () => viewModel
                                                  .handleGoogleSignIn(context),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SvgPicture.string(
                                                    '<svg viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/><path fill="none" d="M0 0h48v48H0z"/></svg>',
                                                    height: 24,
                                                    width: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    "Sign in with Google",
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AyurezeTheme
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AyurezeTheme.radiusXl),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 16, sigmaY: 16),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AyurezeTheme.spaceXl,
                                            vertical: AyurezeTheme.spaceSm),
                                        decoration:
                                            AyurezeTheme.glassDecoration(
                                                radius: AyurezeTheme.radiusXl),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                getTranslated(
                                                        context,
                                                        AppString
                                                            .login_dont_have_account)
                                                    .toString(),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: AyurezeTheme
                                                      .textSecondary,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pushNamed(
                                                      context, 'signup'),
                                              child: Text(
                                                getTranslated(context,
                                                        AppString.login_sign_up)
                                                    .toString(),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AyurezeTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glassBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

import 'package:doctro/core/constants/app_string.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/features/authentication/view_models/forgotpassword_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
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

    return ChangeNotifierProvider<ForgotPasswordViewModel>(
      create: (_) => ForgotPasswordViewModel(),
      child: Scaffold(
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
        body: SafeArea(
          child: Consumer<ForgotPasswordViewModel>(
            builder: (context, viewModel, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -80,
                    child: GlassBlob(
                        size: 220, color: AyurezeTheme.healingGreen50),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -70,
                    child: GlassBlob(
                        size: 220, color: AyurezeTheme.sunshineYellow50),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AyurezeTheme.spaceXl,
                          vertical: AyurezeTheme.spaceMd),
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
                                          Text(
                                            getTranslated(
                                                    context,
                                                    AppString
                                                        .forgot_password_title)
                                                .toString(),
                                            style: textTheme.headlineMedium
                                                ?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            getTranslated(
                                                    context,
                                                    AppString
                                                        .forgot_password_description)
                                                .toString(),
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    GlassSurface(
                                      padding: const EdgeInsets.all(
                                          AyurezeTheme.spaceXl),
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller:
                                                viewModel.emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            style:
                                                textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AyurezeTheme.textPrimary,
                                            ),
                                            decoration: AyurezeTheme
                                                .textFieldDecoration(
                                              labelText: getTranslated(
                                                      context,
                                                      AppString
                                                          .forgot_email_hint)
                                                  .toString(),
                                            ).copyWith(
                                              prefixIcon: HugeIcon(
                                                  icon: HugeIcons
                                                      .strokeRoundedMailAtSign01,
                                                  size: 20,
                                                  color:
                                                      AyurezeTheme.iconPrimary),
                                            ),
                                            validator: (String? value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return getTranslated(
                                                        context,
                                                        AppString
                                                            .please_enter_email)
                                                    .toString();
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          OslerButton(
                                            text: getTranslated(
                                                    context,
                                                    AppString
                                                        .forgot_reset_button)
                                                .toString(),
                                            isLoading: viewModel.isLoading,
                                            onPressed: () {
                                              if (viewModel
                                                  .formKey.currentState!
                                                  .validate()) {
                                                viewModel
                                                    .forgotPasswordScreenRequest(
                                                        context);
                                              }
                                            },
                                          ),
                                        ],
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
      ),
    );
  }
}

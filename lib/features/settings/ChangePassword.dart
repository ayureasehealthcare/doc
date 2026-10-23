import 'package:doctro/widgets/osler_hero.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'view_models/change_password_view_model.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  late double height;
  late double width;

  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider(
      create: (_) => ChangePasswordViewModel(),
      child: Scaffold(
        backgroundColor: AyurezeTheme.canvas,
        appBar: AppBar(
          backgroundColor: AyurezeTheme.canvas,
          leading: IconButton(
            icon: HugeIcon(
              icon: AppIcons.back,
              color: AyurezeTheme.iconPrimary,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            getTranslated(context, AppString.change_password_heading)
                .toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AyurezeTheme.textPrimary,
                ),
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SingleChildScrollView(
            padding: AyurezeTheme.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 18),
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return const OslerHero(
      eyebrow: 'Security update',
      title: 'Keep your doctor workspace protected.',
      subtitle:
          'Update your password with a calmer Ayureze-style form that keeps the task focused and clear.',
    );
  }

  Widget _buildFormCard() {
    return Consumer<ChangePasswordViewModel>(
      builder: (context, viewModel, child) {
        return GlassSurface(
          width: double.infinity,
          padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(getTranslated(context, AppString.change_old_password)
                  .toString()),
              TextFormField(
                controller: _oldPassword,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp('[a-zA-Z0-9!@#\$.*&~_]'))
                ],
                decoration: InputDecoration(
                  hintText:
                      getTranslated(context, AppString.change_old_password_hint)
                          .toString(),
                  suffixIcon: _toggleIcon(viewModel.isHidden, () {
                    viewModel.togglePasswordVisibility();
                  }),
                ),
                obscureText: viewModel.isHidden,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                            context, AppString.please_enter_old_password)
                        .toString();
                  } else if (value.length < 6) {
                    return getTranslated(
                            context, AppString.please_enter_valid_password)
                        .toString();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel(
                  getTranslated(context, AppString.change_enter_new_password)
                      .toString()),
              TextFormField(
                controller: _newPassword,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp('[a-zA-Z0-9!@#\$.*&~_]'))
                ],
                decoration: InputDecoration(
                  hintText: getTranslated(
                          context, AppString.change_enter_new_password_hint)
                      .toString(),
                  suffixIcon: _toggleIcon(viewModel.isHidden1, () {
                    viewModel.toggleNewPasswordVisibility();
                  }),
                ),
                obscureText: viewModel.isHidden1,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                            context, AppString.please_enter_new_password)
                        .toString();
                  } else if (value.length < 6) {
                    return getTranslated(
                            context, AppString.please_enter_valid_password)
                        .toString();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel(getTranslated(
                      context, AppString.change_enter_confirm_password)
                  .toString()),
              TextFormField(
                controller: _confirmPassword,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp('[a-zA-Z0-9!@#\$.*&~_]'))
                ],
                decoration: InputDecoration(
                  hintText: getTranslated(
                          context, AppString.change_enter_confirm_password_hint)
                      .toString(),
                  suffixIcon: _toggleIcon(viewModel.isHidden2, () {
                    viewModel.toggleConfirmPasswordVisibility();
                  }),
                ),
                obscureText: viewModel.isHidden2,
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                            context, AppString.please_enter_confirm_password)
                        .toString();
                  } else if (_newPassword.text != _confirmPassword.text) {
                    return getTranslated(context, AppString.confirm_not_match)
                        .toString();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: viewModel.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AyurezeTheme.iconPrimary,
                        ),
                      )
                    : OslerButton(
                        text: getTranslated(
                                context, AppString.change_password_button)
                            .toString(),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final response = await viewModel.passwordChange(
                              context,
                              _oldPassword.text,
                              _newPassword.text,
                              _confirmPassword.text,
                            );

                            // Inside build() the `context` parameter shadows State.context,
                            // so the check must be context.mounted.
                            if (!context.mounted) return;
                            if (response != null) {
                              if (response.success == true) {
                                OslerToast.success(context, response.data!);
                                Navigator.pop(context);
                              } else {
                                OslerToast.error(context, response.data!);
                              }
                            }
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceSm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AyurezeTheme.textPrimary,
            ),
      ),
    );
  }

  Widget _toggleIcon(bool hidden, VoidCallback onTap) {
    return IconButton(
      icon: HugeIcon(
        icon: hidden ? AppIcons.visibility : AppIcons.visibilityOff,
        color: AyurezeTheme.textSecondary,
      ),
      onPressed: onTap,
    );
  }
}

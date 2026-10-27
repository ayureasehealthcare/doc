import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/theme/theme_provider.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:provider/provider.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/widgets/osler_modal.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:doctro/widgets/osler_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:hugeicons/hugeicons.dart';

import 'ChangePassword.dart';
import 'changeLanguage.dart';
import 'view_models/settings_view_model.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
    _viewModel.loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchDoctorProfile(context);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AyurezeTheme.canvas,
        appBar: AppBar(
          backgroundColor: AyurezeTheme.canvas,
          leading: IconButton(
            icon: HugeIcon(
                icon: AppIcons.back, color: AyurezeTheme.iconPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            getTranslated(context, AppString.drawer_setting).toString(),
            style: AyurezeTheme.font(
              AyurezeTheme.textXl,
              FontWeight.w800,
              AyurezeTheme.textPrimary,
            ),
          ),
        ),
        body: Consumer<SettingsViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: AyurezeTheme.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenEntrance(index: 0, child: _buildHeroCard()),
                  const SizedBox(height: 18),
                  ScreenEntrance(
                    index: 1,
                    child: _buildSection(
                      title: getTranslated(
                        context,
                        AppString.settings_appearance,
                      ).toString(),
                      items: [
                        _buildToggleItem(
                          icon: AppIcons.settings,
                          title: getTranslated(
                            context,
                            AppString.settings_dark_mode,
                          ).toString(),
                          value: viewModel.isDarkMode,
                          color: AyurezeTheme.oslerGray50,
                          onChanged: (val) async {
                            viewModel.setDarkMode(val);
                            await context.read<ThemeProvider>().setDarkMode(
                                  val,
                                );
                            // Inside build() the `context` parameter shadows State.context,
                            // so the check must be context.mounted.
                            if (!context.mounted) return;
                            OslerToast.success(
                              context,
                              "Dark mode: ${val ? 'ON' : 'OFF'}",
                            );
                          },
                        ),
                        _buildNavigationItem(
                          icon: AppIcons.language2,
                          title: getTranslated(
                            context,
                            AppString.drawer_change_language,
                          ).toString(),
                          color: AyurezeTheme.sunshineYellow50,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeLanguage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ScreenEntrance(
                    index: 2,
                    child: _buildSection(
                      title: getTranslated(
                        context,
                        AppString.settings_notifications_section,
                      ).toString(),
                      items: [
                        _buildToggleItem(
                          icon: AppIcons.notifications,
                          title: getTranslated(
                            context,
                            AppString.settings_push_notifications,
                          ).toString(),
                          value: viewModel.isNotificationEnabled,
                          color: AyurezeTheme.remoteRed50,
                          onChanged: (val) {
                            viewModel.setNotificationEnabled(val);
                          },
                        ),
                        _buildToggleItem(
                          icon: AppIcons.videoCall,
                          title: getTranslated(
                            context,
                            AppString.video_call,
                          ).toString(),
                          subtitle: getTranslated(
                            context,
                            AppString.settings_video_call_desc,
                          ).toString(),
                          value: viewModel.isCallEnable,
                          color: AyurezeTheme.healingGreen50,
                          onChanged: (val) async {
                            bool success = await viewModel.updateVCall(
                              context,
                              val,
                            );
                            // Inside build() the `context` parameter shadows State.context,
                            // so the check must be context.mounted.
                            if (!context.mounted) return;
                            if (success) {
                              OslerToast.success(
                                context,
                                "Call settings updated!",
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ScreenEntrance(
                    index: 3,
                    child: _buildSection(
                      title: getTranslated(
                        context,
                        AppString.settings_security_section,
                      ).toString(),
                      items: [
                        _buildNavigationItem(
                          icon: AppIcons.password,
                          title: getTranslated(
                            context,
                            AppString.drawer_change_password,
                          ).toString(),
                          color: AyurezeTheme.healingGreenFill,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePassword(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ScreenEntrance(
                    index: 4,
                    child: _buildSection(
                      title: getTranslated(
                        context,
                        AppString.settings_support_section,
                      ).toString(),
                      items: [
                        _buildNavigationItem(
                          icon: AppIcons.help,
                          title: "Contact Support",
                          color: AyurezeTheme.connectivityBlue50,
                          onTap: () {
                            OslerToast.info(
                              context,
                              "Support ticket system coming soon",
                            );
                          },
                        ),
                        _buildNavigationItem(
                          icon: AppIcons.privacy,
                          title: getTranslated(
                            context,
                            AppString.settings_privacy_policy,
                          ).toString(),
                          color: AyurezeTheme.healingGreen50,
                          onTap: () {},
                        ),
                        _buildNavigationItem(
                          icon: AppIcons.terms,
                          title: getTranslated(
                            context,
                            AppString.settings_terms_conditions,
                          ).toString(),
                          color: AyurezeTheme.oslerGray50,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ScreenEntrance(
                    index: 5,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showDeleteAccountDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AyurezeTheme.danger,
                          side: BorderSide(color: AyurezeTheme.danger),
                        ),
                        child: Text(
                          getTranslated(
                            context,
                            AppString.settings_delete_account,
                          ).toString(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final name = SharedPreferenceHelper.getString(Preferences.name);
    final specialization = SharedPreferenceHelper.getStringOrNull(
      Preferences.specialization,
    );
    final avatarUrl = SharedPreferenceHelper.getString(Preferences.image);
    final hasAvatar = avatarUrl.isNotEmpty && avatarUrl != 'N_A';
    final hasName = name.isNotEmpty && name != 'N_A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AyurezeTheme.space2xl),
      decoration: AyurezeTheme.heroDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: hasAvatar
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const HugeIcon(
                            icon: HugeIcons.strokeRoundedUserCircle,
                            color: Colors.white,
                          ),
                          errorWidget: (_, __, ___) => const HugeIcon(
                            icon: HugeIcons.strokeRoundedUserCircle,
                            color: Colors.white,
                          ),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedUserCircle,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasName ? "Dr. $name" : "Doctor",
                      style: AyurezeTheme.font(
                        AyurezeTheme.textLg,
                        FontWeight.w800,
                        Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (specialization != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialization,
                        style: AyurezeTheme.font(
                          AyurezeTheme.textMd,
                          FontWeight.w500,
                          Colors.white.withValues(alpha: 0.78),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
                ),
                child: Text(
                  "Workspace",
                  style: AyurezeTheme.font(
                      AyurezeTheme.textXs, FontWeight.w700, Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Tune how your Ayureze desk behaves day to day.",
            style: AyurezeTheme.font(
              AyurezeTheme.text2xl,
              FontWeight.w800,
              Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Appearance, patient call controls, account security, and support live here.",
            style: AyurezeTheme.font(
              AyurezeTheme.textMd,
              FontWeight.w500,
              Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AyurezeTheme.spaceXs, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: AyurezeTheme.font(
              AyurezeTheme.textSm,
              FontWeight.w800,
              AyurezeTheme.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        GlassSurface(
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [
                  items[index],
                  if (index != items.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 18,
                      color: AyurezeTheme.border,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required List<List<dynamic>> icon,
    required String title,
    String? subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      // Tapping anywhere in the row toggles it too, not just the switch
      // itself - a larger, more forgiving tap target.
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceLg, vertical: 6),
      leading: OslerTooltip(message: title, child: _iconBadge(icon, color)),
      title: Text(
        title,
        style: AyurezeTheme.font(
            AyurezeTheme.textBase, FontWeight.w700, AyurezeTheme.textPrimary),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: AyurezeTheme.spaceXs),
              child: Text(
                subtitle,
                style: AyurezeTheme.font(
                  AyurezeTheme.textSm,
                  FontWeight.w500,
                  AyurezeTheme.textSecondary,
                ),
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: AyurezeTheme.forestDeep,
        activeTrackColor: AyurezeTheme.healingGreen50,
        onChanged: (val) {
          HapticFeedback.selectionClick();
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildNavigationItem({
    required List<List<dynamic>> icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedTapScale(
      // Dummy tap: only here to drive the press-in scale. The real tap
      // (with haptic) stays solely on ListTile's onTap below, so this
      // doesn't double-fire the callback.
      pressedScale: 0.99,
      onTap: () {},
      child: ListTile(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AyurezeTheme.spaceLg, vertical: 6),
        leading: OslerTooltip(message: title, child: _iconBadge(icon, color)),
        title: Text(
          title,
          style: AyurezeTheme.font(
            AyurezeTheme.textBase,
            FontWeight.w700,
            AyurezeTheme.textPrimary,
          ),
        ),
        trailing: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 14,
          color: AyurezeTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _iconBadge(List<List<dynamic>> icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
      ),
      child: HugeIcon(icon: icon, color: color, size: 22),
    );
  }

  void _showDeleteAccountDialog() {
    // Self-service deletion has no backend endpoint yet, so this dialog must
    // not claim the account has been deleted or that removal is in progress.
    // Telling the user their data was erased when nothing happened is a
    // correctness problem, not just a copy problem - health data is involved.
    OslerModal.show(
      context: context,
      title: "Delete Account",
      message:
          "Account deletion isn't available in the app yet. To request permanent "
          "deletion of your account and data, please contact our support team.",
      primaryText: "Close",
      primaryAction: () => Navigator.pop(context),
      isDanger: true,
    );
  }
}

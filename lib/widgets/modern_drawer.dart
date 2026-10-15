import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/glass_surface.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/features/authentication/professional_registration_screen.dart';
import 'package:doctro/features/consultation/chat/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String? dName =
        SharedPreferenceHelper.getStringOrNull(Preferences.name);
    final String dFullImage =
        SharedPreferenceHelper.getStringOrNull(Preferences.image) ?? '';
    final String? phone =
        SharedPreferenceHelper.getStringOrNull(Preferences.phone_no);

    return Drawer(
      child: Stack(
        children: [
          Container(color: AyurezeTheme.canvas),
          Positioned(
            top: 220,
            left: -70,
            child: GlassBlob(size: 200, color: AyurezeTheme.healingGreen50),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: GlassBlob(size: 220, color: AyurezeTheme.sunshineYellow50),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 54, left: 22, right: 22, bottom: 22),
                decoration: AyurezeTheme.heroDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusPill),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: Text(
                        "Ayureze Doctor Desk",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AyurezeTheme.healingGreen50, width: 2),
                        image: DecorationImage(
                          image: (dFullImage.isNotEmpty)
                              ? NetworkImage(dFullImage)
                              : const AssetImage("assets/images/no_image.jpg")
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Dr. ${dName ?? "Doctor"}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phone ?? "",
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AyurezeTheme.healingGreen50,
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusPill),
                      ),
                      child: Text(
                        "Verified Professional",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AyurezeTheme.forestDeep,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                  children: [
                    _sectionHeader(context, "Clinical Desk"),
                    _drawerItem(
                        context,
                        AppIcons.home,
                        getTranslated(context, AppString.drawer_home)
                            .toString(),
                        () => Navigator.popUntil(
                            context, ModalRoute.withName('loginHome'))),
                    _drawerItem(
                        context,
                        AppIcons.appointment,
                        getTranslated(context, AppString.drawer_appointments)
                            .toString(),
                        () => Navigator.popAndPushNamed(
                            context, 'AppointmentHistoryScreen'),
                        badge: _pulsingDot(AyurezeTheme.healingGreen50)),
                    _drawerItem(
                        context,
                        AppIcons.close,
                        getTranslated(
                                context, AppString.drawer_canceled_appointment)
                            .toString(),
                        () => Navigator.popAndPushNamed(
                            context, 'cancelAppoitmentRoutes')),
                    _sectionHeader(context, "Patient Care"),
                    _drawerItem(
                        context,
                        AppIcons.star,
                        getTranslated(context, AppString.drawer_review)
                            .toString(),
                        () => Navigator.popAndPushNamed(
                            context, 'rateAndReviewRoutes'),
                        badge: _pulsingDot(AyurezeTheme.healingGreen50)),
                    _drawerItem(
                        context,
                        AppIcons.notifications,
                        getTranslated(context, AppString.drawer_notification)
                            .toString(),
                        () => Navigator.popAndPushNamed(
                            context, 'notifications')),
                    _drawerItem(
                        context,
                        HugeIcons.strokeRoundedSearch01,
                        "Search",
                        () => Navigator.popAndPushNamed(context, 'search')),
                    _sectionHeader(context, "Office & Finances"),
                    _drawerItem(
                        context,
                        AppIcons.payment,
                        getTranslated(context, AppString.drawer_payments)
                            .toString(),
                        () => Navigator.popAndPushNamed(context, 'payment')),
                    _drawerItem(
                        context,
                        AppIcons.clock,
                        getTranslated(context, AppString.drawer_schedule_timing)
                            .toString(),
                        () => Navigator.popAndPushNamed(
                            context, 'Schedule Timings')),
                    _sectionHeader(context, "Preferences"),
                    _drawerItem(
                        context, AppIcons.verified, "Profile & Registration",
                        () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ProfessionalRegistrationScreen()));
                    }),
                    _drawerItem(
                        context,
                        AppIcons.settings,
                        getTranslated(context, AppString.drawer_setting)
                            .toString(),
                        () => Navigator.popAndPushNamed(context, 'Settings')),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Divider(color: AyurezeTheme.border),
                    ),
                    _drawerItem(
                        context,
                        AppIcons.logout,
                        getTranslated(context, AppString.drawer_logout)
                            .toString(),
                        () => _showLogoutDialog(context),
                        isDestructive: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AyurezeTheme.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  Widget _pulsingDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 2,
          )
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, List<List<dynamic>> icon,
      String label, VoidCallback onTap,
      {bool isDestructive = false, Widget? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceSm),
      child: GlassSurface(
        radius: AyurezeTheme.radius2xl,
        blur: 8,
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AyurezeTheme.danger.withValues(alpha: 0.1)
                  : AyurezeTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: HugeIcon(
                icon: icon,
                color: isDestructive
                    ? AyurezeTheme.danger
                    : AyurezeTheme.textPrimary,
                size: 20),
          ),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDestructive
                      ? AyurezeTheme.danger
                      : AyurezeTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[badge, const SizedBox(width: 8)],
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 14,
                color: isDestructive
                    ? AyurezeTheme.danger.withValues(alpha: 0.7)
                    : AyurezeTheme.textSecondary,
              ),
            ],
          ),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated(context, AppString.drawer_logout).toString()),
        content: Text(
            getTranslated(context, AppString.are_you_sure_logout).toString()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                  getTranslated(context, AppString.cancel_button).toString())),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // dismiss dialog
              // Full logout: clears prefs + signs out Firebase/Google.
              await context.read<AuthProvider>().handleSignOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, 'SignIn', (route) => false);
            },
            child: Text(
                getTranslated(context, AppString.logout_button).toString(),
                style: const TextStyle(color: AyurezeTheme.danger)),
          ),
        ],
      ),
    );
  }
}

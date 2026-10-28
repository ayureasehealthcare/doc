import 'package:doctro/widgets/osler_hero.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/localization/language_model.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/main.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  // This screen used to load the whole legacy doctor profile only to post it
  // back with the new language. Astra's doctor update (UpdateDoctorRequest)
  // has no language field, and the app language is a local setting anyway,
  // so the choice is saved on the device only (setLocale + language_name).
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
      body: GestureDetector(
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
                          final language = Language.languageList()[selected];
                          final locale = await setLocale(language.languageCode);
                          await SharedPreferenceHelper.setString(
                            Preferences.language_name,
                            language.name,
                          );
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
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
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
}

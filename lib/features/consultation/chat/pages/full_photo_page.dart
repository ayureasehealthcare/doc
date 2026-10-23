import 'package:doctro/core/constants/app_string.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullPhotoPage extends StatelessWidget {
  final String url;

  const FullPhotoPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AyurezeTheme.surfaceMuted,
        elevation: 0,
        title: Text(
          getTranslated(context, AppString.full_photo).toString(),
          style: TextStyle(color: AyurezeTheme.textPrimary),
        ),
        centerTitle: true,
        // IconButton rather than a bare InkWell: a full 48px tap target
        // and the same back affordance as every other screen.
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AyurezeTheme.iconPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        loadingBuilder: (context, _) => const OslerLoadingView(),
        errorBuilder: (context, _, __) => const OslerStateView(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          title: "Couldn't load this photo",
          tone: OslerStateTone.error,
        ),
      ),
    );
  }
}

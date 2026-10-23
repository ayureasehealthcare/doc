import 'package:doctro/core/constants/app_string.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/theme/ayureze_theme.dart';
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
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AyurezeTheme.textPrimary,
          ),
        ),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
      ),
    );
  }
}

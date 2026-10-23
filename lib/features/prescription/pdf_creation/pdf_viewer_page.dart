import 'dart:io';

import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final File? path;

  const PdfViewerPage({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        backgroundColor: AyurezeTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppIcons.back,
            color: AyurezeTheme.iconPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "PDF Preview",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AyurezeTheme.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: path != null
              ? SfPdfViewer.file(path!)
              : const OslerStateView(
                  icon: HugeIcons.strokeRoundedFile01,
                  title: "No PDF document loaded",
                  tone: OslerStateTone.muted,
                ),
        ),
      ),
    );
  }
}

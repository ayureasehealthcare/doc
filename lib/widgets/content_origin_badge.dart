import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:doctro/widgets/osler_tag.dart';

/// Where a piece of content shown to the doctor came from.
///
/// Doctor-app counterpart of the patient app's `ContentOrigin` - same two
/// labels, so the patient and doctor see the same wording for the same
/// thing.
enum ContentOrigin {
  /// Astra's own output: an AI-extracted intake, a drafted diagnosis, a
  /// suggestion, a chat reply, a proactive flag.
  astraSuggestion,

  /// The doctor's own entry or decision.
  doctorApproved;

  String get label => switch (this) {
        ContentOrigin.astraSuggestion => 'Astra suggestion',
        ContentOrigin.doctorApproved => 'Doctor-approved',
      };

  /// Origin of a field Astra may have pre-filled: unchanged Astra text is
  /// an Astra suggestion, anything the doctor typed or edited is theirs,
  /// and an empty field has no origin to show (null).
  static ContentOrigin? forDraft(String current, {String? astraDraft}) {
    if (current.trim().isEmpty) return null;
    if (astraDraft != null && current == astraDraft) {
      return ContentOrigin.astraSuggestion;
    }
    return ContentOrigin.doctorApproved;
  }
}

/// A small pill labelling content as "Astra suggestion" or
/// "Doctor-approved". Built on [OslerTag] so it uses the kit's
/// accent-on-tint pairs (shade 10 fill, shade 100 text), which read in both
/// light and dark mode.
///
/// Show it once per card or screen where the distinction matters, not on
/// every line - the same rule the patient app follows.
class ContentOriginBadge extends StatelessWidget {
  final ContentOrigin origin;

  const ContentOriginBadge({super.key, required this.origin});

  @override
  Widget build(BuildContext context) {
    final isAstra = origin == ContentOrigin.astraSuggestion;
    return Semantics(
      label: 'Content origin: ${origin.label}',
      excludeSemantics: true,
      child: OslerTag(
        label: origin.label,
        style: isAstra ? OslerTagStyle.warning : OslerTagStyle.success,
        icon: isAstra
            ? HugeIcons.strokeRoundedSparkles
            : HugeIcons.strokeRoundedCheckmarkBadge01,
      ),
    );
  }
}

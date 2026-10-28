import 'package:flutter/material.dart';

import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_tag.dart';

/// Shows the Astra AI companion's journey/progress for a consultation,
/// fetched by [caseId] (the `astra_case_id` stitched onto the appointment
/// at booking time - see Data.astraCaseId in appointment_details.dart).
///
/// Renders nothing (SizedBox.shrink) while loading, on a fetch failure, or
/// when the case can't be found - this is a best-effort companion panel
/// alongside the video-call entry point, never a reason to block or clutter
/// the appointment detail screen for appointments that predate the
/// Astra integration or weren't linked for any other reason.
class AstraCaseProgressCard extends StatefulWidget {
  final String caseId;

  const AstraCaseProgressCard({super.key, required this.caseId});

  @override
  State<AstraCaseProgressCard> createState() => _AstraCaseProgressCardState();
}

class _AstraCaseProgressCardState extends State<AstraCaseProgressCard> {
  Map<String, dynamic>? _case;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AstraApiService().getCompanionCase(widget.caseId);
    if (!mounted) return;
    setState(() {
      _case = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _case == null) return const SizedBox.shrink();

    final diagnosis = _case!['diagnosis']?.toString();
    final status = _case!['status']?.toString() ?? 'open';
    final progress = (_case!['progress_percentage'] as num?) ?? 0;
    final adherence = (_case!['adherence_score'] as num?) ?? 100;
    final durationDays = _case!['treatment_duration_days'];

    return OslerCard(
      margin: const EdgeInsets.only(top: AyurezeTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: AyurezeTheme.iconPrimary),
              const SizedBox(width: AyurezeTheme.spaceSm),
              Text(
                'Astra Companion',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AyurezeTheme.textMd,
                  color: AyurezeTheme.textPrimary,
                ),
              ),
              const Spacer(),
              OslerTag(
                  label: _statusLabel(status), style: _statusStyle(status)),
            ],
          ),
          if (diagnosis != null && diagnosis.isNotEmpty) ...[
            const SizedBox(height: AyurezeTheme.spaceSm),
            Text(
              diagnosis,
              style: TextStyle(
                  fontSize: AyurezeTheme.textMd,
                  color: AyurezeTheme.textSecondary),
            ),
          ],
          const SizedBox(height: AyurezeTheme.spaceMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
            child: LinearProgressIndicator(
              value: (progress.toDouble() / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AyurezeTheme.surfaceMuted,
              color: AyurezeTheme.iconPrimary,
            ),
          ),
          const SizedBox(height: AyurezeTheme.spaceXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.toStringAsFixed(0)}% through treatment'
                '${durationDays != null ? ' ($durationDays days)' : ''}',
                style: TextStyle(
                    fontSize: AyurezeTheme.textXs,
                    color: AyurezeTheme.textSecondary),
              ),
              Text(
                'Adherence ${adherence.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: AyurezeTheme.textXs,
                    color: AyurezeTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_treatment':
        return 'In treatment';
      case 'follow_up':
        return 'Follow-up';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  OslerTagStyle _statusStyle(String status) {
    switch (status) {
      case 'in_treatment':
        return OslerTagStyle.info;
      case 'follow_up':
        return OslerTagStyle.warning;
      case 'resolved':
      case 'closed':
        return OslerTagStyle.success;
      default:
        return OslerTagStyle.secondary;
    }
  }
}

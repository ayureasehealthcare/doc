import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'package:doctro/models/patient_wellness.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_tag.dart';

typedef WellnessLoader = Future<PatientWellness?> Function(String patientId);

/// Read-only view of the patient's wellness self-tracking (sleep,
/// movement, relaxation, mood) and their active goals.
///
/// Always labelled as patient-reported: these are numbers a patient typed
/// into their own app, not clinical measurements, and must never read as
/// vitals. When the data isn't available (the backend endpoint isn't live
/// yet, or the fetch failed) it says so instead of hiding or inventing it.
class PatientWellnessSection extends StatefulWidget {
  final String patientId;

  /// Defaults to [AstraApiService.getPatientWellness]; injectable for tests.
  final WellnessLoader? loader;

  /// How many of the most recent days to list.
  final int maxEntries;

  const PatientWellnessSection({
    super.key,
    required this.patientId,
    this.loader,
    this.maxEntries = 7,
  });

  @override
  State<PatientWellnessSection> createState() => _PatientWellnessSectionState();
}

class _PatientWellnessSectionState extends State<PatientWellnessSection> {
  PatientWellness? _wellness;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader = widget.loader ?? AstraApiService().getPatientWellness;
    PatientWellness? result;
    try {
      result = await loader(widget.patientId);
    } catch (_) {
      // Treated the same as "not available": this panel is supplementary
      // and must never take the patient screen down with it.
      result = null;
    }
    if (!mounted) return;
    setState(() {
      _wellness = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return OslerCard(
      margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceLg),
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedYoga01,
                size: 18,
                color: AyurezeTheme.iconPrimary,
              ),
              const SizedBox(width: AyurezeTheme.spaceSm),
              Expanded(
                child: Text(
                  'Wellness',
                  style: textTheme.titleMedium?.copyWith(
                    color: AyurezeTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const OslerTag(
                label: 'Patient-reported',
                style: OslerTagStyle.info,
              ),
            ],
          ),
          const SizedBox(height: AyurezeTheme.spaceXs),
          Text(
            'Self-tracked by the patient in their app. Not a clinical '
            'measurement.',
            style: textTheme.bodySmall
                ?.copyWith(color: AyurezeTheme.textSecondary),
          ),
          const SizedBox(height: AyurezeTheme.spaceMd),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AyurezeTheme.spaceSm),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final wellness = _wellness;
    if (wellness == null) {
      return _message(
        context,
        'Not available yet',
        'Wellness logs from the patient app aren\'t shared with doctors '
            'yet. They will appear here once that is switched on.',
      );
    }
    if (wellness.isEmpty) {
      return _message(
        context,
        'No wellness entries',
        'The patient hasn\'t logged any wellness data or goals.',
      );
    }

    final entries = wellness.entries.take(widget.maxEntries).toList();
    final goals = wellness.activeGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isEmpty)
          _message(context, 'No recent entries', null)
        else
          for (final entry in entries) _EntryRow(entry: entry),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: AyurezeTheme.spaceMd),
          Text(
            'Active goals',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AyurezeTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AyurezeTheme.spaceXs),
          for (final goal in goals)
            Padding(
              padding: const EdgeInsets.only(top: AyurezeTheme.spaceXs),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTarget01,
                    size: 14,
                    color: AyurezeTheme.textSecondary,
                  ),
                  const SizedBox(width: AyurezeTheme.spaceSm),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AyurezeTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _message(BuildContext context, String title, String? body) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            color: AyurezeTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: AyurezeTheme.spaceXs),
          Text(
            body,
            style: textTheme.bodySmall
                ?.copyWith(color: AyurezeTheme.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final WellnessEntry entry;

  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stats = <String>[
      if (entry.sleepHours != null) 'Sleep ${_trim(entry.sleepHours!)}h',
      if (entry.movementMinutes != null) 'Move ${entry.movementMinutes}m',
      if (entry.relaxationMinutes != null) 'Relax ${entry.relaxationMinutes}m',
      if (entry.moodLabel != null) 'Mood ${entry.moodLabel}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AyurezeTheme.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              _formatDate(entry.dateKey),
              style: textTheme.bodySmall?.copyWith(
                color: AyurezeTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              stats.isEmpty ? 'Note only' : stats.join('  ·  '),
              style: textTheme.bodySmall
                  ?.copyWith(color: AyurezeTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  static String _formatDate(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    return parsed == null ? dateKey : DateFormat('EEE d MMM').format(parsed);
  }
}

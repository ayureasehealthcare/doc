import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/widgets/content_origin_badge.dart';

/// Widget to display Astra Fill health intake records submitted by patient
/// This shows symptoms, vitals, medical history that patient filled in their app
class AstraFillDisplayWidget extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic>? preloadedData;

  const AstraFillDisplayWidget({
    super.key,
    required this.patientId,
    this.preloadedData,
  });

  @override
  _AstraFillDisplayWidgetState createState() => _AstraFillDisplayWidgetState();
}

class _AstraFillDisplayWidgetState extends State<AstraFillDisplayWidget> {
  final AstraApiService _astraService = AstraApiService();
  Map<String, dynamic>? _astraFillData;
  bool _isLoading = true;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedData != null && widget.preloadedData!.isNotEmpty) {
      _astraFillData = widget.preloadedData;
      _isLoading = false;
    } else {
      _loadAstraFillData();
    }
  }

  Future<void> _loadAstraFillData() async {
    try {
      final data = await _astraService.getLatestAstraFill(widget.patientId);
      if (mounted) {
        setState(() {
          _astraFillData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_astraFillData == null || _astraFillData!.isEmpty) {
      return _buildNoDataCard();
    }

    return _buildAstraFillCard();
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd)),
      child: Padding(
        padding: EdgeInsets.all(AyurezeTheme.spaceLg),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AyurezeTheme.purple),
            ),
            SizedBox(width: 12),
            Text("Loading patient's health intake...",
                style: TextStyle(color: AyurezeTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd)),
      child: Padding(
        padding: EdgeInsets.all(AyurezeTheme.spaceLg),
        child: Row(
          children: [
            HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                color: AyurezeTheme.textSecondary,
                size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "No health intake data available. Patient hasn't filled Astra form yet.",
                style: TextStyle(
                    color: AyurezeTheme.textSecondary,
                    fontSize: AyurezeTheme.textMd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAstraFillCard() {
    // Standardize data from the NEW upgraded Astra Fill 20-parameter model Response
    final chiefComplaint = _astraFillData?['primary_complaint'] ??
        _astraFillData?['chief_complaint'] ??
        '';
    final duration = _astraFillData?['duration'] ?? '';
    final severityDetails = _astraFillData?['severity_clues'] ?? '';
    final timing = _astraFillData?['pattern_or_timing'] ?? '';

    // Ayurvedic / Lifestyle Parameters
    final sleepDetails = _astraFillData?['sleep'] ?? '';
    final appetiteDetails = _astraFillData?['appetite'] ?? '';
    final bowelDetails = _astraFillData?['bowel'] ?? '';
    final micturitionDetails = _astraFillData?['micturition'] ?? '';

    // Medical History
    final pastHistory = _astraFillData?['past_history'] ?? '';
    final previousTreatment = _astraFillData?['previous_treatment'] ?? '';

    // Boolean Flags
    final hasDiabetes = _astraFillData?['history_of_diabetes'] == true;
    final hasThyroid = _astraFillData?['history_of_thyroid'] == true;
    final hasBp = _astraFillData?['history_of_blood_pressure'] == true;

    // Legacy support handles
    final currentMedications = _astraFillData?['current_medications'] ?? [];
    final vitals = _astraFillData?['vitals'];
    final medicalHistory = _astraFillData?['medical_history'];
    final timestamp =
        _astraFillData?['created_at'] ?? _astraFillData?['timestamp'] ?? '';
    final severityScore = _astraFillData?['severity_score'];

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
          gradient: LinearGradient(
            // Ends on the themed surface, not white: a white end stranded the
            // dark-mode (light) text on a near-white corner.
            colors: [
              AyurezeTheme.purple.withValues(alpha: 0.05),
              AyurezeTheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AyurezeTheme.radiusLg)),
              child: Container(
                padding: EdgeInsets.all(AyurezeTheme.spaceLg),
                decoration: BoxDecoration(
                  color: AyurezeTheme.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AyurezeTheme.radiusLg)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AyurezeTheme.spaceSm),
                          decoration: BoxDecoration(
                            color: AyurezeTheme.purple,
                            borderRadius:
                                BorderRadius.circular(AyurezeTheme.radiusSm),
                          ),
                          child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSparkles,
                              color: Colors.white,
                              size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Astra AI Health Intake",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AyurezeTheme.purple,
                                    ),
                              ),
                              if (timestamp.isNotEmpty)
                                Text(
                                  "Submitted by patient",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AyurezeTheme.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        HugeIcon(
                          icon: _isExpanded
                              ? HugeIcons.strokeRoundedArrowUp01
                              : HugeIcons.strokeRoundedArrowDown01,
                          color: AyurezeTheme.purple,
                        ),
                      ],
                    ),
                    // Badges get their own wrapping line, so the title row is
                    // just icon + title + chevron. Next to the severity pill
                    // the title had ~100px and wrapped to three lines.
                    Padding(
                      padding: const EdgeInsets.only(top: AyurezeTheme.spaceSm),
                      child: Wrap(
                        spacing: AyurezeTheme.spaceSm,
                        runSpacing: AyurezeTheme.spaceXs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const ContentOriginBadge(
                              origin: ContentOrigin.astraSuggestion),
                          if (severityScore != null)
                            SeverityPill(score: severityScore),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable Content
            if (_isExpanded)
              Padding(
                padding: EdgeInsets.all(AyurezeTheme.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chief Complaint
                    if (chiefComplaint.toString().isNotEmpty)
                      _buildSection(
                        icon: HugeIcons.strokeRoundedAlertDiamond,
                        title: "Primary Complaint",
                        content: chiefComplaint.toString(),
                        iconColor: AyurezeTheme.warning,
                      ),

                    // Severity & Timing
                    if (severityDetails.toString().isNotEmpty ||
                        timing.toString().isNotEmpty)
                      _buildSection(
                        icon: HugeIcons.strokeRoundedChartLine,
                        title: "Pattern & Severity",
                        content:
                            "${severityDetails.toString().isNotEmpty ? 'Severity: $severityDetails\n' : ''}"
                            "${timing.toString().isNotEmpty ? 'Timing: $timing' : ''}",
                        iconColor: Colors.redAccent,
                      ),

                    // Duration
                    if (duration.toString().isNotEmpty)
                      _buildSection(
                        icon: HugeIcons.strokeRoundedClock01,
                        title: "Duration",
                        content: duration.toString(),
                        iconColor: Colors.blue,
                      ),

                    // Lifestyle & Ayurvedic Parameters
                    if (sleepDetails.toString().isNotEmpty ||
                        appetiteDetails.toString().isNotEmpty ||
                        bowelDetails.toString().isNotEmpty ||
                        micturitionDetails.toString().isNotEmpty)
                      _buildSection(
                        icon: HugeIcons.strokeRoundedYoga01,
                        title: "Lifestyle & Ashtavidha Pariksha",
                        content: "${sleepDetails.toString().isNotEmpty ? '• Sleep: $sleepDetails\n' : ''}"
                                "${appetiteDetails.toString().isNotEmpty ? '• Appetite: $appetiteDetails\n' : ''}"
                                "${bowelDetails.toString().isNotEmpty ? '• Bowel: $bowelDetails\n' : ''}"
                                "${micturitionDetails.toString().isNotEmpty ? '• Urine: $micturitionDetails' : ''}"
                            .trim(),
                        iconColor: AyurezeTheme.healingGreen50,
                      ),

                    // Medical Flags
                    if (hasDiabetes ||
                        hasThyroid ||
                        hasBp ||
                        pastHistory.toString().isNotEmpty)
                      _buildSection(
                        icon: HugeIcons.strokeRoundedClock05,
                        title: "Medical History",
                        content: "${hasDiabetes ? '⚠️ Diabetes\n' : ''}"
                                "${hasThyroid ? '⚠️ Thyroid\n' : ''}"
                                "${hasBp ? '⚠️ Blood Pressure\n' : ''}"
                                "${pastHistory.toString().isNotEmpty ? 'Details: $pastHistory' : ''}"
                            .trim(),
                        iconColor: AyurezeTheme.iconPrimary,
                      ),

                    // Previous Treatment
                    if (previousTreatment.toString().isNotEmpty)
                      _buildSection(
                        icon: HugeIcons.strokeRoundedMedicineBottle01,
                        title: "Previous Treatment",
                        content: previousTreatment.toString(),
                        iconColor: Colors.teal,
                      ),

                    // Current Medications (Legacy/Standard)
                    if (currentMedications != null &&
                        (currentMedications as List).isNotEmpty)
                      _buildChipsSection(
                        icon: HugeIcons.strokeRoundedMedicine02,
                        title: "Current Medications",
                        items: List<String>.from(currentMedications),
                        chipColor: AyurezeTheme.healingGreen10,
                        textColor: AyurezeTheme.healingGreen100,
                      ),

                    // Vitals
                    if (vitals is Map && vitals.isNotEmpty)
                      _buildVitalsSection(vitals.cast<String, dynamic>()),

                    // Structured medical history
                    if (medicalHistory is Map && medicalHistory.isNotEmpty)
                      _buildMedicalHistorySection(
                          medicalHistory.cast<String, dynamic>()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required List<List<dynamic>> icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AyurezeTheme.spaceLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusXs),
            ),
            child: HugeIcon(icon: icon, color: iconColor, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AyurezeTheme.textSecondary)),
                SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AyurezeTheme.textPrimary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsSection({
    required List<List<dynamic>> icon,
    required String title,
    required List<String> items,
    required Color chipColor,
    required Color textColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, color: textColor, size: 18),
              SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AyurezeTheme.textSecondary)),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusXl),
                        border:
                            Border.all(color: textColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                            color: textColor,
                            fontSize: AyurezeTheme.textMd,
                            fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSection(Map vitals) {
    return Padding(
      padding: EdgeInsets.only(bottom: AyurezeTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedPulse02,
                  color: AyurezeTheme.danger,
                  size: 18),
              SizedBox(width: 8),
              Text("Vitals",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AyurezeTheme.textSecondary)),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(AyurezeTheme.spaceMd),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (vitals['blood_pressure'] != null)
                  _buildVitalItem("BP", vitals['blood_pressure'].toString(),
                      HugeIcons.strokeRoundedFavouriteCircle),
                if (vitals['heart_rate'] != null)
                  _buildVitalItem("HR", "${vitals['heart_rate']} bpm",
                      HugeIcons.strokeRoundedPulse01),
                if (vitals['temperature'] != null)
                  _buildVitalItem("Temp", "${vitals['temperature']}°F",
                      HugeIcons.strokeRoundedTemperature),
                if (vitals['oxygen_saturation'] != null ||
                    vitals['spo2'] != null)
                  _buildVitalItem(
                      "SpO2",
                      "${vitals['oxygen_saturation'] ?? vitals['spo2']}%",
                      HugeIcons.strokeRoundedWind),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, List<List<dynamic>> icon) {
    return Column(
      children: [
        HugeIcon(icon: icon, color: Colors.blue.shade700, size: 20),
        SizedBox(height: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AyurezeTheme.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: AyurezeTheme.textMd,
                fontWeight: FontWeight.bold,
                color: AyurezeTheme.textPrimary)),
      ],
    );
  }

  Widget _buildMedicalHistorySection(Map history) {
    List<String> conditions = [];

    if (history['conditions'] != null) {
      if (history['conditions'] is List) {
        conditions.addAll(List<String>.from(history['conditions']));
      } else {
        conditions.add(history['conditions'].toString());
      }
    }
    if (history['chronic_conditions'] != null) {
      if (history['chronic_conditions'] is List) {
        conditions.addAll(List<String>.from(history['chronic_conditions']));
      } else {
        conditions.add(history['chronic_conditions'].toString());
      }
    }
    if (history['past_surgeries'] != null) {
      if (history['past_surgeries'] is List) {
        conditions.addAll(
            (history['past_surgeries'] as List).map((s) => "Surgery: $s"));
      } else {
        conditions.add("Surgery: ${history['past_surgeries'].toString()}");
      }
    }

    if (conditions.isEmpty) return SizedBox.shrink();

    return _buildChipsSection(
      icon: HugeIcons.strokeRoundedClock05,
      title: "Medical History",
      items: conditions,
      chipColor: AyurezeTheme.surfaceMuted,
      textColor: AyurezeTheme.textPrimary,
    );
  }
}

/// Compact version for inline display (e.g., in prescription screen)
class AstraFillCompactWidget extends StatelessWidget {
  final Map<String, dynamic>? astraFillData;

  const AstraFillCompactWidget({super.key, this.astraFillData});

  @override
  Widget build(BuildContext context) {
    if (astraFillData == null || astraFillData!.isEmpty) {
      return SizedBox.shrink();
    }

    final rawSymptoms =
        astraFillData?['extracted_symptoms'] ?? astraFillData?['symptoms'];
    final List<String> symptoms = rawSymptoms is List
        ? List<String>.from(rawSymptoms)
        : (rawSymptoms != null ? [rawSymptoms.toString()] : []);
    final severityScore = astraFillData?['severity_score'];

    return Card(
      color: AyurezeTheme.purple.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd)),
      child: Padding(
        padding: EdgeInsets.all(AyurezeTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    color: AyurezeTheme.purple,
                    size: 18),
                SizedBox(width: 8),
                Text(
                  "Astra AI Summary",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: AyurezeTheme.purple),
                ),
                Spacer(),
                if (severityScore != null)
                  SeverityPill(score: severityScore, compact: true),
              ],
            ),
            const SizedBox(height: AyurezeTheme.spaceXs),
            const ContentOriginBadge(origin: ContentOrigin.astraSuggestion),
            ...[
              SizedBox(height: 8),
              Text(
                "Symptoms: ${symptoms.join(', ')}",
                style: TextStyle(
                    fontSize: AyurezeTheme.textMd,
                    color: AyurezeTheme.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Severity of a patient's intake as a tint-pair pill (shade 10 behind its
/// shade 100 ink, 8:1 or better in both themes). It used white text on the
/// band colour, which was 1.9-4.9:1 across the three bands.
class SeverityPill extends StatelessWidget {
  final dynamic score;
  final bool compact;

  const SeverityPill({super.key, required this.score, this.compact = false});

  static int parse(dynamic score) =>
      score is int ? score : int.tryParse(score.toString()) ?? 0;

  /// (background, foreground) for the band [score] falls in.
  static (Color, Color) colorsFor(dynamic score) {
    final severity = parse(score);
    if (severity <= 3) {
      return (AyurezeTheme.healingGreen10, AyurezeTheme.healingGreen100);
    }
    if (severity <= 6) {
      return (AyurezeTheme.sunshineYellow10, AyurezeTheme.sunshineYellow100);
    }
    return (AyurezeTheme.remoteRed10, AyurezeTheme.remoteRed100);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colorsFor(score);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AyurezeTheme.spaceMd,
        vertical: AyurezeTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusPill),
      ),
      child: Text(
        compact ? "$score/10" : "Severity: $score/10",
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
      ),
    );
  }
}

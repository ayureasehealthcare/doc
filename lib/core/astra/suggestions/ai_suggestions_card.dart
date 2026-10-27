import 'package:flutter/material.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/astra/suggestions/suggestion_model.dart';
import 'package:doctro/core/astra/navigation/app_router.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/content_origin_badge.dart';

/// AI Suggestions Card Widget
///
/// A compact card that displays contextual AI suggestions
/// from Astra. Can be added to existing screens without modification.
class AISuggestionsCard extends StatelessWidget {
  /// List of suggestions to display
  final List<AISuggestion> suggestions;

  /// Title for the card
  final String title;

  /// Maximum number of suggestions to show (0 = show all)
  final int maxVisible;

  /// Callback when a suggestion is tapped
  final void Function(AISuggestion)? onSuggestionTap;

  /// Callback when a suggestion is dismissed
  final void Function(AISuggestion)? onDismiss;

  /// Whether to show the card header
  final bool showHeader;

  /// Whether to show expand/collapse
  final bool collapsible;

  const AISuggestionsCard({
    super.key,
    required this.suggestions,
    this.title = 'AI Suggestions',
    this.maxVisible = 3,
    this.onSuggestionTap,
    this.onDismiss,
    this.showHeader = true,
    this.collapsible = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeSuggestions = suggestions.where((s) => !s.isDismissed).toList();
    if (activeSuggestions.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'AI Suggestions, ${activeSuggestions.length} items',
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(
            horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
          side: BorderSide(
            color: AyurezeTheme.healingGreen50.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildHeader(context),
            _buildSuggestionsList(activeSuggestions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AyurezeTheme.spaceLg,
          AyurezeTheme.spaceMd, AyurezeTheme.spaceSm, AyurezeTheme.spaceSm),
      decoration: BoxDecoration(
        color: AyurezeTheme.healingGreen50.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AyurezeTheme.radiusMd),
          topRight: Radius.circular(AyurezeTheme.radiusMd),
        ),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedBrain01,
            size: 18,
            color: AyurezeTheme.healingGreen50,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AyurezeTheme.textMd,
                fontWeight: FontWeight.w600,
                color: AyurezeTheme.textPrimary,
              ),
            ),
          ),
          const ContentOriginBadge(origin: ContentOrigin.astraSuggestion),
          _buildCollapsibleButton(context),
        ],
      ),
    );
  }

  Widget _buildCollapsibleButton(BuildContext context) {
    if (!collapsible) return const SizedBox.shrink();

    return IconButton(
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowDown01,
        color: AyurezeTheme.textSecondary,
        size: 20,
      ),
      onPressed: () {
        // Toggle expansion - parent should handle state
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Expand suggestions',
    );
  }

  Widget _buildSuggestionsList(List<AISuggestion> suggestions) {
    final visible =
        maxVisible > 0 ? suggestions.take(maxVisible).toList() : suggestions;
    final hidden = maxVisible > 0
        ? suggestions.skip(maxVisible).toList()
        : <AISuggestion>[];

    return Column(
      children: [
        ...visible.map((s) => _buildSuggestionTile(s)),
        if (hidden.isNotEmpty) _buildMoreIndicator(hidden.length),
      ],
    );
  }

  Widget _buildSuggestionTile(AISuggestion suggestion) {
    return Semantics(
      label: '${suggestion.type.label} suggestion: ${suggestion.title}',
      hint: 'Double tap to view details',
      button: true,
      child: InkWell(
        onTap: () => _handleSuggestionTap(suggestion),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceLg, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(suggestion),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(suggestion),
                    if (suggestion.description != null)
                      _buildDescription(suggestion),
                  ],
                ),
              ),
              _buildPriorityBadge(suggestion),
              _buildDismissButton(suggestion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(AISuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: suggestion.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusSm),
      ),
      child: HugeIcon(
        icon: suggestion.icon,
        size: 16,
        color: suggestion.color,
      ),
    );
  }

  Widget _buildTitle(AISuggestion suggestion) {
    return Text(
      suggestion.title,
      style: TextStyle(
        fontSize: AyurezeTheme.textMd,
        fontWeight: FontWeight.w500,
        color: AyurezeTheme.textPrimary,
      ),
    );
  }

  Widget _buildDescription(AISuggestion suggestion) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        suggestion.description!,
        style: TextStyle(
          fontSize: AyurezeTheme.textSm,
          color: AyurezeTheme.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPriorityBadge(AISuggestion suggestion) {
    if (suggestion.priority == SuggestionPriority.medium) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: AyurezeTheme.spaceSm),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: suggestion.priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusXs),
      ),
      child: Text(
        suggestion.priority.label,
        style: TextStyle(
          fontSize: AyurezeTheme.textXs,
          fontWeight: FontWeight.w500,
          color: suggestion.priorityColor,
        ),
      ),
    );
  }

  Widget _buildDismissButton(AISuggestion suggestion) {
    return IconButton(
      icon: HugeIcon(
        icon: AppIcons.close,
        size: 16,
        color: AyurezeTheme.textSecondary,
      ),
      onPressed: () => _handleDismiss(suggestion),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      tooltip: 'Dismiss suggestion',
    );
  }

  Widget _buildMoreIndicator(int count) {
    return InkWell(
      onTap: () {
        // Parent should expand to show all
        onSuggestionTap?.call(suggestions.first);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 16,
              color: AyurezeTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '+$count more suggestions',
              style: TextStyle(
                fontSize: AyurezeTheme.textSm,
                color: AyurezeTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuggestionTap(AISuggestion suggestion) {
    // Handle action if present
    if (suggestion.action != null) {
      _executeAction(suggestion.action!);
    }
    onSuggestionTap?.call(suggestion);
  }

  void _handleDismiss(AISuggestion suggestion) {
    suggestion.isDismissed = true;
    onDismiss?.call(suggestion);
  }

  void _executeAction(SuggestionAction action) {
    // Map action to navigation
    switch (action.type) {
      case 'open_patient':
        AppRouter.instance.openPatient(
          patientId: action.params['patient_id']?.toString() ?? '',
        );
        break;
      case 'open_prescription':
        AppRouter.instance.openPrescription(
          prescriptionId: action.params['prescription_id']?.toString(),
          patientId: action.params['patient_id']?.toString(),
        );
        break;
      case 'open_reminder':
        AppRouter.instance.openReminders(
          patientId: action.params['patient_id']?.toString(),
        );
        break;
      case 'open_payment':
        AppRouter.instance.openPayment();
        break;
      case 'open_appointment':
        AppRouter.instance.openAppointment(
          appointmentId: action.params['appointment_id']?.toString(),
        );
        break;
      default:
        // Generic navigation
        break;
    }
  }
}

/// Compact suggestion badge for inline display
class AISuggestionBadge extends StatelessWidget {
  final AISuggestion suggestion;
  final VoidCallback? onTap;

  const AISuggestionBadge({
    super.key,
    required this.suggestion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${suggestion.type.label}: ${suggestion.title}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: suggestion.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
            border: Border.all(
              color: suggestion.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: suggestion.icon,
                size: 14,
                color: suggestion.color,
              ),
              const SizedBox(width: 4),
              Text(
                suggestion.title,
                style: TextStyle(
                  fontSize: AyurezeTheme.textSm,
                  fontWeight: FontWeight.w500,
                  color: suggestion.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Suggestion indicator dot
class AISuggestionDot extends StatelessWidget {
  final int count;
  final Color? color;

  const AISuggestionDot({
    super.key,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Semantics(
      label: '$count AI suggestions available',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: (color ?? Colors.green).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSparkles,
              size: 10,
              color: color ?? Colors.green,
            ),
            const SizedBox(width: 2),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: AyurezeTheme.textXs,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

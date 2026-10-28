import 'package:flutter/material.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/astra/actions/action_models.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Astra Action Chip Widget
///
/// Displays a clickable action chip from Astra AI response.
class AstraActionChip extends StatelessWidget {
  final AstraNavigationAction action;
  final void Function(AstraNavigationAction action)? onTap;
  final bool isSelected;
  final bool isLoading;

  const AstraActionChip({
    super.key,
    required this.action,
    this.onTap,
    this.isSelected = false,
    this.isLoading = false,
  });

  String get _accessibilityLabel {
    final description = action.description ?? _getDefaultDescription();
    final priority = action.priority == ActionPriority.high
        ? ', High priority'
        : (action.priority == ActionPriority.critical
            ? ', Critical priority'
            : '');
    return '$description$priority${isSelected ? ', Selected' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _accessibilityLabel,
      hint: isLoading ? 'Loading, please wait' : 'Double tap to activate',
      button: true,
      enabled: !isLoading,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => onTap?.call(action),
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: AyurezeTheme.spaceLg, vertical: 10),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
              border: Border.all(
                color: _getBorderColor(),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                    icon: _getActionIcon(), size: 18, color: _getIconColor()),
                const SizedBox(width: 8),
                Text(
                  action.description ?? _getDefaultDescription(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getTextColor(),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
                if (action.priority == ActionPriority.high ||
                    action.priority == ActionPriority.critical) ...[
                  const SizedBox(width: 8),
                  _buildPriorityIndicator(),
                ],
                if (isLoading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_getAccentColor()),
                    ),
                  ),
                ],
                if (!isLoading) ...[
                  const SizedBox(width: 4),
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: _getTextColor().withValues(alpha: 0.6)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    if (action.priority == ActionPriority.critical) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
        ),
        child: const Text('⚡', style: TextStyle(fontSize: AyurezeTheme.textXs)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(AyurezeTheme.radiusMd),
      ),
      child: Text(
        '!',
        style: TextStyle(
          fontSize: AyurezeTheme.textXs,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) return _getAccentColor().withValues(alpha: 0.1);
    switch (action.priority) {
      case ActionPriority.critical:
        return Colors.red.shade50;
      case ActionPriority.high:
        return Colors.orange.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    if (isSelected) return _getAccentColor();
    switch (action.priority) {
      case ActionPriority.critical:
        return Colors.red.shade300;
      case ActionPriority.high:
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getAccentColor() {
    switch (action.priority) {
      case ActionPriority.critical:
        return Colors.red;
      case ActionPriority.high:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getTextColor() {
    if (isSelected) return _getAccentColor();
    switch (action.priority) {
      case ActionPriority.critical:
        return Colors.red.shade700;
      case ActionPriority.high:
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getIconColor() {
    if (isSelected) return _getAccentColor();
    switch (action.priority) {
      case ActionPriority.critical:
        return Colors.red;
      case ActionPriority.high:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<List<dynamic>> _getActionIcon() {
    switch (action.type) {
      case AstraActionType.openPatient:
        return HugeIcons.strokeRoundedUser;
      case AstraActionType.openPrescription:
        return HugeIcons.strokeRoundedFile01;
      case AstraActionType.openReport:
        return HugeIcons.strokeRoundedChartLine;
      case AstraActionType.openStorage:
        return AppIcons.folder;
      case AstraActionType.openReminders:
        return HugeIcons.strokeRoundedAlarmClock;
      case AstraActionType.openNotifications:
        return AppIcons.notifications;
      case AstraActionType.openAppointmentBooking:
        return HugeIcons.strokeRoundedCalendar03;
      case AstraActionType.openChat:
        return AppIcons.chat;
      case AstraActionType.openPayment:
        return AppIcons.payment;
      case AstraActionType.openVideoCall:
        return HugeIcons.strokeRoundedVideo01;
      case AstraActionType.openAppointment:
        return HugeIcons.strokeRoundedCalendar03;
      case AstraActionType.openProfile:
        return HugeIcons.strokeRoundedUserCircle;
      case AstraActionType.goBack:
        return HugeIcons.strokeRoundedArrowLeft01;
      case AstraActionType.unknown:
        return HugeIcons.strokeRoundedCursor02;
    }
  }

  String _getDefaultDescription() {
    switch (action.type) {
      case AstraActionType.openPatient:
        return 'View Patient';
      case AstraActionType.openPrescription:
        return 'Open Prescription';
      case AstraActionType.openReport:
        return 'View Report';
      case AstraActionType.openStorage:
        return 'View Documents';
      case AstraActionType.openReminders:
        return 'Manage Reminders';
      case AstraActionType.openNotifications:
        return 'View Notifications';
      case AstraActionType.openAppointmentBooking:
        return 'Book Appointment';
      case AstraActionType.openChat:
        return 'Open Chat';
      case AstraActionType.openPayment:
        return 'Pay Now';
      case AstraActionType.openVideoCall:
        return 'Start Video Call';
      case AstraActionType.openAppointment:
        return 'View Appointment';
      case AstraActionType.openProfile:
        return 'View Profile';
      case AstraActionType.goBack:
        return 'Go Back';
      case AstraActionType.unknown:
        return 'Take Action';
    }
  }
}

/// Widget to display a list of action chips
class AstraActionChipList extends StatelessWidget {
  final List<AstraNavigationAction> actions;
  final void Function(AstraNavigationAction action)? onActionTap;
  final String? loadingActionType;

  const AstraActionChipList({
    super.key,
    required this.actions,
    this.onActionTap,
    this.loadingActionType,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        return AstraActionChip(
          action: action,
          onTap: onActionTap,
          isLoading: loadingActionType == action.type.name,
        );
      }).toList(),
    );
  }
}

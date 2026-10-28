import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/core/astra/models/conversation_model.dart';
import 'package:doctro/core/astra/utils/astra_config.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Astra Chat Bubble Widget
///
/// Displays a single chat message in the Astra conversation.
/// Fully accessible with screen reader support.
class AstraChatBubble extends StatelessWidget {
  /// The message to display
  final AstraMessage message;

  /// Whether this message is from the current user
  final bool isUser;

  /// Callback when action is tapped
  final void Function(String actionType, Map<String, dynamic>? params)?
      onActionTap;

  const AstraChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.onActionTap,
  });

  /// Get accessibility label for screen readers
  String get _accessibilityLabel {
    final role = message.role == MessageRole.user
        ? 'You'
        : (message.role == MessageRole.system ? 'System' : 'Astra AI');
    final status = message.status == MessageStatus.sending
        ? 'Sending'
        : (message.status == MessageStatus.failed ? 'Failed' : '');
    return '$role message: ${message.content}. $status'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: _accessibilityLabel,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: isUser ? 48 : AyurezeTheme.spaceLg,
            right: isUser ? AyurezeTheme.spaceLg : 48,
            top: AyurezeTheme.spaceXs,
            bottom: AyurezeTheme.spaceXs,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Message content
              Semantics(
                label: 'Message content',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AyurezeTheme.spaceLg,
                    vertical: AyurezeTheme.spaceMd,
                  ),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AyurezeTheme.radiusXl),
                      topRight: const Radius.circular(AyurezeTheme.radiusXl),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      _buildMessageContent(theme),

                      // Streaming indicator
                      if (message.status == MessageStatus.sending &&
                          message.role == MessageRole.assistant)
                        _buildStreamingIndicator(),

                      // Action button
                      if (message.action != null) _buildActionButton(theme),
                    ],
                  ),
                ),
              ),

              // Timestamp
              Semantics(
                label: 'Sent at ${_formatTime(message.createdAt)}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: AyurezeTheme.spaceXs,
                      left: AyurezeTheme.spaceXs,
                      right: AyurezeTheme.spaceXs),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // Error indicator
              if (message.status == MessageStatus.failed)
                _buildErrorIndicator(theme),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (message.role == MessageRole.system) {
      return message.status == MessageStatus.failed
          ? Colors.red.shade50
          : Colors.blue.shade50;
    }

    if (message.status == MessageStatus.failed) {
      return Colors.red.shade50;
    }

    return isUser
        ? AstraConfig.enableLogging
            ? Colors.green.shade100
            : Colors.grey.shade200
        : Colors.white;
  }

  Widget _buildMessageContent(ThemeData theme) {
    final textColor = message.role == MessageRole.system
        ? (message.status == MessageStatus.failed
            ? Colors.red.shade700
            : Colors.blue.shade700)
        : (isUser ? Colors.white : Colors.black87);

    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isUser ? Colors.white : textColor,
      height: 1.4,
    );

    // Only the assistant writes markdown (bold, lists, headers) - user
    // input and system status lines are always plain text, so rendering
    // them as markdown would just be extra cost for no visual difference.
    if (message.role != MessageRole.assistant) {
      return SelectableText(message.content, style: baseStyle);
    }

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        strong: baseStyle?.copyWith(fontWeight: FontWeight.bold),
        em: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        listBullet: baseStyle,
        h1: baseStyle?.copyWith(
            fontSize: AyurezeTheme.textXl,
            fontWeight: FontWeight.bold,
            height: 1.6),
        h2: baseStyle?.copyWith(
            fontSize: AyurezeTheme.textLg,
            fontWeight: FontWeight.bold,
            height: 1.6),
        h3: baseStyle?.copyWith(
            fontSize: AyurezeTheme.textBase,
            fontWeight: FontWeight.bold,
            height: 1.6),
        code: baseStyle?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.black.withValues(alpha: 0.06),
        ),
        blockquoteDecoration: BoxDecoration(
          border:
              Border(left: BorderSide(color: Colors.grey.shade400, width: 3)),
        ),
        blockSpacing: 8,
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: AyurezeTheme.spaceSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: message.streamProgress,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message.streamProgress != null
                ? '${(message.streamProgress! * 100).toInt()}%'
                : 'Typing...',
            style: const TextStyle(
              fontSize: AyurezeTheme.textSm,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    final action = message.action!;
    final actionLabel = action.description ?? _getActionLabel(action.type.name);

    return Semantics(
      label: 'Action button: $actionLabel',
      hint: 'Double tap to open ${_getActionLabel(action.type.name)}',
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AyurezeTheme.spaceMd),
        child: InkWell(
          onTap: () => onActionTap?.call(action.type.name, action.params),
          borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceLg,
              vertical: AyurezeTheme.spaceSm,
            ),
            decoration: BoxDecoration(
              color: AstraConfig.enableLogging
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: _getActionIcon(action.type.name),
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: AyurezeTheme.textMd,
                  ),
                ),
                const SizedBox(width: 4),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 12,
                  color: Colors.green.shade700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
          top: AyurezeTheme.spaceXs,
          left: AyurezeTheme.spaceXs,
          right: AyurezeTheme.spaceXs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 14,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            message.errorMessage ?? 'Failed to send',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  List<List<dynamic>> _getActionIcon(String actionType) {
    switch (actionType) {
      case 'openPatient':
        return HugeIcons.strokeRoundedUser;
      case 'openPrescription':
        return HugeIcons.strokeRoundedFile01;
      case 'openPayment':
        return AppIcons.payment;
      case 'openNotifications':
        return AppIcons.notifications;
      case 'openChat':
        return AppIcons.chat;
      case 'openVideoCall':
        return HugeIcons.strokeRoundedVideo01;
      case 'openAppointment':
        return HugeIcons.strokeRoundedCalendar01;
      case 'openReminders':
        return HugeIcons.strokeRoundedAlarmClock;
      case 'openReport':
        return HugeIcons.strokeRoundedChartLine;
      case 'goBack':
        return HugeIcons.strokeRoundedArrowLeft01;
      default:
        return HugeIcons.strokeRoundedCursor02;
    }
  }

  String _getActionLabel(String actionType) {
    switch (actionType) {
      case 'openPatient':
        return 'View Patient';
      case 'openPrescription':
        return 'View Prescription';
      case 'openPayment':
        return 'Make Payment';
      case 'openNotifications':
        return 'View Notifications';
      case 'openChat':
        return 'Open Chat';
      case 'openVideoCall':
        return 'Start Video Call';
      case 'openAppointment':
        return 'View Appointment';
      case 'openReminders':
        return 'Set Reminder';
      case 'openReport':
        return 'View Report';
      case 'goBack':
        return 'Go Back';
      default:
        return 'Take Action';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
}

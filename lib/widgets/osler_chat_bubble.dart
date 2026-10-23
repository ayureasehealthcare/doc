import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:hugeicons/hugeicons.dart';

class OslerChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String? time;
  final bool isRead;
  final bool showAvatar;
  final Widget? avatar;

  const OslerChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.time,
    this.isRead = false,
    this.showAvatar = true,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceXs),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            avatar ??
                CircleAvatar(
                    radius: 16, backgroundColor: AyurezeTheme.healingGreen50),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AyurezeTheme.spaceLg,
                  vertical: AyurezeTheme.spaceMd),
              decoration: BoxDecoration(
                color: isMe
                    ? AyurezeTheme.healingGreen50
                    : AyurezeTheme.surfaceMuted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AyurezeTheme.radiusXl),
                  topRight: const Radius.circular(AyurezeTheme.radiusXl),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMe ? Colors.white : AyurezeTheme.textPrimary,
                          height: 1.4,
                        ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time!,
                          style: TextStyle(
                            fontSize: AyurezeTheme.textXs,
                            color: isMe
                                ? Colors.white70
                                : AyurezeTheme.textSecondary,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          HugeIcon(
                            icon: isRead
                                ? HugeIcons.strokeRoundedTick02
                                : HugeIcons.strokeRoundedTick01,
                            size: 14,
                            color: isRead
                                ? AyurezeTheme.connectivityBlue50
                                : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe && showAvatar) ...[
            const SizedBox(width: 8),
            avatar ??
                CircleAvatar(
                    radius: 16, backgroundColor: AyurezeTheme.surfaceMuted),
          ],
        ],
      ),
    );
  }
}

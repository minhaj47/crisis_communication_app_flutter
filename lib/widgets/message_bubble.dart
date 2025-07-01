import 'package:flutter/material.dart';
import 'package:new_project/models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromMe) ...[
            _buildAvatar(
              initials: message.senderId.substring(0, 2).toUpperCase(),
              backgroundColor: colorScheme.secondary,
              textColor: colorScheme.onSecondary,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromMe
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isFromMe ? 20 : 4),
                  bottomRight: Radius.circular(message.isFromMe ? 4 : 20),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!message.isFromMe) ...[
                    Text(
                      'User_${message.senderId.substring(0, 6)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isFromMe
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMessageFooter(theme, colorScheme),
                ],
              ),
            ),
          ),
          if (message.isFromMe) ...[
            const SizedBox(width: 12),
            _buildAvatar(
              initials: 'ME',
              backgroundColor: colorScheme.primaryContainer,
              textColor: colorScheme.onPrimaryContainer,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String initials,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMessageFooter(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: message.isFromMe
                ? colorScheme.onPrimary.withValues(alpha: 0.7)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        if (message.isFromMe) ...[
          const SizedBox(width: 6),
          _buildStatusIcon(colorScheme),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (message.status) {
      case MessageStatus.sending:
        iconData = Icons.schedule_outlined;
        iconColor = colorScheme.onPrimary.withValues(alpha: 0.7);
        break;
      case MessageStatus.sent:
        iconData = Icons.check_outlined;
        iconColor = colorScheme.onPrimary.withValues(alpha: 0.7);
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        iconColor = colorScheme.error;
        break;
      default:
        iconData = Icons.check_outlined;
        iconColor = colorScheme.onPrimary.withValues(alpha: 0.7);
    }

    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

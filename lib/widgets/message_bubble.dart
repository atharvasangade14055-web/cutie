import 'package:flutter/material.dart';

import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe
        ? const Color(0xFF8D7BFF)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.sender.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor.withOpacity(0.75),
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: textColor),
              ),
              if (isMe) ...[
                const SizedBox(height: 4),
                _buildReceiptIcon(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptIcon() {
    if (message.readAt != null) {
      // ✔✔ (red for read)
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 16, color: Colors.red),
          SizedBox(width: 4),
          Icon(Icons.done_all, size: 16, color: Colors.red),
        ],
      );
    } else if (message.deliveredAt != null) {
      // ✔✔ (black for delivered)
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 16, color: Colors.black),
          SizedBox(width: 4),
          Icon(Icons.done_all, size: 16, color: Colors.black),
        ],
      );
    } else {
      // ✔ (black for sent)
      return const Icon(Icons.done, size: 16, color: Colors.black);
    }
  }
}

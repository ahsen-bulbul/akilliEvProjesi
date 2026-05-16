import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isOwnMessage
        ? const Color(0xFF00D4AA)
        : const Color(0xFF21262D);
    final textColor = isOwnMessage ? const Color(0xFF06130F) : Colors.white;
    final timeColor = isOwnMessage
        ? const Color(0xAA06130F)
        : const Color(0xFF8B949E);

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBubbleWidth = constraints.maxWidth > 700
              ? 520.0
              : constraints.maxWidth * 0.78;

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                ),
                border: isOwnMessage
                    ? null
                    : Border.all(color: const Color(0xFF30363D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

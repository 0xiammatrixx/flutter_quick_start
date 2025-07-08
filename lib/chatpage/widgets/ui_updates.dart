import 'dart:ui';

import 'package:arbichat/chatpage/transaction/wallet_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.isMe,
    required this.message,
    required this.timestamp,
  });

  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$formattedHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.black : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? Colors.white : Colors.black,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          DateFormat('yMMMd').format(date),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ),
    );
  }
}



PreferredSizeWidget buildChatAppBar(String address, String avatarUrl) {
  return AppBar(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 1,
    titleSpacing: 0,
    title: Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(avatarUrl),
        ),
        const SizedBox(width: 10),
        Expanded(child: walletAddressPill(address)),
      ],
    ),
  );
}

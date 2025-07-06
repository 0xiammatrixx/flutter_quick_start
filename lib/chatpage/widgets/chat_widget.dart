import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:arbichat/chatpage/model/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatTiles chat;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.chat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(chat.avatarUrl), // Use the avatarUrl passed from Chat
      ),
      title: Text(
        chat.userProfile.name != 'Unknown Name'
            ? chat.userProfile.name
            : chat.userProfile.walletAddress,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.message.messageContent, // Directly use message data from the chat
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontWeight: chat.isSentByUser
              ? FontWeight.normal
              : FontWeight.bold,
        ),
      ),
      trailing: Text(DateFormat('HH:mm').format((chat.message.timestamp),
)
),
      onTap: onTap,
    );
  }
}


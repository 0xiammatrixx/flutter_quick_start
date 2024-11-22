// widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:w3aflutter/chatpage/model/message_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final messageTime = DateFormat('HH:mm').format(message.timestamp);
    bool isSentByUser = message.isSentByUser;
    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: IntrinsicWidth(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSentByUser ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  message.messageContent,
                  style: TextStyle(
                      color: isSentByUser ? Colors.white : Colors.black),
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  messageTime,
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

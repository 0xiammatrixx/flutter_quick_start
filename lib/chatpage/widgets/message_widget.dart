import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final EthereumAddress userWalletAddress; 

  const MessageBubble({
    super.key,
    required this.message,
    required this.userWalletAddress,
  });

  @override
  Widget build(BuildContext context) {
    final isSentByUser = message.sender.hex == userWalletAddress.hex;
    final messageTime = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.timestamp.toInt() * 1000),
    );

    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSentByUser ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.plaintext ?? '[Encrypted]', // Decrypted text or fallback
                style: TextStyle(
                  color: isSentByUser ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                messageTime,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

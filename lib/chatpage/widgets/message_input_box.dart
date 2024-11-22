import 'package:flutter/material.dart';
import 'package:w3aflutter/chatpage/transaction/tip_transaction.dart';
import 'package:w3aflutter/main.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoiceRecord;
  final String receiverAddress;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceRecord,
    required this.receiverAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: onVoiceRecord,
          ),
          IconButton(
            icon: Icon(Icons.attach_money),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  double tipAmount = 0.0;
                  return AlertDialog(
                    title: Text('Send a Tip'),
                    content: TextField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(hintText: 'Enter amount in ETH'),
                      onChanged: (value) {
                        tipAmount = double.tryParse(value) ?? 0.0;
                      },
                    ),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Send Tip'),
                        onPressed: () async {
                          if (tipAmount < 0.0001) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                              SnackBar(content: Text('Invalid tip amount: Must be at least 0.0001 ETH'))
                            );
                            print(
                                'Invalid tip amount: Must be at least 0.0001 ETH');
                            return;
                          }
                          Navigator.of(context).pop();
                          final recipientAddress = receiverAddress;
                          await sendTip(
                              tipAmount: tipAmount,
                              recipientAddress: recipientAddress,
                              context: context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

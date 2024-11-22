import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w3aflutter/chatpage/model/message_model.dart';
import 'package:w3aflutter/chatpage/widgets/message_input_box.dart';
import 'package:w3aflutter/chatpage/widgets/message_widget.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

class MessagingPage extends StatefulWidget {
  final UserProfile userProfile;

  MessagingPage({required this.userProfile});

  @override
  _MessagingPageState createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Initialize `_messageStream` to an empty stream
  late Stream<List<Message>> _messageStream = Stream.value([]);

  Future<String> _getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '0';

    final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    log("Account, ${address.hexEip55}");
    return address.hexEip55;
  }

  @override
  void initState() {
    super.initState();
    initMessagesStream();
  }

  void initMessagesStream() async {
    final senderAddress = await _getAddress();
    final receiverAddress = widget.userProfile.walletAddress;

    setState(() {
      _messageStream = _firestore
          .collection('users')
          .doc(senderAddress)
          .collection('messages')
          .doc(receiverAddress)
          .collection('chat')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList());
    });
  }

  void _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;

  final messageContent = _messageController.text.trim();
  final timestamp = DateTime.now();

  // Get sender and receiver addresses
  final senderAddress = await _getAddress(); 
  final receiverAddress = widget.userProfile.walletAddress;
  
  // Create the message object
  final messageForSender = Message(
    senderAddress: senderAddress,
    messageContent: messageContent,
    timestamp: timestamp,
    isSentByUser: true,
    isRead: true,
  );

  final messageForReceiver = Message(
    senderAddress: senderAddress,
    messageContent: messageContent,
    timestamp: timestamp,
    isSentByUser: false,
    isRead: false,
  );

  // 1. Store message in sender's sub-collection under receiver's document
  final senderDocRef = _firestore
      .collection('users')
      .doc(senderAddress)
      .collection('messages')
      .doc(receiverAddress);

    // Add a field if it doesn't already exist (to prevent virtual document issue)
  final senderDocSnapshot = await senderDocRef.get();
  if (!senderDocSnapshot.exists) {
    await senderDocRef.set({
      'hasChat': true, // Add a dummy field to avoid Firebase treating it as a virtual document
    }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
  }
  
  await senderDocRef.collection('chat').add(messageForSender.toFirestore());

  // 2. Store message in receiver's sub-collection under sender's document
  final receiverDocRef = _firestore
      .collection('users')
      .doc(receiverAddress)
      .collection('messages')
      .doc(senderAddress);

    // Add a field if it doesn't already exist (to prevent virtual document issue)
  final receiverDocSnapshot = await receiverDocRef.get();
  if (!receiverDocSnapshot.exists) {
    await receiverDocRef.set({
      'hasChat': true, // Add a dummy field to avoid Firebase treating it as a virtual document
    }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
  }

  await receiverDocRef.collection('chat').add(messageForReceiver.toFirestore());

  // Clear the message input field
  _messageController.clear();
}


  void _recordVoice() {
    print("Voice recording feature triggered");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userProfile.walletAddress,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (widget.userProfile.isVerified)
              Text(
                widget.userProfile.name,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
  stream: _messageStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text("No messages yet"));
    }
    final messages = snapshot.data!;
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  },
),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onVoiceRecord: _recordVoice,
            receiverAddress: widget.userProfile.walletAddress,
          ),
        ],
      ),
    );
  }
}

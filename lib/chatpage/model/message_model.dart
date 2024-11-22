// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String walletAddress;
  final String name;
  final double walletBalance;
  final int interactionScore;

  bool get isVerified => walletBalance > 100.0 && interactionScore > 50;

  UserProfile({
    required this.walletAddress,
    required this.name,
    required this.walletBalance,
    required this.interactionScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'walletAddress': walletAddress,
      'name': name,
      'walletBalance': walletBalance,
      'interactionScore': interactionScore
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      walletAddress: map['walletAddress'] ?? 'Unknown Address', 
      name: map['name'] ?? 'Unknown User',                     
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0, 
      interactionScore: map['interactionScore'] ?? 0,          
    );
  }
}




class Message {
  final String senderAddress;
  final String messageContent;
  final DateTime timestamp;
  final bool isSentByUser;
  final bool isRead;

  Message({
    required this.senderAddress,
    required this.messageContent,
    required this.timestamp,
    required this.isSentByUser,
    required this.isRead,
  });

   // Method to convert Firestore document to Message object
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      senderAddress: data['senderAddress'] ?? '',
      messageContent: data['messageContent'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isSentByUser: data['isSentByUser'] ?? false,
      isRead: data['isRead'] ?? false,
    );
  }

  // Method to convert Message object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderAddress': senderAddress,
      'messageContent': messageContent,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSentByUser': isSentByUser,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'senderAddress': senderAddress,
      'messageContent': messageContent,
      'timestamp': timestamp,
      'isSentByUser': isSentByUser,
    };
  }
}


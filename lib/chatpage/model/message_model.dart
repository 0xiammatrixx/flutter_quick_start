import 'package:web3dart/web3dart.dart';

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


class ChatMessage {
  final EthereumAddress sender;
  final EthereumAddress receiver;
  final String cid;
  final BigInt timestamp;
  final bool deleted;
  final String? plaintext; 

  ChatMessage({
    required this.sender,
    required this.receiver,
    required this.cid,
    required this.timestamp,
    required this.deleted,
    this.plaintext,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      sender: EthereumAddress.fromHex(map['sender']),
      receiver: EthereumAddress.fromHex(map['receiver']),
      cid: map['cid'],
      timestamp: BigInt.parse(map['timestamp'].toString()),
      deleted: map['deleted'],
    );
  }
}

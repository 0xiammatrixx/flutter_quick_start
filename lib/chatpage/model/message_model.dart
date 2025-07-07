import 'package:equatable/equatable.dart';
import 'package:web3dart/web3dart.dart';

class UserProfile {
  final String walletAddress;
  final String name;
  final double walletBalance;
  final int interactionScore;
  final String avatarUrl;

  bool get isVerified => walletBalance > 100.0 && interactionScore > 50;

  UserProfile({
    required this.walletAddress,
    required this.name,
    required this.walletBalance,
    required this.interactionScore,
    required this.avatarUrl,
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
      avatarUrl: map['avatarUrl'] ?? 'assets/profileplaceholder.png',          
    );
  }
}

class ChatMessage extends Equatable {
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

  ChatMessage copyWith({
    EthereumAddress? sender,
    EthereumAddress? receiver,
    String? cid,
    BigInt? timestamp,
    bool? deleted,
    String? plaintext,
  }) {
    return ChatMessage(
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      cid: cid ?? this.cid,
      timestamp: timestamp ?? this.timestamp,
      deleted: deleted ?? this.deleted,
      plaintext: plaintext ?? this.plaintext,
    );
  }
  @override
  List<Object?> get props => [sender, receiver, timestamp];
}

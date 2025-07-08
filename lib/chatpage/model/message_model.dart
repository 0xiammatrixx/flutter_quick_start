import 'package:web3dart/web3dart.dart';
import 'package:hive/hive.dart';

part 'message_model.g.dart';

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
      'interactionScore': interactionScore,
      'avatarUrl': avatarUrl,
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

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String senderHex;

  @HiveField(1)
  final String receiverHex;

  @HiveField(2)
  final String cid;

  @HiveField(3)
  final int timestamp; // stored as int for Hive

  @HiveField(4)
  final bool deleted;

  @HiveField(5)
  final String? plaintext;

  // ✅ This constructor is now Hive-compatible
  ChatMessage({
    required this.senderHex,
    required this.receiverHex,
    required this.cid,
    required this.timestamp,
    required this.deleted,
    this.plaintext,
  });

  // 🧠 Helper getters for developer ergonomics
  EthereumAddress get sender => EthereumAddress.fromHex(senderHex);
  EthereumAddress get receiver => EthereumAddress.fromHex(receiverHex);
  BigInt get timestampBigInt => BigInt.from(timestamp);

  // Optional: factory to construct from real types
  factory ChatMessage.fromTypes({
    required EthereumAddress sender,
    required EthereumAddress receiver,
    required String cid,
    required BigInt timestamp,
    required bool deleted,
    String? plaintext,
  }) {
    return ChatMessage(
      senderHex: sender.hex,
      receiverHex: receiver.hex,
      cid: cid,
      timestamp: timestamp.toInt(),
      deleted: deleted,
      plaintext: plaintext,
    );
  }

  Map<String, dynamic> toMap() => {
    'sender': senderHex,
    'receiver': receiverHex,
    'cid': cid,
    'timestamp': timestamp,
    'deleted': deleted,
    'plaintext': plaintext,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    int timestampInt;

  final ts = map['timestamp'];
  if (ts is BigInt) {
    timestampInt = ts.toInt();
  } else if (ts is int) {
    timestampInt = ts;
  } else if (ts is String) {
    timestampInt = int.parse(ts);
  } else {
    throw Exception('Invalid timestamp type: ${ts.runtimeType}');
  }

    return ChatMessage(
      senderHex: map['sender'],
      receiverHex: map['receiver'],
      cid: map['cid'],
      timestamp: timestampInt,
      deleted: map['deleted'],
      plaintext: map['plaintext'],
    );
  }

  ChatMessage copyWith({
    String? senderHex,
    String? receiverHex,
    String? cid,
    int? timestamp,
    bool? deleted,
    String? plaintext,
  }) {
    return ChatMessage(
      senderHex: senderHex ?? this.senderHex,
      receiverHex: receiverHex ?? this.receiverHex,
      cid: cid ?? this.cid,
      timestamp: timestamp ?? this.timestamp,
      deleted: deleted ?? this.deleted,
      plaintext: plaintext ?? this.plaintext,
    );
  }
}

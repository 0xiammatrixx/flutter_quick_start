import 'dart:math';
import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class TrustScoreService {
  static const double _alpha = 0.95; // decay
  static const int _maxScore = 100;

  // Main entry
  static Future<int> calculateTrustScore(String ownAddress) async {
    final box = await Hive.openBox<ChatMessage>('chat_messages_$ownAddress');
    final now = DateTime.now();

    // 1. Group received messages by sender
    Map<String, List<ChatMessage>> messagesFromOthers = {};
    for (final msg in box.values) {
      if (msg.receiverHex.toLowerCase() == ownAddress.toLowerCase()) {
        messagesFromOthers.putIfAbsent(msg.senderHex, () => []).add(msg);
      }
    }

    double score = 0;

    for (final entry in messagesFromOthers.entries) {
      final sender = entry.key;
      final messages = entry.value;

      for (final msg in messages) {
        final msgTime = DateTime.fromMillisecondsSinceEpoch(msg.timestamp.toInt() * 1000);
        final daysAgo = now.difference(msgTime).inDays.toDouble();
        final decay = pow(_alpha, daysAgo);

        // 2. Unique sender multiplier
        final uniqueSenderMultiplier = 1.2; // can scale with # of unique senders

        // 3. Sender rank (pull from Firestore if needed)
        final senderRankMultiplier = await _getRankMultiplier(sender); // e.g., 1.5 for Vanguard, 1.2 for Trusted

        // 4. Two-way bonus (did YOU ever message them back?)
        final replied = box.values.any((m) =>
            m.senderHex.toLowerCase() == ownAddress.toLowerCase() &&
            m.receiverHex.toLowerCase() == sender.toLowerCase());
        final twoWayMultiplier = replied ? 1.2 : 0.7;

        final messageScore = decay *
            uniqueSenderMultiplier *
            senderRankMultiplier *
            twoWayMultiplier;

        score += messageScore;
      }
    }

    return score.clamp(0, _maxScore).toInt();
  }

  // Rank-based weight (e.g., Vanguard = 1.5, Newbie = 1.0)
  static Future<double> _getRankMultiplier(String address) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(address).get();
      final rank = doc.data()?['rank'] ?? 'Newbie';
      switch (rank) {
        case 'Vanguard':
          return 1.5;
        case 'Elite':
          return 1.3;
        case 'Trusted':
          return 1.2;
        case 'Contributor':
          return 1.1;
        default:
          return 1.0;
      }
    } catch (_) {
      return 1.0;
    }
  }
}

import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:arbichat/chatpage/model/minimal_message.dart';

class ChatTiles {
  final UserProfile userProfile;
  final Message message;
  final String avatarUrl;
  final DateTime timestamp;
  final bool isSentByUser;

  ChatTiles({
    required this.userProfile,
    required this.message,
    required this.avatarUrl,
    required this.timestamp,
    required this.isSentByUser,
  });

  Map<String, dynamic> toMap(){
    return {
      'userProfile': userProfile,
    };
  }
}
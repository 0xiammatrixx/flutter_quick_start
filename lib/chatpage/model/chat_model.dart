import 'package:w3aflutter/chatpage/model/message_model.dart';

class Chat {
  final UserProfile userProfile;
  final Message message;
  final String avatarUrl;
  final bool isUnread;
  final bool isRead;
  final int unreadCount;
  

  Chat({
    required this.userProfile,
    required this.message,
    required this.avatarUrl,
    required this.isUnread,
    required this.isRead,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap(){
    return {
      'userProfile': userProfile,

    };
  }
}
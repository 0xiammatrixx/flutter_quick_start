class Message {
  final String senderAddress;
  final String messageContent;
  final DateTime timestamp;
  final bool isSentByUser;

  Message({
    required this.senderAddress,
    required this.messageContent,
    required this.timestamp,
    required this.isSentByUser,
  });
}

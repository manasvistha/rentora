class MessageEntity {
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime timestamp;

  const MessageEntity({
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.timestamp,
  });
}

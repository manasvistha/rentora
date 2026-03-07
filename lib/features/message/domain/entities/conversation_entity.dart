import 'message_entity.dart';

class ConversationParticipantEntity {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  const ConversationParticipantEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}

class ConversationEntity {
  final String id;
  final List<ConversationParticipantEntity> participants;
  final String? bookingId;
  final List<MessageEntity> messages;
  final String lastMessage;
  final DateTime? lastMessageTime;

  const ConversationEntity({
    required this.id,
    required this.participants,
    required this.messages,
    required this.lastMessage,
    this.lastMessageTime,
    this.bookingId,
  });
}

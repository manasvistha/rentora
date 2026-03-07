import 'package:dartz/dartz.dart';
import 'package:rentora/core/error/failures.dart';
import '../entities/conversation_entity.dart';

abstract class MessageRepository {
  Future<Either<Failure, List<ConversationEntity>>> getConversations();
  Future<Either<Failure, ConversationEntity>> getConversation(String id);
  Future<Either<Failure, ConversationEntity>> sendMessage({
    required String conversationId,
    required String content,
  });
  Future<Either<Failure, ConversationEntity>> createConversation({
    required List<String> participants,
  });
}

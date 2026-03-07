import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/message/data/repositories/message_repository_impl.dart';
import '../entities/conversation_entity.dart';
import '../repositories/message_repository.dart';

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repo = ref.read(messageRepositoryProvider);
  return SendMessageUseCase(repo);
});

class SendMessageUseCase {
  final MessageRepository _repo;
  SendMessageUseCase(this._repo);

  Future<Either<Failure, ConversationEntity>> execute({
    required String conversationId,
    required String content,
  }) {
    return _repo.sendMessage(conversationId: conversationId, content: content);
  }
}

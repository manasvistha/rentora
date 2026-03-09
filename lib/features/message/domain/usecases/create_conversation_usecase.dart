import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/message/data/repositories/message_repository_impl.dart';
import '../entities/conversation_entity.dart';
import '../repositories/message_repository.dart';

final createConversationUseCaseProvider = Provider<CreateConversationUseCase>((
  ref,
) {
  final repo = ref.read(messageRepositoryProvider);
  return CreateConversationUseCase(repo);
});

class CreateConversationUseCase {
  final MessageRepository _repo;
  CreateConversationUseCase(this._repo);

  Future<Either<Failure, ConversationEntity>> execute({
    required List<String> participants,
  }) {
    return _repo.createConversation(participants: participants);
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/message/data/repositories/message_repository_impl.dart';
import '../entities/conversation_entity.dart';
import '../repositories/message_repository.dart';

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((
  ref,
) {
  final repo = ref.read(messageRepositoryProvider);
  return GetConversationsUseCase(repo);
});

class GetConversationsUseCase {
  final MessageRepository _repo;
  GetConversationsUseCase(this._repo);

  Future<Either<Failure, List<ConversationEntity>>> execute() {
    return _repo.getConversations();
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/message/data/repositories/message_repository_impl.dart';
import 'package:rentora/features/message/domain/repositories/message_repository.dart';

final deleteConversationUseCaseProvider = Provider<DeleteConversationUseCase>((
  ref,
) {
  final repo = ref.read(messageRepositoryProvider);
  return DeleteConversationUseCase(repo);
});

class DeleteConversationUseCase {
  final MessageRepository _repo;

  DeleteConversationUseCase(this._repo);

  Future<Either<Failure, bool>> execute(String conversationId) {
    return _repo.deleteConversation(conversationId);
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/message/data/repositories/message_repository_impl.dart';
import '../entities/conversation_entity.dart';
import '../repositories/message_repository.dart';

final getConversationUseCaseProvider = Provider<GetConversationUseCase>((ref) {
  final repo = ref.read(messageRepositoryProvider);
  return GetConversationUseCase(repo);
});

class GetConversationUseCase {
  final MessageRepository _repo;
  GetConversationUseCase(this._repo);

  Future<Either<Failure, ConversationEntity>> execute(String id) {
    return _repo.getConversation(id);
  }
}

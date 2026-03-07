import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_conversation_usecase.dart';

final conversationsProvider =
    FutureProvider.autoDispose<Either<Failure, List<ConversationEntity>>>((
      ref,
    ) async {
      final usecase = ref.read(getConversationsUseCaseProvider);
      return usecase.execute();
    });

final conversationByIdProvider = FutureProvider.autoDispose
    .family<Either<Failure, ConversationEntity>, String>((ref, id) async {
      final usecase = ref.read(getConversationUseCaseProvider);
      return usecase.execute(id);
    });

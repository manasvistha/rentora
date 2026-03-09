import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/core/error/failures.dart';
import 'package:rentora/features/message/domain/entities/conversation_entity.dart';
import 'package:rentora/features/message/domain/entities/message_entity.dart';
import 'package:rentora/features/message/domain/repositories/message_repository.dart';
import '../datasources/remote/message_remote_datasource.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final remote = ref.read(messageRemoteDataSourceProvider);
  return MessageRepositoryImpl(remote);
});

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remote;
  MessageRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations() async {
    try {
      final rawList = await _remote.getConversations();
      final list = rawList.map(_parseConversation).toList();
      return right(list);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity>> getConversation(String id) async {
    try {
      final raw = await _remote.getConversation(id);
      return right(_parseConversation(raw));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteConversation(String id) async {
    try {
      await _remote.deleteConversation(id);
      return right(true);
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final raw = await _remote.sendMessage(
        conversationId: conversationId,
        content: content,
      );
      return right(_parseConversation(raw));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity>> createConversation({
    required List<String> participants,
  }) async {
    try {
      final raw = await _remote.createConversation(participants: participants);
      return right(_parseConversation(raw));
    } catch (e) {
      return left(ApiFailure(message: e.toString()));
    }
  }

  ConversationEntity _parseConversation(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    final participantsRaw = (map['participants'] as List?) ?? const [];
    final participants = participantsRaw.map((p) {
      final pm = (p is Map) ? p.cast<String, dynamic>() : <String, dynamic>{};
      final id = (pm['_id'] ?? pm['id'] ?? '').toString();
      final name = (pm['name'] ?? '').toString();
      final email = (pm['email'] ?? '').toString();
      final avatarRaw =
          pm['profilePicture'] ??
          pm['profileImage'] ??
          pm['profile_image'] ??
          pm['profilePic'] ??
          pm['avatar'] ??
          pm['image'] ??
          pm['photoUrl'] ??
          pm['photoURL'];
      final avatarUrl = _resolveAvatarUrl(avatarRaw?.toString());
      return ConversationParticipantEntity(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );
    }).toList();

    final messagesRaw = (map['messages'] as List?) ?? const [];
    final messages = messagesRaw.map((m) {
      final mm = (m is Map) ? m.cast<String, dynamic>() : <String, dynamic>{};
      final senderRaw = mm['sender'];
      String senderId = '';
      String senderName = '';
      String? senderAvatarUrl;
      if (senderRaw is Map) {
        senderId = (senderRaw['_id'] ?? senderRaw['id'] ?? '').toString();
        senderName = (senderRaw['name'] ?? senderRaw['email'] ?? '').toString();
        final senderAvatarRaw =
            senderRaw['profilePicture'] ??
            senderRaw['profileImage'] ??
            senderRaw['profile_image'] ??
            senderRaw['profilePic'] ??
            senderRaw['avatar'] ??
            senderRaw['image'] ??
            senderRaw['photoUrl'] ??
            senderRaw['photoURL'];
        senderAvatarUrl = _resolveAvatarUrl(senderAvatarRaw?.toString());
      } else {
        senderId = (senderRaw ?? '').toString();
      }
      final content = (mm['content'] ?? '').toString();
      final tsRaw = (mm['timestamp'] ?? '').toString();
      final ts = DateTime.tryParse(tsRaw) ?? DateTime.now();
      return MessageEntity(
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        content: content,
        timestamp: ts,
      );
    }).toList();

    final id = (map['_id'] ?? map['id'] ?? '').toString();
    final bookingId = map['booking'] == null ? null : map['booking'].toString();
    final lastMessage = (map['lastMessage'] ?? '').toString();
    final lastTimeRaw = map['lastMessageTime']?.toString();
    final lastTime = lastTimeRaw == null
        ? null
        : DateTime.tryParse(lastTimeRaw);

    return ConversationEntity(
      id: id,
      participants: participants,
      messages: messages,
      bookingId: bookingId,
      lastMessage: lastMessage,
      lastMessageTime: lastTime,
    );
  }

  String? _resolveAvatarUrl(String? rawPath) {
    if (rawPath == null) return null;
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final host = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (trimmed.startsWith('/')) return '$host$trimmed';
    return '$host/public/profile-pictures/$trimmed';
  }
}

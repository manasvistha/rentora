import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/message_providers.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  Timer? _poll;
  static const _dashboardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2F9E9A), Color(0xFF6CCBC7), Color(0xFFD8F3F2)],
  );

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Conversations'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: _dashboardGradient),
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, st) => Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            data: (either) => either.fold(
              (failure) => Center(
                child: Text(
                  failure.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: const Color(0xFF2F9E9A),
                  backgroundColor: Colors.white,
                  onRefresh: () async => ref.invalidate(conversationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _ConversationTile(item: item);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationEntity item;
  const _ConversationTile({required this.item});

  ConversationParticipantEntity _otherParticipant(String currentUserId) {
    final other = item.participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => item.participants.isNotEmpty
          ? item.participants.first
          : const ConversationParticipantEntity(
              id: '',
              name: 'User',
              email: '',
            ),
    );
    return other;
  }

  String _displayName(ConversationParticipantEntity other) {
    if (other.name.trim().isNotEmpty) return other.name;
    if (other.email.trim().isNotEmpty) return other.email;
    return 'User';
  }

  Widget _avatar({required String name, String? imageUrl}) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFD1FAE5),
      foregroundImage: (imageUrl != null && imageUrl.trim().isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Color(0xFF065F46),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, String?>>(
      future: ref.read(userSessionServiceProvider).getUserSession(),
      builder: (context, snap) {
        final currentId = snap.data?['id'] ?? '';
        final other = _otherParticipant(currentId);
        final name = _displayName(other);
        final last = item.lastMessage.isNotEmpty
            ? item.lastMessage
            : (item.messages.isNotEmpty
                  ? item.messages.last.content
                  : 'No messages yet');
        final time =
            item.lastMessageTime ??
            (item.messages.isNotEmpty ? item.messages.last.timestamp : null);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFBFE8D8)),
          ),
          color: const Color(0xFFFCFFFD),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(conversationId: item.id),
                ),
              );
            },
            leading: _avatar(name: name, imageUrl: other.avatarUrl),
            title: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF0F3D33),
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF3E6B5D)),
            ),
            trailing: Text(
              time == null
                  ? ''
                  : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF3E6B5D)),
            ),
          ),
        );
      },
    );
  }
}

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
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(conversationsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your recent conversations with owners and tenants.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
            async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              error: (e, st) => _MessageErrorCard(
                message: e.toString(),
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
              data: (either) => either.fold(
                (failure) => _MessageErrorCard(
                  message: failure.message,
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
                (list) {
                  if (list.isEmpty) {
                    return const _MessageEmptyCard(
                      message:
                          'No conversations yet. Start by opening a property and chatting with the owner.',
                    );
                  }

                  return Column(
                    children: list
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ConversationTile(item: item),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessageErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD5D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9B2C2C),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MessageEmptyCard extends StatelessWidget {
  final String message;

  const _MessageEmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFECE9)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF5E7A7E), fontSize: 13),
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF3E6B5D), fontSize: 13),
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

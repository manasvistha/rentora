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
        body: Container(
          decoration: const BoxDecoration(gradient: _dashboardGradient),
          child: RefreshIndicator(
            color: const Color(0xFF2F9E9A),
            backgroundColor: Colors.white,
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              children: [
                const Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chats with owners and renters.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (e, st) => _MessageStateCard(message: e.toString()),
                  data: (either) => either.fold(
                    (failure) => _MessageStateCard(message: failure.message),
                    (list) {
                      if (list.isEmpty) {
                        return const _MessageStateCard(
                          message: 'No conversations yet',
                        );
                      }
                      return Column(
                        children: list
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
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
      radius: 28,
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

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversationId: item.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _avatar(name: name, imageUrl: other.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF103033),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5E7A7E),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time == null
                      ? ''
                      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3E6B5D),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageStateCard extends StatelessWidget {
  final String message;

  const _MessageStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF23474A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../providers/message_providers.dart';

enum _ChatMenuAction { deleteChat }

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  bool _deletingConversation = false;
  Timer? _poll;
  static const _dashboardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2F9E9A), Color(0xFF6CCBC7), Color(0xFFD8F3F2)],
  );

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      ref.invalidate(conversationByIdProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  ConversationParticipantEntity? _otherParticipant(
    ConversationEntity conversation,
    String currentUserId,
  ) {
    if (conversation.participants.isEmpty) return null;
    return conversation.participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => conversation.participants.first,
    );
  }

  Widget _avatar({
    required String label,
    String? imageUrl,
    double radius = 16,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD1FAE5),
      foregroundImage: (imageUrl != null && imageUrl.trim().isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Color(0xFF065F46),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final usecase = ref.read(sendMessageUseCaseProvider);
    final result = await usecase.execute(
      conversationId: widget.conversationId,
      content: text,
    );

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        _controller.clear();
        ref.invalidate(conversationByIdProvider(widget.conversationId));
        ref.invalidate(conversationsProvider);
      },
    );

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _onMenuSelected(_ChatMenuAction action) async {
    if (action != _ChatMenuAction.deleteChat) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deletingConversation = true);
    final result = await ref
        .read(deleteConversationUseCaseProvider)
        .execute(widget.conversationId);

    if (!mounted) return;
    setState(() => _deletingConversation = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        ref.invalidate(conversationsProvider);
        ref.invalidate(conversationByIdProvider(widget.conversationId));
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationByIdProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            (conversation) => FutureBuilder<Map<String, String?>>(
              future: ref.read(userSessionServiceProvider).getUserSession(),
              builder: (context, snap) {
                final currentId = snap.data?['id'] ?? '';
                final other = _otherParticipant(conversation, currentId);
                final otherName = (other?.name.trim().isNotEmpty ?? false)
                    ? other!.name
                    : ((other?.email.trim().isNotEmpty ?? false)
                          ? other!.email
                          : 'Chat');
                final messages = conversation.messages;

                return Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            bottom: BorderSide(color: Colors.white30),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                              ),
                            ),
                            _avatar(
                              label: otherName,
                              imageUrl: other?.avatarUrl,
                              radius: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                otherName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_deletingConversation)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              PopupMenuButton<_ChatMenuAction>(
                                onSelected: _onMenuSelected,
                                color: Colors.white,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                itemBuilder: (context) => const [
                                  PopupMenuItem<_ChatMenuAction>(
                                    value: _ChatMenuAction.deleteChat,
                                    child: Text('Delete Chat'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final mine = msg.senderId == currentId;
                                final bubbleColor = mine
                                    ? const Color(0xFF0F766E)
                                    : Colors.white;
                                final textColor = mine
                                    ? Colors.white
                                    : const Color(0xFF0F3D33);

                                return Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!mine)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: _avatar(
                                            label: msg.senderName.isNotEmpty
                                                ? msg.senderName
                                                : otherName,
                                            imageUrl:
                                                msg.senderAvatarUrl ??
                                                other?.avatarUrl,
                                            radius: 14,
                                          ),
                                        ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bubbleColor,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(
                                              mine ? 16 : 4,
                                            ),
                                            bottomRight: Radius.circular(
                                              mine ? 4 : 16,
                                            ),
                                          ),
                                          border: mine
                                              ? null
                                              : Border.all(
                                                  color: const Color(
                                                    0xFFBFE8D8,
                                                  ),
                                                ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (!mine &&
                                                msg.senderName.isNotEmpty)
                                              Text(
                                                msg.senderName,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF3E6B5D),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            Text(
                                              msg.content,
                                              style: TextStyle(
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: mine
                                                    ? const Color(0xFFD1FAE5)
                                                    : const Color(0xFF6B8D82),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (mine)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: _avatar(
                                            label: msg.senderName.isNotEmpty
                                                ? msg.senderName
                                                : 'Me',
                                            imageUrl: msg.senderAvatarUrl,
                                            radius: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            top: BorderSide(color: Colors.white30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF6B8D82),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFBFE8D8),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFBFE8D8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              backgroundColor: const Color(0xFF10B981),
                              child: IconButton(
                                onPressed: _sending ? null : _send,
                                icon: _sending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

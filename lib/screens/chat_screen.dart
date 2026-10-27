import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name, required this.uid});

  final String name;
  final String uid;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _firestore = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  late final Future<String> _conversationId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = _currentUser?.uid;
    _conversationId = currentUserId == null
        ? Future<String>.error(StateError('Sign in to start a conversation.'))
        : _firestore.ensureConversation(
            currentUserId: currentUserId,
            otherUserId: widget.uid,
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String conversationId) async {
    final text = _controller.text.trim();
    final senderId = _currentUser?.uid;
    if (text.isEmpty || senderId == null || _sending) return;
    if (text.length > 2000) {
      _showMessage('Messages must be 2,000 characters or less.');
      return;
    }

    setState(() => _sending = true);
    try {
      await _firestore.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: text,
      );
      _controller.clear();
    } catch (_) {
      _showMessage('Message could not be sent. Check your connection.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<String>(
        future: _conversationId,
        builder: (context, conversationSnapshot) {
          if (conversationSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (conversationSnapshot.hasError ||
              conversationSnapshot.data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('This conversation could not be opened.'),
              ),
            );
          }

          final conversationId = conversationSnapshot.data!;
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _firestore.watchMessages(conversationId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Messages could not be loaded.'),
                      );
                    }

                    final messages = snapshot.data ?? const <MessageModel>[];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Start the conversation with a message.'),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - index - 1];
                        final isMine = message.senderId == _currentUser?.uid;
                        return _MessageBubble(
                          message: message,
                          isMine: isMine,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 2000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Write a message',
                            counterText: '',
                          ),
                          onSubmitted: (_) => _send(conversationId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed:
                            _sending ? null : () => _send(conversationId),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? colors.primaryContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(message.text),
            ),
            if (message.createdAt == null)
              Text(
                'Sending…',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}

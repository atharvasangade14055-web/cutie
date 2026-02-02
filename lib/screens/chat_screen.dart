import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../services/firebase_service.dart';
import '../widgets/message_bubble.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  StreamSubscription<List<Message>>? _messageSubscription;
  List<Message> _messages = const [];
  bool _isSending = false;
  String? _currentUser;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as read when the chat screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markOtherMessagesRead();
    });
  }

  void _bootstrap() {
    final user = FirebaseService.instance.getCurrentUser();
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
      });
      return;
    }

    setState(() => _currentUser = user);

    _messageSubscription = FirebaseService.instance.getMessagesStream().listen(
      (messages) {
        setState(() => _messages = messages);
        _scrollToBottom();
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load messages. Retry shortly.')),
        );
      },
    );
  }

  void _markOtherMessagesRead() {
    final currentUser = _currentUser;
    if (currentUser == null || !mounted) return;

    FirebaseService.instance.markUnreadMessagesAsRead(currentUser);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    if (_currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      setState(() => _sendError = 'Type a message first');
      return;
    }

    setState(() {
      _sendError = null;
      _isSending = true;
    });

    try {
      await FirebaseService.instance.sendMessage(text, _currentUser!);
      _messageController.clear();
      _focusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send. Check connection.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseService.instance.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF9F1FF), Color(0xFFFDF7F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _messages.isEmpty
                    ? const Center(child: Text('Say hi to start chatting!'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.sender == _currentUser;
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: theme.scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_sendError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _sendError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Type your message',
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSending ? null : _handleSend,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(14),
                          shape: const CircleBorder(),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

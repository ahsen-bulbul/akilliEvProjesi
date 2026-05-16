import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/datasources/api_service.dart';
import '../../data/models/message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input_field.dart';

class ChatScreen extends StatefulWidget {
  final String? targetUserId;
  final String? title;

  const ChatScreen({super.key, this.targetUserId, this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Message> _messages = const [];
  String? _currentUserId;
  String? _error;
  bool _loading = true;
  bool _sending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _bootstrapChat();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(widget.title ?? 'Destek / Admin Paneli'),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          MessageInputField(
            controller: _messageController,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFB4B4)),
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Henuz mesaj yok.',
          style: TextStyle(color: Color(0xFF8B949E)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return ChatBubble(
          message: message,
          isOwnMessage: message.senderId == _currentUserId,
        );
      },
    );
  }

  Future<void> _bootstrapChat() async {
    try {
      final user = await ApiService.getMe();
      if (!mounted) {
        return;
      }
      setState(() => _currentUserId = user.id);
      await _loadMessages(scrollToBottom: true);
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _loadMessages(),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMessages({bool scrollToBottom = false}) async {
    try {
      final messages = await ApiService.getChatMessages(
        targetUserId: widget.targetUserId,
      );
      if (!mounted) {
        return;
      }

      final shouldScroll =
          scrollToBottom ||
          messages.length != _messages.length ||
          (messages.isNotEmpty &&
              _messages.isNotEmpty &&
              messages.last.id != _messages.last.id);

      setState(() {
        _messages = messages;
        _error = null;
        _loading = false;
      });

      if (shouldScroll) {
        _scrollToLatestMessage();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      await ApiService.sendChatMessage(
        text: text,
        targetUserId: widget.targetUserId,
      );
      _messageController.clear();
      await _loadMessages(scrollToBottom: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // Yeni mesaj eklendikten sonra listenin en altina yumuşak kaydirma yapar.
  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

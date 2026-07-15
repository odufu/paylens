import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/features/chatbot/presentation/state/chat_provider.dart';
import 'package:mspay/features/chatbot/data/models/chat_message_model.dart';

class ChatbotScreen extends StatefulWidget {
  final String? initialText;
  const ChatbotScreen({super.key, this.initialText});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // If we have an initial query, process it after first frame loads
    if (widget.initialText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).sendMessage(widget.initialText!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(ChatProvider chatProvider) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      chatProvider.sendMessage(text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _handleQuickReply(ChatProvider chatProvider, String replyText) {
    chatProvider.sendMessage(replyText);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    // Scroll to bottom when messages list size changes or bot is typing
    if (chatProvider.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              // ignore: deprecated_member_use
              backgroundColor: AppColors.accentLime.withValues(alpha: 0.2),
              child: const Icon(
                LucideIcons.bot,
                color: AppColors.accentLime,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pay Lenses Customer Care',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online • AI Assistant',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textLightGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: 'Reset Conversation',
            onPressed: () {
              chatProvider.clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support session restarted.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // MESSAGES PANEL
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final msg = chatProvider.messages[index];
                return _buildMessageBubble(msg, chatProvider);
              },
            ),
          ),

          // TYPING INDICATOR
          if (chatProvider.isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(
                      LucideIcons.bot,
                      size: 14,
                      color: AppColors.primaryForest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Assistant is typing...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _handleSend(chatProvider),
                      decoration: InputDecoration(
                        hintText: 'Type your support message...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _handleSend(chatProvider),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.sendHorizontal,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, ChatProvider chatProvider) {
    final bool isUser = msg.isUser;

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryForest.withValues(alpha: 0.08),
                child: const Icon(
                  LucideIcons.bot,
                  size: 16,
                  color: AppColors.primaryForest,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primaryForest
                      : const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppColors.textDark,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Time footer
        Padding(
          padding: EdgeInsets.only(
            left: isUser ? 0 : 40.0,
            right: isUser ? 8.0 : 0,
            bottom: 8.0,
          ),
          child: Text(
            DateFormat('hh:mm a').format(msg.timestamp),
            style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
          ),
        ),

        // Quick Reply Suggestions (if any)
        if (!isUser &&
            msg.quickReplies != null &&
            msg.quickReplies!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 36.0, bottom: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: msg.quickReplies!.map((reply) {
                return GestureDetector(
                  onTap: () => _handleQuickReply(chatProvider, reply),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryForest.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      reply,
                      style: const TextStyle(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

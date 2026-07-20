import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/features/chatbot/data/models/chat_message_model.dart';
import 'package:mspay/features/chatbot/domain/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final _uuid = const Uuid();
  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;

  bool _isAgentMode = false;
  String? _activeTicketId;
  StreamSubscription? _streamSub;
  StreamSubscription? _ticketUnreadSub;
  bool _hasUnreadMessages = false;

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isAgentMode => _isAgentMode;
  String? get activeTicketId => _activeTicketId;
  bool get hasUnreadMessages => _hasUnreadMessages;

  ChatProvider(this._chatRepository) {
    // Reset conversation when user changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      disconnectLiveAgent();
      startUnreadListener();
    });
    startUnreadListener();
  }

  String _getUserName() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      return user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Darlington';
    }
    return 'Darlington';
  }

  /// Sends a message from the user directly to the live admin support chat
  Future<void> sendMessage(String text) async {
    await sendLiveMessage(text);
  }

  void startUnreadListener() {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) {
      _hasUnreadMessages = false;
      notifyListeners();
      return;
    }

    _ticketUnreadSub?.cancel();
    _ticketUnreadSub = SupabaseService.client
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .eq('profile_id', uid)
        .listen((data) {
          if (data.isNotEmpty) {
            final hasUnread = data.any((row) => (row['user_unread'] as bool? ?? false) && row['status'] == 'escalated');
            if (_hasUnreadMessages != hasUnread) {
              _hasUnreadMessages = hasUnread;
              notifyListeners();
            }
          }
        });
  }

  Future<void> connectToLiveAgent() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;

    _isTyping = true;
    notifyListeners();

    try {
      // 1. Check for existing escalated Live Chat ticket
      final existing = await SupabaseService.client
          .from('support_tickets')
          .select()
          .eq('profile_id', uid)
          .eq('title', 'Live Support Chat')
          .eq('status', 'escalated')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      String ticketId;
      if (existing != null && existing['id'] != null) {
        ticketId = existing['id'];
      } else {
        ticketId = _generateTicketId();
        await SupabaseService.client.from('support_tickets').insert({
          'id': ticketId,
          'profile_id': uid,
          'title': 'Live Support Chat',
          'description': 'Real-time conversation with customer',
          'status': 'escalated',
          'admin_unread': true,
          'user_unread': false,
        });
      }

      _activeTicketId = ticketId;
      _isAgentMode = true;

      // 2. Fetch existing messages
      final msgRes = await SupabaseService.client
          .from('support_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      _messages.clear();
      
      final userName = _getUserName();
      _messages.add(
        ChatMessageModel(
          id: _uuid.v4(),
          text: 'Hello $userName! Welcome to Pay Lenses Live Support. Please type your message below and an admin will respond to you shortly.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      if (msgRes != null) {
        final list = List<Map<String, dynamic>>.from(msgRes);
        for (final m in list) {
          _messages.add(
            ChatMessageModel(
              id: m['id'] ?? _uuid.v4(),
              text: m['message'] ?? '',
              isUser: !(m['is_admin'] as bool),
              timestamp: m['created_at'] != null ? DateTime.parse(m['created_at'].toString()) : DateTime.now(),
            ),
          );
        }
      }

      // Mark user unread to false
      await SupabaseService.client
          .from('support_tickets')
          .update({'user_unread': false})
          .eq('id', ticketId);

      _hasUnreadMessages = false;

      // 3. Subscribe to real-time updates
      _streamSub?.cancel();
      _streamSub = SupabaseService.client
          .from('support_messages')
          .stream(primaryKey: ['id'])
          .eq('ticket_id', ticketId)
          .listen((data) async {
            if (data.isNotEmpty) {
              bool newAdminMessageReceived = false;
              for (final row in data) {
                final msgId = row['id'];
                final text = row['message'] ?? '';
                final isAdminMsg = row['is_admin'] as bool;
                final createdAt = row['created_at'] != null ? DateTime.parse(row['created_at'].toString()) : DateTime.now();

                final exists = _messages.any((m) => m.id == msgId);
                if (!exists) {
                  _messages.add(
                    ChatMessageModel(
                      id: msgId,
                      text: text,
                      isUser: !isAdminMsg,
                      timestamp: createdAt,
                    ),
                  );
                  if (isAdminMsg) {
                    newAdminMessageReceived = true;
                  }
                }
              }

              if (newAdminMessageReceived) {
                await SupabaseService.client
                    .from('support_tickets')
                    .update({'user_unread': false})
                    .eq('id', ticketId);
              }
              
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              notifyListeners();
            }
          });

    } catch (e) {
      debugPrint('Failed to initialize live agent chat: $e. Falling back to local bot.');
      _isAgentMode = false;
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> sendLiveMessage(String text) async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null || _activeTicketId == null) return;

    final localMsgId = _uuid.v4();
    _messages.add(
      ChatMessageModel(
        id: localMsgId,
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      await SupabaseService.client.from('support_messages').insert({
        'id': localMsgId,
        'ticket_id': _activeTicketId,
        'sender_id': uid,
        'message': text,
        'is_admin': false,
      });

      await SupabaseService.client.from('support_tickets').update({
        'admin_unread': true,
        'user_unread': false,
      }).eq('id', _activeTicketId!);
    } catch (e) {
      debugPrint('Error sending live message to Supabase: $e');
    }
  }

  void disconnectLiveAgent() {
    _streamSub?.cancel();
    _streamSub = null;
    _ticketUnreadSub?.cancel();
    _ticketUnreadSub = null;
    _isAgentMode = false;
    _activeTicketId = null;
    clearChat();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  String _generateTicketId() {
    final rand = Random().nextInt(89999) + 10000;
    return '#TKT-$rand';
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _ticketUnreadSub?.cancel();
    super.dispose();
  }
}

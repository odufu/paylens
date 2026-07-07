import 'dart:math';
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

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;

  ChatProvider(this._chatRepository) {
    _sendWelcomeMessage();
    // Reset conversation when user changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      clearChat();
    });
  }

  String _getUserName() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      return user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Darlington';
    }
    return 'Darlington';
  }

  /// Sends the initial greeting from the chatbot
  void _sendWelcomeMessage() {
    final userName = _getUserName();
    _messages.add(
      ChatMessageModel(
        id: _uuid.v4(),
        text: 'Hello $userName! Welcome to Pay Lenses support. I am your Customer Care assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: [
          'Verify Transaction Status',
          'Report Technical Issue',
          'Paystack Info',
          'VTPass Utilities Info',
          'Talk to an Agent'
        ],
      ),
    );
  }

  /// Sends a message from the user and triggers AI/scripted response
  Future<void> sendMessage(String text) async {
    _messages.add(
      ChatMessageModel(
        id: _uuid.v4(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    // Trigger typing effect and simulated reply
    _isTyping = true;
    notifyListeners();
    
    // We introduce a minimum delay of 600ms for natural conversational pacing
    final startTime = DateTime.now();

    try {
      // Pass history excluding the newly added user message
      final history = _messages.sublist(0, _messages.length - 1);
      final reply = await _chatRepository.getReply(text, history);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 600) {
        await Future.delayed(Duration(milliseconds: 600 - elapsed));
      }

      _isTyping = false;
      _messages.add(
        ChatMessageModel(
          id: _uuid.v4(),
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: [
            'Verify Transaction Status',
            'Report Technical Issue',
            'Paystack Info',
            'Talk to an Agent',
            'Back to Main Menu'
          ],
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Gemini Chatbot failed: $e. Falling back to rule-based responses.');
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 600) {
        await Future.delayed(Duration(milliseconds: 600 - elapsed));
      }
      _isTyping = false;
      await _processFallbackResponse(text);
    }
  }

  /// Handles bot decision tree based on message and logs to Supabase
  Future<void> _processFallbackResponse(String userText) async {
    String replyText = '';
    List<String>? replies;
    final userName = _getUserName();
    final query = userText.toLowerCase();

    if (query.contains('verify transaction') || query.contains('status')) {
      replyText = 'Which service provider was the transaction made through? Or choose from your options below:';
      replies = ['Paystack Transfer', 'VTPass Utilities', 'Back to Main Menu'];
    } else if (query == 'paystack transfer' || query == 'vtpass utilities') {
      replyText = 'Understood. Please provide the 10-digit reference ID or describe the transaction (e.g. DSTV, Funding). You can also report it directly via the "Report Technical Issue" menu.';
      replies = ['Report Technical Issue', 'Back to Main Menu'];
    } else if (query.contains('technical issue') || query.contains('report')) {
      replyText = 'We apologize for the inconvenience. To escalate this to engineering, please select which transaction has issues, or type details:';
      replies = [
        'Report DSTV Premium (#1)',
        'Report Wallet Funding (#2)',
        'Report MTN Airtime (#3)',
        'Something else'
      ];
    } else if (query.contains('dstv') || query.contains('report dstv premium')) {
      final ticketId = _generateTicketId();
      await _logTicketToSupabase(ticketId, 'DSTV Subscription', 'Customer reported issues with DSTV Premium Package');
      replyText = 'Thank you $userName. A technical ticket has been created for the engineering team regarding your DSTV Subscription issue.\n\n**Ticket ID**: $ticketId\n**Provider**: VTPass\n**Status**: Escalated to Engineering\n\nWe will notify you within 15 minutes.';
      replies = ['Back to Main Menu'];
    } else if (query.contains('funding') || query.contains('report wallet funding')) {
      final ticketId = _generateTicketId();
      await _logTicketToSupabase(ticketId, 'Wallet Funding', 'Customer reported issues with Paystack Wallet Funding');
      replyText = 'Thank you $userName. A ticket has been created for the engineering team regarding your Wallet Funding transaction.\n\n**Ticket ID**: $ticketId\n**Provider**: Paystack\n**Status**: Escalated to Engineering\n\nWe will review the bank settlement records and notify you.';
      replies = ['Back to Main Menu'];
    } else if (query.contains('mtn') || query.contains('report mtn airtime')) {
      final ticketId = _generateTicketId();
      await _logTicketToSupabase(ticketId, 'MTN Airtime', 'Customer reported issues with MTN Airtime top-up');
      replyText = 'Thank you $userName. A ticket has been created for the engineering team regarding your MTN Airtime transaction.\n\n**Ticket ID**: $ticketId\n**Provider**: VTPass\n**Status**: Escalated to Engineering\n\nWe will check the network delivery logs and update you.';
      replies = ['Back to Main Menu'];
    } else if (query.contains('paystack info')) {
      replyText = 'Paystack is our primary wallet provider. It generates dedicated virtual bank accounts for each user (e.g. Wema or Titan Trust Bank account numbers) which settle deposits instantly to your Pay Lenses wallet.';
      replies = ['Check Wallet Balance', 'Back to Main Menu'];
    } else if (query.contains('vtpass utilities info')) {
      replyText = 'VTPass is our billing partner. We route payments for airtime top-ups, internet data subscription, electricity bills, and Cable TV packages (DSTV, GOtv, StarTimes) securely via their API.';
      replies = ['Back to Main Menu'];
    } else if (query.contains('agent') || query.contains('talk to')) {
      replyText = 'We are putting you in touch with a Pay Lenses Support Agent. A representative will join this chat in about 2 minutes. Please remain online.';
      replies = ['Cancel Call', 'Back to Main Menu'];
    } else if (query.contains('main menu') || query.contains('back to') || query.contains('menu')) {
      replyText = 'Sure. Here are the main options. How can I help you today?';
      replies = [
        'Verify Transaction Status',
        'Report Technical Issue',
        'Paystack Info',
        'VTPass Utilities Info',
        'Talk to an Agent'
      ];
    } else {
      replyText = 'I am not sure I understand that query. You can choose from the options below or ask to talk to an agent.';
      replies = [
        'Report Technical Issue',
        'Talk to an Agent',
        'Back to Main Menu'
      ];
    }

    _messages.add(
      ChatMessageModel(
        id: _uuid.v4(),
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: replies,
      ),
    );
    notifyListeners();
  }

  Future<void> _logTicketToSupabase(String ticketId, String title, String description) async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await SupabaseService.client.from('support_tickets').insert({
        'id': ticketId,
        'profile_id': uid,
        'title': title,
        'description': description,
        'status': 'escalated',
      });
    } catch (e) {
      debugPrint('Error inserting support ticket to Supabase: $e');
    }
  }

  String _generateTicketId() {
    final rand = Random().nextInt(89999) + 10000;
    return '#TKT-$rand';
  }

  /// Reset chatbot history
  void clearChat() {
    _messages.clear();
    _sendWelcomeMessage();
    notifyListeners();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/features/chatbot/data/models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<String> generateReply(String message, List<ChatMessageModel> history);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ChatRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<String> generateReply(String message, List<ChatMessageModel> history) async {
    final historyJson = history.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'model',
        'text': msg.text,
      };
    }).toList();

    final response = await _supabaseClient.functions.invoke(
      'chat',
      body: {
        'message': message,
        'history': historyJson,
      },
    );

    if (response.status != 200) {
      final err = response.data is Map ? response.data['error'] : 'Unknown error';
      throw Exception('Chatbot Edge Function error (${response.status}): $err');
    }

    final data = response.data;
    if (data is Map && data.containsKey('reply')) {
      return data['reply'] as String;
    }

    throw Exception('Invalid response structure from Edge Function.');
  }
}

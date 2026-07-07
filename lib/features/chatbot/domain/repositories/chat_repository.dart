import 'package:mspay/features/chatbot/data/models/chat_message_model.dart';

abstract class ChatRepository {
  Future<String> getReply(String message, List<ChatMessageModel> history);
}

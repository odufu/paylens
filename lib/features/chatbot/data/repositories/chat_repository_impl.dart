import 'package:mspay/features/chatbot/data/datasources/chat_remote_datasource.dart';
import 'package:mspay/features/chatbot/data/models/chat_message_model.dart';
import 'package:mspay/features/chatbot/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<String> getReply(String message, List<ChatMessageModel> history) {
    return _remoteDataSource.generateReply(message, history);
  }
}

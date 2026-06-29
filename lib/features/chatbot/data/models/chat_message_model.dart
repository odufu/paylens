class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? quickReplies;
  final String? relatedTransactionId;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies,
    this.relatedTransactionId,
  });
}

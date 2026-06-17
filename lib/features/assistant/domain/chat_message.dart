class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'isFromUser': isFromUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'],
    text: map['text'],
    isFromUser: map['isFromUser'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
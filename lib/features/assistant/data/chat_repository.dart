import 'package:hive_flutter/hive_flutter.dart';
import '../domain/chat_message.dart';

class ChatRepository {
  static const _boxName = 'chat_history';

  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  Future<void> saveMessage(ChatMessage message) async {
    final box = await _openBox();
    await box.put(message.id, message.toMap());
  }

  Future<List<ChatMessage>> loadHistory() async {
    final box = await _openBox();
    return box.values
        .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> clearHistory() async {
    final box = await _openBox();
    await box.clear();
  }
}
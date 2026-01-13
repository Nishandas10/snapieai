import 'package:hive_flutter/hive_flutter.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 1)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  List<ChatMessageModel> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ChatSession.create({String? title}) {
    final now = DateTime.now();
    return ChatSession(
      id: now.millisecondsSinceEpoch.toString(),
      title: title ?? 'New Chat',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  void addMessage(ChatMessageModel message) {
    messages.add(message);
    updatedAt = DateTime.now();

    // Update title from first user message if it's still default
    if (title == 'New Chat' && message.isUser && messages.length <= 2) {
      final firstMessage = message.content;
      title = firstMessage.length > 40
          ? '${firstMessage.substring(0, 40)}...'
          : firstMessage;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

@HiveType(typeId: 2)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessageModel.user(String content) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessageModel.assistant(String content) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_session.dart';

/// Service for managing chat sessions in local storage using Hive
class ChatStorageService {
  static const String _boxName = 'chat_sessions';
  static Box<ChatSession>? _box;

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChatMessageModelAdapter());
    }
    _box = await Hive.openBox<ChatSession>(_boxName);
    debugPrint(
      '[ChatStorageService] Initialized with ${_box?.length ?? 0} sessions',
    );
  }

  /// Get the Hive box
  static Box<ChatSession> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('ChatStorageService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Get all chat sessions sorted by updated date (newest first)
  static List<ChatSession> getAllSessions() {
    final sessions = box.values.toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  /// Get a specific session by ID
  static ChatSession? getSession(String id) {
    try {
      return box.values.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create a new chat session
  static Future<ChatSession> createSession({String? title}) async {
    final session = ChatSession.create(title: title);
    await box.put(session.id, session);
    debugPrint('[ChatStorageService] Created session: ${session.id}');
    return session;
  }

  /// Save/update a chat session
  static Future<void> saveSession(ChatSession session) async {
    await box.put(session.id, session);
    debugPrint(
      '[ChatStorageService] Saved session: ${session.id} with ${session.messages.length} messages',
    );
  }

  /// Add a message to a session
  static Future<void> addMessage(
    String sessionId,
    ChatMessageModel message,
  ) async {
    final session = getSession(sessionId);
    if (session != null) {
      session.addMessage(message);
      await saveSession(session);
    }
  }

  /// Rename a session
  static Future<void> renameSession(String sessionId, String newTitle) async {
    final session = getSession(sessionId);
    if (session != null) {
      session.title = newTitle;
      session.updatedAt = DateTime.now();
      await saveSession(session);
      debugPrint(
        '[ChatStorageService] Renamed session: $sessionId to $newTitle',
      );
    }
  }

  /// Delete a session
  static Future<void> deleteSession(String sessionId) async {
    await box.delete(sessionId);
    debugPrint('[ChatStorageService] Deleted session: $sessionId');
  }

  /// Delete all sessions
  static Future<void> deleteAllSessions() async {
    await box.clear();
    debugPrint('[ChatStorageService] Deleted all sessions');
  }

  /// Get session count
  static int get sessionCount => box.length;
}

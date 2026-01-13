import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/chat_storage_service.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatSession? _currentSession;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String _streamingText = '';
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // Create a new session
    _currentSession = await ChatStorageService.createSession();
    _addInitialMessage();
    setState(() {});
  }

  void _addInitialMessage() {
    final initialMessage = ChatMessageModel(
      id: 'initial',
      content:
          '''👋 Hi! I'm Sara, your personal nutrition assistant. I can help you with:

• 🍎 Food and nutrition questions
• 📊 Analyzing your eating patterns
• 🍽️ Meal suggestions based on your goals
• 🏥 Personalized advice for your health conditions
• 💡 Tips for healthier eating

Your chat history is stored locally on your device - only you have access to it.

How can I help you today?''',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages = [initialMessage];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    // Add user message
    final userMessage = ChatMessageModel.user(text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _streamingText = '';
      _isStreaming = true;
    });

    // Save user message to session
    if (_currentSession != null) {
      _currentSession!.addMessage(userMessage);
      await ChatStorageService.saveSession(_currentSession!);
    }

    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      final user = ref.read(userProfileProvider);

      // Build conversation history for context
      final conversationHistory = _messages
          .where((m) => m.id != 'initial')
          .map(
            (m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList();

      final response = await aiService.chat(
        text,
        userProfile: user,
        conversationHistory: conversationHistory,
      );

      // Simulate streaming by revealing text gradually
      await _simulateStreaming(response);

      // Add assistant message
      final assistantMessage = ChatMessageModel.assistant(response);
      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
        _isStreaming = false;
        _streamingText = '';
      });

      // Save assistant message to session
      if (_currentSession != null) {
        _currentSession!.addMessage(assistantMessage);
        await ChatStorageService.saveSession(_currentSession!);
      }
    } catch (e) {
      final errorMessage = ChatMessageModel.assistant(
        'Sorry, I encountered an error. Please try again.',
      );
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
        _isStreaming = false;
        _streamingText = '';
      });
    }

    _scrollToBottom();
  }

  Future<void> _simulateStreaming(String fullText) async {
    // Split into words for more natural streaming
    final words = fullText.split(' ');
    final buffer = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      if (!mounted) break;

      buffer.write(words[i]);
      if (i < words.length - 1) buffer.write(' ');

      setState(() {
        _streamingText = buffer.toString();
      });

      _scrollToBottom();

      // Variable delay for more natural feel
      await Future.delayed(Duration(milliseconds: 15 + (i % 3) * 5));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() async {
    // Save current session if it has messages
    if (_currentSession != null && _messages.length > 1) {
      await ChatStorageService.saveSession(_currentSession!);
    }

    // Create new session
    _currentSession = await ChatStorageService.createSession();
    _addInitialMessage();
    setState(() {});
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSession = session;
      _messages = List.from(session.messages);
      if (_messages.isEmpty) {
        _addInitialMessage();
      }
    });
    Navigator.of(context).pop(); // Close the history drawer
    _scrollToBottom();
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatHistorySheet(
        onSelectSession: _loadSession,
        onDeleteSession: _deleteSession,
        onRenameSession: _renameSession,
        currentSessionId: _currentSession?.id,
      ),
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    await ChatStorageService.deleteSession(sessionId);

    // If we deleted the current session, start a new one
    if (_currentSession?.id == sessionId) {
      _startNewChat();
    }

    setState(() {});
  }

  Future<void> _renameSession(String sessionId, String newTitle) async {
    await ChatStorageService.renameSession(sessionId, newTitle);
    if (_currentSession?.id == sessionId) {
      _currentSession?.title = newTitle;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Sara'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showChatHistory,
            tooltip: 'Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length + (_isStreaming ? 1 : (_isLoading ? 1 : 0)),
              itemBuilder: (context, index) {
                // Show streaming message
                if (_isStreaming && index == _messages.length) {
                  return _StreamingMessageBubble(text: _streamingText);
                }
                // Show typing indicator
                if (_isLoading && !_isStreaming && index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Quick suggestions
          if (_messages.length <= 2)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _QuickSuggestion(
                    text: 'What should I eat today?',
                    onTap: () {
                      _messageController.text = 'What should I eat today?';
                      _sendMessage();
                    },
                  ),
                  _QuickSuggestion(
                    text: 'Low calorie snack ideas',
                    onTap: () {
                      _messageController.text = 'Low calorie snack ideas';
                      _sendMessage();
                    },
                  ),
                  _QuickSuggestion(
                    text: 'How much protein do I need?',
                    onTap: () {
                      _messageController.text = 'How much protein do I need?';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything about nutrition...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AppColors.textHint
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: message.isUser
            ? Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: _formatMarkdown(message.content),
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  strong: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  listBullet: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                  h1: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  blockquote: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  code: TextStyle(
                    backgroundColor: AppColors.inputBackground,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                selectable: true,
              ),
      ),
    );
  }

  String _formatMarkdown(String text) {
    // Clean up common formatting issues from AI responses
    String formatted = text;

    // Convert **text** to proper markdown bold
    // Already works in markdown

    // Convert bullet points that might use different characters
    formatted = formatted.replaceAll('• ', '* ');
    formatted = formatted.replaceAll('- ', '* ');

    // Ensure proper line breaks for lists
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d+\.) '),
      (match) => '\n${match.group(0)}',
    );

    // Clean up double newlines
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return formatted.trim();
  }
}

class _StreamingMessageBubble extends StatelessWidget {
  final String text;

  const _StreamingMessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const _BlinkingCursor(),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(width: 2, height: 16, color: AppColors.primary),
        );
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotAnimation(delay: 0),
            const SizedBox(width: 4),
            _DotAnimation(delay: 150),
            const SizedBox(width: 4),
            _DotAnimation(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;

  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.3 + (_animation.value * 0.7),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickSuggestion({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Chat History Sheet
class _ChatHistorySheet extends StatefulWidget {
  final Function(ChatSession) onSelectSession;
  final Function(String) onDeleteSession;
  final Function(String, String) onRenameSession;
  final String? currentSessionId;

  const _ChatHistorySheet({
    required this.onSelectSession,
    required this.onDeleteSession,
    required this.onRenameSession,
    this.currentSessionId,
  });

  @override
  State<_ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends State<_ChatHistorySheet> {
  List<ChatSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = ChatStorageService.getAllSessions();
    });
  }

  void _showRenameDialog(ChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                widget.onRenameSession(session.id, newTitle);
                Navigator.pop(context);
                _loadSessions();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _showDeleteConfirmation(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteSession(session.id);
              Navigator.pop(context);
              _loadSessions();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Chat History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_sessions.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All History'),
                          content: const Text(
                            'Are you sure you want to delete all chat history?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ChatStorageService.deleteAllSessions();
                        _loadSessions();
                      }
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Sessions list
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No chat history yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final isActive = session.id == widget.currentSessionId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? AppColors.primary
                              : AppColors.inputBackground,
                          child: Icon(
                            Icons.chat,
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(session.updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameDialog(session);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(session);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 12),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => widget.onSelectSession(session),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

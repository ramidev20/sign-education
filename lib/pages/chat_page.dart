import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/pages/chatSettings_page.dart';
import 'package:sign_education/utils/imageAvatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uuid/uuid.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';

class ChatPage extends StatefulWidget {
  final UserModel user;
  final ClassGroupModel group;

  const ChatPage({super.key, required this.user, required this.group});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final chat_core.ChatController _chatController;
  RealtimeChannel? _channel;
  final List<chat_core.TextMessage> _messages = [];
  final Set<String> _messageIds = <String>{};
  final Set<String> _animateMessageIds = <String>{};

  DateTime? _oldestCreatedAt;
  bool _loadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 50;

  late final OnMessageLongPressCallback? onMessageLongPress;

  @override
  void initState() {
    super.initState();
    _chatController = chat_core.InMemoryChatController();

    _loadMessages();
    // ✅ Subscribe to real-time updates
    _initRealtime();

    onMessageLongPress =
        (
          BuildContext context,
          chat_core.Message message, {
          LongPressStartDetails? details,
          int? index,
        }) {
          debugPrint("Message long pressed ${message.id}");
          showModalBottomSheet<String>(
            context: context,
            builder: (context) {
              final emojis = ["👍", "❤️", "😂", "🔥", "😮", "😢"];
              return Wrap(
                alignment: WrapAlignment.center,
                children: emojis.map((e) {
                  return InkWell(
                    onTap: () => Navigator.pop(context, e),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              );
            },
          ).then((emoji) {
            if (emoji != null) {
              debugPrint(
                "Reaction $emoji on message ${message.id} "
                "at index ${index ?? -1} (details: $details)",
              );
              // TODO: save to backend/controller
            }
          });
        };
  }

  void _initRealtime() async {
    _channel = await DbHelperClasses.subscribeToGroupMessages(
      classGroupId: widget.group.classGroupId,
      onMessage: (payload) async {
        // only insert the new message
        final messageId = payload['message_id']?.toString();
        if (messageId == null || messageId.isEmpty) return;
        if (_messageIds.contains(messageId)) return;

        final message = chat_core.TextMessage(
          id: messageId,
          authorId: payload['sender_id'].toString(),
          createdAt: DateTime.parse(payload['created_at']).toUtc(),
          text: payload['text'] ?? '',
        );

        _messageIds.add(messageId);
        _animateMessageIds.add(messageId);
        _messages.add(message);
        _chatController.insertMessage(message);
      },
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final response = await _supabase
        .from('messages')
        .select('message_id, sender_id, created_at, text')
        .eq('class_group_id', widget.group.classGroupId)
        .order('created_at', ascending: false)
        .limit(_pageSize);

    final messages = (response as List).map((m) {
      final id = m['message_id']?.toString() ?? const Uuid().v4();
      return chat_core.TextMessage(
        id: id,
        authorId: m['sender_id'].toString(),
        createdAt:
            DateTime.tryParse(m['created_at'] ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
        text: m['text'] ?? '',
      );
    }).toList().reversed.toList();

    _messages
      ..clear()
      ..addAll(messages);
    _messageIds
      ..clear()
      ..addAll(messages.map((m) => m.id));
    _oldestCreatedAt = _messages.isNotEmpty ? _messages.first.createdAt : null;
    _hasMore = (response as List).length == _pageSize;

    // preload all unique sender IDs in one query
    final userIds = messages.map((m) => m.authorId).toSet().toList();
    if (userIds.isNotEmpty) {
      final users = await _supabase
          .from('users')
          .select('id, name')
          .inFilter('id', userIds);

      for (final u in users) {
        _userCache[u['id']] = chat_core.User(id: u['id'], name: u['name']);
      }
    }

    _chatController.setMessages(messages);
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore || !_hasMore || _oldestCreatedAt == null) return;
    setState(() => _loadingMore = true);

    try {
      final response = await _supabase
          .from('messages')
          .select('message_id, sender_id, created_at, text')
          .eq('class_group_id', widget.group.classGroupId)
          .lt('created_at', _oldestCreatedAt!.toIso8601String())
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final page = (response as List).map((m) {
        final id = m['message_id']?.toString() ?? const Uuid().v4();
        return chat_core.TextMessage(
          id: id,
          authorId: m['sender_id'].toString(),
          createdAt:
              DateTime.tryParse(m['created_at'] ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
          text: m['text'] ?? '',
        );
      }).toList().reversed.toList();

      if (!mounted) return;
      setState(() {
        _messages.insertAll(0, page);
        _messageIds.addAll(page.map((m) => m.id));
        _oldestCreatedAt = _messages.isNotEmpty ? _messages.first.createdAt : null;
        _hasMore = page.length == _pageSize;
      });

      _chatController.setMessages(List<chat_core.TextMessage>.from(_messages));

      if (!_hasMore && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد رسائل أقدم')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل المزيد: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _handleSendMessage(String text) async {
    final messageId = const Uuid().v4();
    final message = chat_core.TextMessage(
      id: messageId,
      authorId: widget.user.id,
      createdAt: DateTime.now().toUtc(),
      text: text,
    );

    _messageIds.add(messageId);
    _animateMessageIds.add(messageId);
    _messages.add(message);
    _chatController.insertMessage(message);

    await DbHelperClasses.sendMessageToGroup(
      classGroupId: widget.group.classGroupId,
      senderId: widget.user.id,
      text: text,
      messageId: messageId,
    );
  }

  final Map<String, chat_core.User> _userCache = {};

  Future<chat_core.User> _resolveUser(chat_core.UserID id) async {
    if (_userCache.containsKey(id)) {
      return _userCache[id]!;
    }

    debugPrint('[resolveUser] Cache miss for $id, fetching from DB...');

    // Remove the "current user optimization"
    final response = await _supabase
        .from('users')
        .select('id, name')
        .eq('id', id)
        .maybeSingle();

    final user = chat_core.User(id: id, name: response?['name'] ?? 'User $id');
    _userCache[id] = user;
    debugPrint('[resolveUser] Fetched user: ${user.name}');
    return user;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            tooltip: 'تحميل رسائل أقدم',
            onPressed: _loadingMore ? null : _loadMoreMessages,
            icon: _loadingMore
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.history),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatSettingsPage(
                    group: widget.group,
                    currentUser: widget.user,
                    isGroupChat: true,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DefaultAvatar(
                avatarColor: widget.group.avatarColor, // 🎨 use new field
                name: widget.group.name,
                radius: 20,
              ),
            ),
          ),
        ],
      ),

      body: Chat(
        chatController: _chatController,
        currentUserId: widget.user.id,
        onMessageSend: _handleSendMessage,
        resolveUser: _resolveUser,
        theme: chat_core.ChatTheme.fromThemeData(theme),
        backgroundColor: theme.colorScheme.background,

        onMessageLongPress: onMessageLongPress,

        builders: chat_core.Builders(
          chatMessageBuilder:
              (
                BuildContext context,
                chat_core.Message message,
                int messageWidth,
                Animation<double> animation,
                Widget child, {
                chat_core.MessageGroupStatus? groupStatus,
                bool? isRemoved,
                required bool isSentByMe,
              }) {
                final shouldAnimate = _animateMessageIds.remove(message.id);
                final sizeFactor = shouldAnimate
                    ? animation
                    : const AlwaysStoppedAnimation<double>(1);

                return SizeTransition(
                  sizeFactor: sizeFactor,
                  child: FutureBuilder<chat_core.User>(
                    future: _resolveUser(message.authorId), // fetch user info
                    builder: (context, snapshot) {
                      final displayName = snapshot.hasData
                          ? snapshot.data!.name
                          : message.authorId; // fallback until loaded

                      return Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 4.0,
                        ), // Add spacing between messages
                        child: Row(
                          mainAxisAlignment: isSentByMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isSentByMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isSentByMe) // 👈 show label only for others
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left:
                                            12.0, // Added left padding to align with bubble
                                        bottom: 4.0, // Increased bottom padding
                                      ),
                                      child: Text(
                                        displayName!,
                                        style: TextStyle(
                                          fontSize: 12, // Slightly larger font
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal:
                                          8.0, // Add horizontal margin to bubbles
                                    ),
                                    child: child, // the original bubble
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
        ),
      ),
    );
  }
}

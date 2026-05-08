import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/assignment_model.dart';
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
  static const String _payloadPrefix = '__SE_CHAT_V2__';

  final SupabaseClient _supabase = Supabase.instance.client;
  late final chat_core.ChatController _chatController;
  RealtimeChannel? _channel;
  final List<chat_core.TextMessage> _messages = [];
  final Set<String> _messageIds = <String>{};
  final Set<String> _animateMessageIds = <String>{};
  final Map<String, _MessagePayload> _payloadByMessageId = <String, _MessagePayload>{};
  final Map<String, List<String>> _reactionByMessageId = <String, List<String>>{};

  chat_core.TextMessage? _replyToMessage;

  DateTime? _oldestCreatedAt;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _sendingReminder = false;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _chatController = chat_core.InMemoryChatController();

    _loadMessages();
    // ✅ Subscribe to real-time updates
    _initRealtime();
  }

  void _initRealtime() async {
    _channel = await DbHelperClasses.subscribeToGroupMessages(
      classGroupId: widget.group.classGroupId,
      onMessage: (payload) async {
        // only insert the new message
        final messageId = payload['message_id']?.toString();
        if (messageId == null || messageId.isEmpty) return;
        if (_messageIds.contains(messageId)) return;

        final payloadText = (payload['text'] ?? '').toString();
        final parsedPayload = _decodePayload(payloadText);
        final message = chat_core.TextMessage(
          id: messageId,
          authorId: payload['sender_id'].toString(),
          createdAt: DateTime.parse(payload['created_at']).toUtc(),
          text: parsedPayload.displayText,
        );

        _payloadByMessageId[messageId] = parsedPayload;
        _reactionByMessageId[messageId] = List<String>.from(parsedPayload.reactions);
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
      final parsedPayload = _decodePayload((m['text'] ?? '').toString());
      _payloadByMessageId[id] = parsedPayload;
      _reactionByMessageId[id] = List<String>.from(parsedPayload.reactions);
      return chat_core.TextMessage(
        id: id,
        authorId: m['sender_id'].toString(),
        createdAt:
            DateTime.tryParse(m['created_at'] ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
        text: parsedPayload.displayText,
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
        final parsedPayload = _decodePayload((m['text'] ?? '').toString());
        _payloadByMessageId[id] = parsedPayload;
        _reactionByMessageId[id] = List<String>.from(parsedPayload.reactions);
        return chat_core.TextMessage(
          id: id,
          authorId: m['sender_id'].toString(),
          createdAt:
              DateTime.tryParse(m['created_at'] ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
          text: parsedPayload.displayText,
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
    final payload = _MessagePayload(
      displayText: text,
      rawText: text,
      replyToMessageId: _replyToMessage?.id,
      replyPreview: _replyToMessage?.text,
      reactions: const <String>[],
      messageType: 'text',
      assignmentTitle: null,
      assignmentDueAt: null,
    );
    final message = chat_core.TextMessage(
      id: messageId,
      authorId: widget.user.id,
      createdAt: DateTime.now().toUtc(),
      text: payload.displayText,
    );

    _payloadByMessageId[messageId] = payload;
    _reactionByMessageId[messageId] = <String>[];
    _messageIds.add(messageId);
    _animateMessageIds.add(messageId);
    _messages.add(message);
    _chatController.insertMessage(message);
    setState(() => _replyToMessage = null);

    await DbHelperClasses.sendMessageToGroup(
      classGroupId: widget.group.classGroupId,
      senderId: widget.user.id,
      text: _encodePayload(payload),
      messageId: messageId,
    );
  }

  _MessagePayload _decodePayload(String rawText) {
    if (!rawText.startsWith(_payloadPrefix)) {
      return _MessagePayload(
        rawText: rawText,
        displayText: rawText,
        replyToMessageId: null,
        replyPreview: null,
        reactions: const <String>[],
        messageType: 'text',
        assignmentTitle: null,
        assignmentDueAt: null,
      );
    }

    try {
      final jsonPart = rawText.substring(_payloadPrefix.length);
      final decoded = Map<String, dynamic>.from(
        (jsonDecode(jsonPart) as Map),
      );
      return _MessagePayload(
        rawText: rawText,
        displayText: (decoded['text'] ?? '').toString(),
        replyToMessageId: decoded['reply_to']?.toString(),
        replyPreview: decoded['reply_preview']?.toString(),
        reactions: (decoded['reactions'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        messageType: (decoded['type'] ?? 'text').toString(),
        assignmentTitle: decoded['assignment_title']?.toString(),
        assignmentDueAt: decoded['assignment_due_at']?.toString(),
      );
    } catch (_) {
      return _MessagePayload(
        rawText: rawText,
        displayText: rawText,
        replyToMessageId: null,
        replyPreview: null,
        reactions: const <String>[],
        messageType: 'text',
        assignmentTitle: null,
        assignmentDueAt: null,
      );
    }
  }

  String _encodePayload(_MessagePayload payload) {
    final map = <String, dynamic>{
      'text': payload.displayText,
      'reply_to': payload.replyToMessageId,
      'reply_preview': payload.replyPreview,
      'reactions': payload.reactions,
      'type': payload.messageType,
      'assignment_title': payload.assignmentTitle,
      'assignment_due_at': payload.assignmentDueAt,
    };
    return '$_payloadPrefix${jsonEncode(map)}';
  }

  Future<void> _persistReaction(chat_core.Message message, String emoji) async {
    final msg = message as chat_core.TextMessage;
    final payload = _payloadByMessageId[msg.id] ?? _decodePayload(msg.text);
    final currentReactions = List<String>.from(payload.reactions);
    if (currentReactions.contains(emoji)) {
      currentReactions.remove(emoji);
    } else {
      currentReactions.add(emoji);
    }

    final updatedPayload = payload.copyWith(reactions: currentReactions);
    _payloadByMessageId[msg.id] = updatedPayload;
    _reactionByMessageId[msg.id] = currentReactions;
    if (mounted) setState(() {});

    try {
      await _supabase
          .from('messages')
          .update({'text': _encodePayload(updatedPayload)})
          .eq('message_id', msg.id);
    } catch (_) {}
  }

  Future<void> _openAssignmentReminderDialog() async {
    if (widget.user.role != 'teacher') return;
    setState(() => _sendingReminder = true);
    try {
      final assignments = await DbHelperAssignments.getAssignmentsByTeacher(
        widget.user.id,
      );
      if (!mounted) return;
      if (assignments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد واجبات لإرسال تذكير بها')),
        );
        return;
      }

      AssignmentModel? selected = assignments.first;
      final noteController = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تذكير بواجب'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selected?.assignmentId,
                  decoration: const InputDecoration(labelText: 'اختر الواجب'),
                  items: assignments
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a.assignmentId,
                          child: Text(a.title ?? 'واجب'),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    setDialogState(() {
                      selected = assignments.firstWhere(
                        (a) => a.assignmentId == id,
                        orElse: () => assignments.first,
                      );
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة إضافية (اختياري)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إرسال التذكير'),
            ),
          ],
        ),
      );

      if (ok != true || selected == null) return;
      final reminderText = noteController.text.trim().isEmpty
          ? 'تذكير: يرجى حل الواجب في الوقت المحدد.'
          : noteController.text.trim();

      final messageId = const Uuid().v4();
      final payload = _MessagePayload(
        rawText: reminderText,
        displayText: reminderText,
        replyToMessageId: null,
        replyPreview: null,
        reactions: const <String>[],
        messageType: 'assignment_reminder',
        assignmentTitle: selected!.title ?? 'واجب',
        assignmentDueAt: selected!.completeAt.toIso8601String(),
      );

      final message = chat_core.TextMessage(
        id: messageId,
        authorId: widget.user.id,
        createdAt: DateTime.now().toUtc(),
        text: payload.displayText,
      );

      _payloadByMessageId[messageId] = payload;
      _reactionByMessageId[messageId] = <String>[];
      _messageIds.add(messageId);
      _animateMessageIds.add(messageId);
      _messages.add(message);
      _chatController.insertMessage(message);

      await DbHelperClasses.sendMessageToGroup(
        classGroupId: widget.group.classGroupId,
        senderId: widget.user.id,
        text: _encodePayload(payload),
        messageId: messageId,
      );
    } finally {
      if (mounted) setState(() => _sendingReminder = false);
    }
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
          if (widget.user.role == 'teacher')
            IconButton(
              tooltip: 'تذكير بواجب',
              onPressed: _sendingReminder ? null : _openAssignmentReminderDialog,
              icon: _sendingReminder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_late_outlined),
            ),
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

      body: Column(
        children: [
          if (_replyToMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyToMessage!.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _replyToMessage = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Chat(
              chatController: _chatController,
              currentUserId: widget.user.id,
              onMessageSend: _handleSendMessage,
              resolveUser: _resolveUser,
              theme: chat_core.ChatTheme.fromThemeData(theme),
              backgroundColor: theme.colorScheme.background,

              onMessageLongPress:
                  (
                    BuildContext context,
                    chat_core.Message message, {
                    LongPressStartDetails? details,
                    int? index,
                  }) {
                    showModalBottomSheet<String>(
                      context: context,
                      builder: (context) {
                        final emojis = ["👍", "❤️", "😂", "🔥", "😮", "😢"];
                        return Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            ...emojis.map((e) {
                              return InkWell(
                                onTap: () => Navigator.pop(context, e),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              );
                            }),
                            ListTile(
                              leading: const Icon(Icons.reply_rounded),
                              title: const Text('رد على الرسالة'),
                              onTap: () => Navigator.pop(context, '__reply__'),
                            ),
                          ],
                        );
                      },
                    ).then((value) async {
                      if (value == null) return;
                      if (value == '__reply__' && message is chat_core.TextMessage) {
                        setState(() => _replyToMessage = message);
                        return;
                      }
                      await _persistReaction(message, value);
                    });
                  },

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
                                    child: Column(
                                      crossAxisAlignment: isSentByMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (_payloadByMessageId[message.id]?.replyPreview !=
                                            null)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cs.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _payloadByMessageId[message.id]!
                                                  .replyPreview!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        if (_payloadByMessageId[message.id]?.messageType ==
                                            'assignment_reminder')
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'تذكير واجب: ${_payloadByMessageId[message.id]?.assignmentTitle ?? ""}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        child,
                                        if ((_reactionByMessageId[message.id] ?? const [])
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Wrap(
                                              spacing: 4,
                                              children:
                                                  (_reactionByMessageId[message.id] ??
                                                          const [])
                                                      .map(
                                                        (emoji) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: cs.surfaceContainerHighest,
                                                            borderRadius:
                                                                BorderRadius.circular(10),
                                                          ),
                                                          child: Text(emoji),
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                          ),
                                      ],
                                    ),
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
          ),
        ],
      ),
    );
  }
}

class _MessagePayload {
  final String rawText;
  final String displayText;
  final String? replyToMessageId;
  final String? replyPreview;
  final List<String> reactions;
  final String messageType;
  final String? assignmentTitle;
  final String? assignmentDueAt;

  const _MessagePayload({
    required this.rawText,
    required this.displayText,
    required this.replyToMessageId,
    required this.replyPreview,
    required this.reactions,
    required this.messageType,
    required this.assignmentTitle,
    required this.assignmentDueAt,
  });

  _MessagePayload copyWith({
    String? rawText,
    String? displayText,
    String? replyToMessageId,
    String? replyPreview,
    List<String>? reactions,
    String? messageType,
    String? assignmentTitle,
    String? assignmentDueAt,
  }) {
    return _MessagePayload(
      rawText: rawText ?? this.rawText,
      displayText: displayText ?? this.displayText,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyPreview: replyPreview ?? this.replyPreview,
      reactions: reactions ?? this.reactions,
      messageType: messageType ?? this.messageType,
      assignmentTitle: assignmentTitle ?? this.assignmentTitle,
      assignmentDueAt: assignmentDueAt ?? this.assignmentDueAt,
    );
  }
}

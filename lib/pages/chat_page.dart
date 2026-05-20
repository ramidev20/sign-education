import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/pages/chat_settings_page.dart';
import 'package:sign_education/utils/app_strings.dart';
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
  final Map<String, _MessagePayload> _payloadByMessageId =
      <String, _MessagePayload>{};
  final Map<String, List<String>> _reactionByMessageId =
      <String, List<String>>{};
  final Map<String, String> _roleByUserId = <String, String>{};

  chat_core.TextMessage? _replyToMessage;

  bool _sendingReminder = false;
  static const int _pageSize = 50;

  static bool _looksArabic(String text) {
    // Basic Arabic blocks (covers common Arabic letters).
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
  }

  static String _formatHHmm(BuildContext context, DateTime dtUtc) {
    final local = dtUtc.toLocal();
    final tod = TimeOfDay(hour: local.hour, minute: local.minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      tod,
      alwaysUse24HourFormat: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _chatController = chat_core.InMemoryChatController();

    _loadMessages();
    // Subscribe to real-time updates.
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
        _reactionByMessageId[messageId] = List<String>.from(
          parsedPayload.reactions,
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

    final messages = (response as List)
        .map((m) {
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
        })
        .toList()
        .reversed
        .toList();

    _messages
      ..clear()
      ..addAll(messages);
    _messageIds
      ..clear()
      ..addAll(messages.map((m) => m.id));
    // preload all unique sender IDs in one query
    final userIds = messages.map((m) => m.authorId).toSet().toList();
    if (userIds.isNotEmpty) {
      final users = await _supabase
          .from('users')
          .select('id, name, role')
          .inFilter('id', userIds);

      for (final u in users) {
        _userCache[u['id']] = chat_core.User(id: u['id'], name: u['name']);
        final role = (u['role'] ?? '').toString();
        if (role.isNotEmpty) _roleByUserId[u['id'].toString()] = role;
      }
    }

    _chatController.setMessages(messages);
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
      final decoded = Map<String, dynamic>.from((jsonDecode(jsonPart) as Map));
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
    final strings = AppStrings.of(context);
    setState(() => _sendingReminder = true);
    try {
      final assignments = await DbHelperAssignments.getAssignmentsByTeacher(
        widget.user.id,
      );
      if (!mounted) return;
      if (assignments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.text(
                'لا توجد واجبات لإرسال تذكير بها',
                'No assignments to remind',
                'Aucun devoir a rappeler',
              ),
            ),
          ),
        );
        return;
      }

      AssignmentModel? selected = assignments.first;
      final noteController = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            strings.text(
              'تذكير بواجب',
              'Assignment reminder',
              'Rappel de devoir',
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selected?.assignmentId,
                  decoration: InputDecoration(
                    labelText:
                        strings.text('اختر الواجب', 'Select assignment', 'Choisir un devoir'),
                  ),
                  items: assignments
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a.assignmentId,
                          child: Text(
                            a.title ??
                                strings.text('واجب', 'Assignment', 'Devoir'),
                          ),
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
                  decoration: InputDecoration(
                    labelText: strings.text(
                      'ملاحظة إضافية (اختياري)',
                      'Optional note',
                      'Note optionnelle',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                strings.text(
                  'إرسال التذكير',
                  'Send reminder',
                  'Envoyer le rappel',
                ),
              ),
            ),
          ],
        ),
      );

      if (ok != true || selected == null) return;
      final reminderText = noteController.text.trim().isEmpty
          ? strings.text(
              'تذكير: يرجى حل الواجب في الوقت المحدد.',
              'Reminder: please complete the assignment on time.',
              "Rappel : veuillez terminer le devoir a temps.",
            )
          : noteController.text.trim();

      final messageId = const Uuid().v4();
      final payload = _MessagePayload(
        rawText: reminderText,
        displayText: reminderText,
        replyToMessageId: null,
        replyPreview: null,
        reactions: const <String>[],
        messageType: 'assignment_reminder',
        assignmentTitle:
            selected!.title ?? strings.text('واجب', 'Assignment', 'Devoir'),
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
        .select('id, name, role')
        .eq('id', id)
        .maybeSingle();

    final user = chat_core.User(id: id, name: response?['name'] ?? 'User $id');
    _userCache[id] = user;
    final role = (response?['role'] ?? '').toString();
    if (role.isNotEmpty) _roleByUserId[id] = role;
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
              onPressed: _sendingReminder
                  ? null
                  : _openAssignmentReminderDialog,
              icon: _sendingReminder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_late_outlined),
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
                avatarColor: widget.group.avatarColor,
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
            child: Directionality(
              // Keep overall chat layout LTR (WhatsApp-style positioning),
              // while we can still render Arabic text RTL per-message.
              textDirection: TextDirection.ltr,
              child: Chat(
                chatController: _chatController,
                currentUserId: widget.user.id,
                onMessageSend: _handleSendMessage,
                resolveUser: _resolveUser,
                theme: chat_core.ChatTheme.fromThemeData(theme),
                backgroundColor: theme.colorScheme.surface,

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
                                  title: Text(
                                    AppStrings.of(context).text(
                                      'رد على الرسالة',
                                      'Reply to message',
                                      'Repondre au message',
                                    ),
                                  ),
                              onTap: () => Navigator.pop(context, '__reply__'),
                            ),
                          ],
                        );
                      },
                    ).then((value) async {
                      if (value == null) return;
                      if (value == '__reply__' &&
                          message is chat_core.TextMessage) {
                        setState(() => _replyToMessage = message);
                        return;
                      }
                      await _persistReaction(message, value);
                    });
                  },

                builders: chat_core.Builders(
                  // WhatsApp-like composer (send icon on the right, subtle input bg)
                  composerBuilder: (context) {
                    final t = Theme.of(context);
                    final cs = t.colorScheme;
                    return Composer(
                      // WhatsApp-like icons/spacing/colors.
                      attachmentIcon: Icon(Icons.add, color: cs.onSurface),
                      sendIcon: const Icon(Icons.send_rounded),
                      sendIconColor: cs.primary,
                      emptyFieldSendIconColor:
                          cs.onSurfaceVariant.withValues(alpha: 0.5),
                      backgroundColor: cs.surface,
                      inputFillColor: cs.surfaceContainerLow,
                      hintColor: cs.onSurfaceVariant,
                      textColor: cs.onSurface,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      gap: 8,
                      inputBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                    );
                  },
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
                      final shouldAnimate = _animateMessageIds.remove(
                        message.id,
                      );
                      final sizeFactor = shouldAnimate
                          ? animation
                          : const AlwaysStoppedAnimation<double>(1);

                      return SizeTransition(
                        sizeFactor: sizeFactor,
                        child: FutureBuilder<chat_core.User>(
                          future: _resolveUser(
                            message.authorId,
                          ), // fetch user info
                          builder: (context, snapshot) {
                            final displayName = snapshot.hasData
                                ? snapshot.data!.name
                                : message.authorId; // fallback until loaded
                            final authorRole =
                                _roleByUserId[message.authorId] ?? '';
                            final isTeacher = authorRole == 'teacher';
                            final teacherTagBg = cs.tertiaryContainer;
                            final teacherTagFg = cs.onTertiaryContainer;
                            final receivedBubbleBg = cs.surface;
                            final receivedBubbleBorder = cs.outlineVariant
                                .withValues(alpha: 0.35);

                            final createdAt = message.createdAt;
                            final timeText = createdAt != null
                                ? _formatHHmm(context, createdAt)
                                : '';

                            final msgText = (message is chat_core.TextMessage)
                                ? message.text
                                : '';
                            final isArabic = _looksArabic(msgText);
                            final bubbleMaxWidth =
                                MediaQuery.of(context).size.width * 0.62;
                            final bubbleRadius = BorderRadius.circular(14);
                            final mineBubbleBg = cs.primaryContainer;
                            final mineBubbleFg = cs.onPrimaryContainer;
                            final otherBubbleFg = cs.onSurface;

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
                                              if (_payloadByMessageId[message
                                                          .id]
                                                      ?.replyPreview !=
                                                  null)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 4,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: cs
                                                        .surfaceContainerHighest,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _payloadByMessageId[message
                                                            .id]!
                                                        .replyPreview!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ),
                                              if (_payloadByMessageId[message
                                                          .id]
                                                      ?.messageType ==
                                                  'assignment_reminder')
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 4,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: cs.tertiaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'تذكير واجب: ${_payloadByMessageId[message.id]?.assignmentTitle ?? ""}',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),

                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: bubbleMaxWidth,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isSentByMe
                                                        ? mineBubbleBg
                                                        : receivedBubbleBg,
                                                    borderRadius: bubbleRadius,
                                                    border: isSentByMe
                                                        ? null
                                                        : Border.all(
                                                          color:
                                                              receivedBubbleBorder,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        12,
                                                        8,
                                                        12,
                                                        6,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      // Sender name + teacher tag inside the bubble.
                                                      // Always show "Teacher" when the author is a teacher.
                                                      if (!isSentByMe || isTeacher)
                                                        Row(
                                                          mainAxisAlignment:
                                                              (!isSentByMe)
                                                                  ? MainAxisAlignment
                                                                      .spaceBetween
                                                                  : MainAxisAlignment
                                                                      .end,
                                                          children: [
                                                            if (!isSentByMe)
                                                              Expanded(
                                                                child: Text(
                                                                  displayName ??
                                                                      '',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: theme
                                                                      .textTheme
                                                                      .labelMedium
                                                                      ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w700,
                                                                        color: cs
                                                                            .onSurfaceVariant,
                                                                      ),
                                                                ),
                                                              ),
                                                            if (isTeacher) ...[
                                                              if (!isSentByMe)
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      teacherTagBg,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        999,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Teacher',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        teacherTagFg,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      if (!isSentByMe || isTeacher)
                                                        const SizedBox(height: 6),
                                                      if (msgText.isNotEmpty)
                                                        Align(
                                                          alignment: isArabic
                                                              ? Alignment
                                                                  .centerRight
                                                              : Alignment
                                                                  .centerLeft,
                                                          child: Text(
                                                            msgText,
                                                            textDirection:
                                                                isArabic
                                                                    ? TextDirection
                                                                        .rtl
                                                                    : TextDirection
                                                                        .ltr,
                                                            textAlign: isArabic
                                                                ? TextAlign
                                                                    .right
                                                                : TextAlign
                                                                    .left,
                                                            style: theme
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontSize:
                                                                      14,
                                                                  color:
                                                                      isSentByMe
                                                                          ? mineBubbleFg
                                                                          : otherBubbleFg,
                                                                ),
                                                          ),
                                                        )
                                                      else
                                                        child,
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Text(
                                                            timeText,
                                                            style: theme
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  color: (isSentByMe
                                                                          ? mineBubbleFg
                                                                          : cs
                                                                              .onSurfaceVariant)
                                                                      .withValues(
                                                                        alpha:
                                                                            0.75,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              if ((_reactionByMessageId[message
                                                          .id] ??
                                                      const [])
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    children:
                                                        (_reactionByMessageId[message
                                                                    .id] ??
                                                                const [])
                                                            .map(
                                                              (
                                                                emoji,
                                                              ) => Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: cs
                                                                      .surfaceContainerHighest,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  emoji,
                                                                ),
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

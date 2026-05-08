import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_live_quizzes.dart';
import 'package:sign_education/data/models/live_quiz_entry_model.dart';
import 'package:sign_education/data/models/live_quiz_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentLiveQuizRoomPage extends StatefulWidget {
  final UserModel user;
  final LiveQuizModel quiz;

  const StudentLiveQuizRoomPage({
    super.key,
    required this.user,
    required this.quiz,
  });

  @override
  State<StudentLiveQuizRoomPage> createState() => _StudentLiveQuizRoomPageState();
}

class _StudentLiveQuizRoomPageState extends State<StudentLiveQuizRoomPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _channel;
  RealtimeChannel? _statusChannel;
  List<LiveQuizEntryModel> _entries = [];
  bool _loading = true;
  bool _sending = false;
  String _entryType = 'text';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _status = widget.quiz.status;
    _loadEntries();
    _subscribeEntries();
    _subscribeQuizStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    _statusChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      final list = await DbHelperLiveQuizzes.getEntriesByQuiz(widget.quiz.quizId!);
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
      _scrollToBottom(animated: false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _subscribeEntries() {
    final quizId = widget.quiz.quizId;
    if (quizId == null) return;
    _channel = _supabase.channel('live_quiz_entries_student_$quizId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_quiz_entries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quiz_id',
            value: quizId,
          ),
          callback: (payload) {
            final newEntry = LiveQuizEntryModel.fromMap(payload.newRecord);
            if (!mounted) return;
            setState(() => _entries = [..._entries, newEntry]);
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  void _subscribeQuizStatus() {
    final quizId = widget.quiz.quizId;
    if (quizId == null) return;
    _statusChannel = _supabase.channel('live_quiz_status_$quizId');
    _statusChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'live_quizzes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quiz_id',
            value: quizId,
          ),
          callback: (payload) {
            final status = (payload.newRecord['status'] ?? 'active').toString();
            if (!mounted) return;
            setState(() => _status = status);
          },
        )
        .subscribe();
  }

  Future<void> _sendEntry() async {
    if (_status != 'active') return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await DbHelperLiveQuizzes.addEntry(
        LiveQuizEntryModel(
          quizId: widget.quiz.quizId!,
          studentId: widget.user.id,
          studentName: widget.user.name,
          entryText: text,
          entryType: _entryType,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال المساهمة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 60;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  String _entryTypeLabel(String type) {
    switch (type) {
      case 'symbol':
        return 'رمز بصري';
      case 'sign_description':
        return 'وصف إشارة';
      default:
        return 'فكرة نصية';
    }
  }

  IconData _entryTypeIcon(String type) {
    switch (type) {
      case 'symbol':
        return Icons.auto_awesome_outlined;
      case 'sign_description':
        return Icons.gesture_outlined;
      default:
        return Icons.text_fields_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickEntryType() async {
    if (_status != 'active') return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _TypeItem(
                value: 'text',
                label: 'فكرة نصية',
                icon: Icons.text_fields_rounded,
              ),
              _TypeItem(
                value: 'symbol',
                label: 'رمز بصري',
                icon: Icons.auto_awesome_outlined,
              ),
              _TypeItem(
                value: 'sign_description',
                label: 'وصف إشارة',
                icon: Icons.gesture_outlined,
              ),
              SizedBox(height: 6),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _entryType = picked);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _status == 'active';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(canSend ? 'مباشر الآن' : 'تم إغلاق الجلسة'),
                        ),
                        Chip(label: Text('مساهمات الفريق: ${_entries.length}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.quiz.promptText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if ((widget.quiz.visualPromptUrl ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.quiz.visualPromptUrl!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                  ? const Center(
                      child: Text('لا توجد مساهمات بعد، ابدأوا العصف الذهني'),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final isMine = entry.studentId == widget.user.id;
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.82,
                            ),
                            child: Card(
                              color: isMine
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.10)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _entryTypeIcon(entry.entryType),
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _entryTypeLabel(entry.entryType),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(entry.createdAt),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.entryText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.studentName,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: canSend ? _pickEntryType : null,
                        icon: Icon(_entryTypeIcon(_entryType), size: 18),
                        label: Text(_entryTypeLabel(_entryType)),
                      ),
                      const Spacer(),
                      if (!canSend)
                        Text(
                          'الجلسة مغلقة',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: canSend,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!canSend || _sending) return;
                            _sendEntry();
                          },
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: canSend
                                ? 'أضف فكرة جديدة...'
                                : 'الجلسة مغلقة، لا يمكن الإرسال',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: (_sending || !canSend) ? null : _sendEntry,
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _TypeItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

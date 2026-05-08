import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_live_quizzes.dart';
import 'package:sign_education/data/models/live_quiz_entry_model.dart';
import 'package:sign_education/data/models/live_quiz_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherLiveQuizRoomPage extends StatefulWidget {
  final LiveQuizModel quiz;

  const TeacherLiveQuizRoomPage({super.key, required this.quiz});

  @override
  State<TeacherLiveQuizRoomPage> createState() => _TeacherLiveQuizRoomPageState();
}

class _TeacherLiveQuizRoomPageState extends State<TeacherLiveQuizRoomPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  List<LiveQuizEntryModel> _entries = [];
  bool _loading = true;
  bool _closing = false;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _status = widget.quiz.status;
    _loadEntries();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    final quizId = widget.quiz.quizId;
    if (quizId == null) return;

    _channel = _supabase.channel('live_quiz_entries_teacher_$quizId');
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
            final entry = LiveQuizEntryModel.fromMap(payload.newRecord);
            if (!mounted) return;
            setState(() => _entries = [..._entries, entry]);
          },
        )
        .subscribe();
  }

  Future<void> _closeQuiz() async {
    if (_status == 'closed') return;
    setState(() => _closing = true);
    try {
      await DbHelperLiveQuizzes.closeQuiz(widget.quiz.quizId!);
      if (!mounted) return;
      setState(() => _status = 'closed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إغلاق الاختبار المباشر')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إغلاق الاختبار: $e')),
      );
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          centerTitle: true,
          actions: [
            if (_status == 'active')
              TextButton(
                onPressed: _closing ? null : _closeQuiz,
                child: const Text('إغلاق'),
              ),
          ],
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
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            _status == 'active' ? 'مباشر الآن' : 'منتهي',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(label: Text('مساهمات: ${_entries.length}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.quiz.promptText,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
                  ? const Center(child: Text('لا توجد مساهمات بعد'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          child: ListTile(
                            title: Text(entry.entryText),
                            subtitle: Text(
                              '${entry.studentName} • ${entry.entryType}',
                            ),
                            leading: const Icon(Icons.bolt_outlined),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


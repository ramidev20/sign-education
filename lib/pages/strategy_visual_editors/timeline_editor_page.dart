import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:uuid/uuid.dart';

class TimelineEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const TimelineEditorPage({super.key, required this.strategy});

  @override
  State<TimelineEditorPage> createState() => _TimelineEditorPageState();
}

class _TimelineEditorPageState extends State<TimelineEditorPage> {
  bool _saving = false;
  late String _title;
  late List<Map<String, dynamic>> _events;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _title = (json['content']?.toString().trim().isNotEmpty ?? false)
        ? json['content'].toString()
        : 'الخط الزمني';

    final nodes = (json['nodes'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _events = nodes
        .where((e) => (e['date']?.toString().isNotEmpty ?? false))
        .toList();
  }

  void _add() {
    setState(() {
      _events.add({
        'id': const Uuid().v4(),
        'date': 'YYYY/MM/DD',
        'content': 'حدث جديد',
        'nodes': <dynamic>[],
      });
    });
  }

  void _remove(int index) {
    setState(() => _events.removeAt(index));
  }

  Future<void> _editEvent(int index) async {
    final e = _events[index];
    final date = TextEditingController(text: e['date']?.toString() ?? '');
    final content =
        TextEditingController(text: e['content']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الحدث'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: date,
              decoration: const InputDecoration(
                labelText: 'التاريخ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: content,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الحدث',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() {
      e['date'] = date.text.trim();
      e['content'] = content.text.trim();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'id': 'root',
          'content': _title,
          'nodes': _events,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محرّر الخط الزمني'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'إضافة',
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: 'حفظ',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: TextEditingController(text: _title),
                onChanged: (v) => _title = v,
                decoration: const InputDecoration(
                  labelText: 'عنوان الخط الزمني',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _events.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _events.removeAt(oldIndex);
                    _events.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final e = _events[index];
                  return Card(
                    key: ValueKey('t-${e['id'] ?? index}'),
                    child: ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(e['content']?.toString() ?? ''),
                      subtitle: Text(e['date']?.toString() ?? ''),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _editEvent(index),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            onPressed: () => _remove(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                      onTap: () => _editEvent(index),
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


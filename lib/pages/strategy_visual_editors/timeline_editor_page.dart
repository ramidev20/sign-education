import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:uuid/uuid.dart';

class TimelineEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const TimelineEditorPage({super.key, required this.strategy});

  @override
  State<TimelineEditorPage> createState() => _TimelineEditorPageState();
}

class _TimelineEditorPageState extends State<TimelineEditorPage> {
  bool _saving = false;
  late final TextEditingController _titleController;
  late List<Map<String, dynamic>> _events;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _titleController = TextEditingController(
      text: (json['content']?.toString().trim().isNotEmpty ?? false)
          ? json['content'].toString()
          : '',
    );

    _events = _extractEvents(json);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _extractEvents(Map<String, dynamic> json) {
    final result = <Map<String, dynamic>>[];

    void walk(dynamic raw) {
      if (raw is! Map) return;
      final node = Map<String, dynamic>.from(raw);
      final hasDate = (node['date']?.toString().trim().isNotEmpty ?? false);
      final hasContent =
          (node['content']?.toString().trim().isNotEmpty ?? false);

      if (hasDate || hasContent) {
        result.add({
          'id': (node['id']?.toString().trim().isNotEmpty ?? false)
              ? node['id'].toString().trim()
              : const Uuid().v4(),
          'date': (node['date'] ?? '').toString(),
          'content': (node['content'] ?? '').toString(),
          'nodes': <dynamic>[],
        });
      }

      for (final child in (node['nodes'] as List? ?? const [])) {
        walk(child);
      }
    }

    for (final rootChild in (json['nodes'] as List? ?? const [])) {
      walk(rootChild);
    }

    return result;
  }

  void _add() {
    final strings = AppStrings.read(context);
    setState(() {
      _events.add({
        'id': const Uuid().v4(),
        'date': strings.tr('strategy_visual.timeline.date_placeholder'),
        'content': strings.tr('strategy_visual.timeline.new_event'),
        'nodes': <dynamic>[],
      });
    });
  }

  void _remove(int index) {
    setState(() => _events.removeAt(index));
  }

  Future<void> _editEvent(int index) async {
    final strings = AppStrings.read(context);
    final e = _events[index];
    final date = TextEditingController(text: e['date']?.toString() ?? '');
    final content = TextEditingController(text: e['content']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.tr('strategy_visual.timeline.edit_event')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: date,
              decoration: InputDecoration(
                labelText: strings.tr('strategy_visual.timeline.date'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: content,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: strings.tr('strategy_visual.timeline.event'),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.tr('strategy_visual.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.tr('strategy_visual.save')),
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

  void _sortByDate() {
    int rank(String value) {
      final text = value.trim();
      if (text.isEmpty) return 1 << 30;

      final parsed = DateTime.tryParse(text.replaceAll('/', '-'));
      if (parsed != null) return parsed.millisecondsSinceEpoch;

      final numbers = RegExp(r'\d+')
          .allMatches(text)
          .map((m) => int.tryParse(m.group(0) ?? '') ?? 0)
          .toList();
      if (numbers.isEmpty) return 1 << 30;

      if (numbers.length == 1) {
        return DateTime(numbers[0], 1, 1).millisecondsSinceEpoch;
      }

      final year = numbers[0];
      final month = numbers.length > 1 ? numbers[1].clamp(1, 12).toInt() : 1;
      final day = numbers.length > 2 ? numbers[2].clamp(1, 28).toInt() : 1;
      return DateTime(year, month, day).millisecondsSinceEpoch;
    }

    setState(() {
      _events.sort(
        (a, b) => rank((a['date'] ?? '').toString())
            .compareTo(rank((b['date'] ?? '').toString())),
      );
    });
  }

  Future<void> _save() async {
    final strings = AppStrings.read(context);
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'id': 'root',
          'content': _titleController.text.trim().isEmpty
              ? strings.tr('strategy.timeline')
              : _titleController.text.trim(),
          'nodes': _events,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('strategy_visual.save_failed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.tr('strategy_visual.timeline.title')),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: strings.tr('strategy_visual.timeline.sort_by_date'),
              onPressed: _saving ? null : _sortByDate,
              icon: const Icon(Icons.sort),
            ),
            IconButton(
              tooltip: strings.tr('strategy_visual.add'),
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: strings.tr('strategy_visual.save'),
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
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.timeline.title_label'),
                  border: const OutlineInputBorder(),
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
                      title: Text((e['content'] ?? '').toString()),
                      subtitle: Text((e['date'] ?? '').toString()),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: strings.tr('strategy_visual.edit'),
                            onPressed: () => _editEvent(index),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: strings.tr('strategy_visual.delete'),
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

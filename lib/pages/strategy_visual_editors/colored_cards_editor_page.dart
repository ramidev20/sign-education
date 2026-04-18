import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class ColoredCardsEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const ColoredCardsEditorPage({super.key, required this.strategy});

  @override
  State<ColoredCardsEditorPage> createState() => _ColoredCardsEditorPageState();
}

class _ColoredCardsEditorPageState extends State<ColoredCardsEditorPage> {
  bool _saving = false;
  late String _title;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _title = (json['title']?.toString().trim().isNotEmpty ?? false)
        ? json['title'].toString()
        : 'البطاقات الملونة';

    _cards = (json['conceptCards'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void _add() {
    setState(() {
      _cards.add({
        'title': 'بطاقة جديدة',
        'type': 'مفهوم',
        'content': '',
        'color': '#60A5FA',
      });
    });
  }

  void _remove(int index) => setState(() => _cards.removeAt(index));

  Future<void> _edit(int index) async {
    final c = _cards[index];
    final title = TextEditingController(text: c['title']?.toString() ?? '');
    final type = TextEditingController(text: c['type']?.toString() ?? '');
    final content = TextEditingController(text: c['content']?.toString() ?? '');
    final color = TextEditingController(text: c['color']?.toString() ?? '#60A5FA');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل البطاقة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: type,
                decoration: const InputDecoration(
                  labelText: 'النوع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: color,
                decoration: const InputDecoration(
                  labelText: 'اللون (HEX مثل #60A5FA)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: content,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'المحتوى',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
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
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() {
      c['title'] = title.text.trim();
      c['type'] = type.text.trim();
      c['content'] = content.text.trim();
      c['color'] = color.text.trim().isEmpty ? '#60A5FA' : color.text.trim();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'title': _title,
          'conceptCards': _cards,
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
          title: const Text('محرّر البطاقات الملونة'),
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
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _cards.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _cards.removeAt(oldIndex);
                    _cards.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final c = _cards[index];
                  return Card(
                    key: ValueKey('c-$index'),
                    child: ListTile(
                      leading: const Icon(Icons.crop_landscape_outlined),
                      title: Text(c['title']?.toString() ?? ''),
                      subtitle: Text(c['type']?.toString() ?? ''),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _edit(index),
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
                      onTap: () => _edit(index),
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


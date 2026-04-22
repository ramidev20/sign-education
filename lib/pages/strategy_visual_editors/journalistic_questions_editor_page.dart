import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class JournalisticQuestionsEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const JournalisticQuestionsEditorPage({super.key, required this.strategy});

  @override
  State<JournalisticQuestionsEditorPage> createState() =>
      _JournalisticQuestionsEditorPageState();
}

class _JournalisticQuestionsEditorPageState
    extends State<JournalisticQuestionsEditorPage> {
  bool _saving = false;
  late List<Map<String, dynamic>> _items;

  static const _types = <String>[
    'what',
    'when',
    'where',
    'why',
    'how',
    'who',
  ];

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _items = (json['journalisticQuestions'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (_items.isEmpty) {
      _items = [
        {'question': '', 'type': 'what', 'answer': ''},
      ];
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {'journalisticQuestions': _items},
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final q = TextEditingController(text: item['question']?.toString() ?? '');
    final a = TextEditingController(text: item['answer']?.toString() ?? '');
    var type = item['type']?.toString() ?? 'what';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تعديل السؤال',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _types.contains(type) ? type : _types.first,
                      decoration: const InputDecoration(
                        labelText: 'النوع',
                        border: OutlineInputBorder(),
                      ),
                      items: _types
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => type = v ?? 'what'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: q,
                      decoration: const InputDecoration(
                        labelText: 'السؤال',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: a,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'الإجابة',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('حفظ'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (ok != true) return;
    setState(() {
      item['type'] = type;
      item['question'] = q.text.trim();
      item['answer'] = a.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محرّر الأسئلة الصحفية'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'إضافة',
              onPressed: _saving
                  ? null
                  : () => setState(
                        () => _items.add(
                          {'question': '', 'type': 'what', 'answer': ''},
                        ),
                      ),
              icon: const Icon(Icons.add_rounded),
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
        body: ReorderableListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final item = _items[index];
            final q = item['question']?.toString() ?? '';
            final t = item['type']?.toString() ?? '';
            return Card(
              key: ValueKey('jq-$index-$t-$q'),
              child: ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: Text(q.isEmpty ? 'سؤال جديد' : q),
                subtitle: Text('النوع: $t'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'تعديل',
                      onPressed: () => _editItem(index),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed: _items.length <= 1
                          ? null
                          : () => setState(() => _items.removeAt(index)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
                onTap: () => _editItem(index),
              ),
            );
          },
        ),
      ),
    );
  }
}


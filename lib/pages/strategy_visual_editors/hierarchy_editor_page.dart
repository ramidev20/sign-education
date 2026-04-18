import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class HierarchyEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const HierarchyEditorPage({super.key, required this.strategy});

  @override
  State<HierarchyEditorPage> createState() => _HierarchyEditorPageState();
}

class _HierarchyEditorPageState extends State<HierarchyEditorPage> {
  bool _saving = false;
  late String _title;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _title = (json['title']?.toString().trim().isNotEmpty ?? false)
        ? json['title'].toString()
        : 'التدرج الهرمي';
    _items = (json['hierarchyMap'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final title = TextEditingController(text: item['title']?.toString() ?? '');
    final desc =
        TextEditingController(text: item['description']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المستوى'),
        content: Column(
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
              controller: desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الوصف',
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
      item['title'] = title.text.trim();
      item['description'] = desc.text.trim();
    });
  }

  void _add() {
    setState(() {
      _items.add({
        'level': _items.length + 1,
        'title': 'مستوى جديد',
        'description': '',
      });
    });
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (var i = 0; i < _items.length; i++) {
        _items[i]['level'] = i + 1;
      }
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'title': _title,
          'hierarchyMap': _items,
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
          title: const Text('محرّر التدرج الهرمي'),
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
                  return Card(
                    key: ValueKey('h-$index'),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(item['title']?.toString() ?? ''),
                      subtitle: Text(
                        item['description']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                            onPressed: () => _remove(index),
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
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/utils/app_strings.dart';

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
        : '';
    _items = (json['hierarchyMap'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _editItem(int index) async {
    final strings = AppStrings.read(context);
    final item = _items[index];
    final title = TextEditingController(text: item['title']?.toString() ?? '');
    final desc =
        TextEditingController(text: item['description']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.tr('strategy_visual.hierarchy.edit_level')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(
                labelText: strings.tr('strategy_visual.title'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: strings.tr('strategy_visual.description'),
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
      item['title'] = title.text.trim();
      item['description'] = desc.text.trim();
    });
  }

  void _add() {
    final strings = AppStrings.read(context);
    setState(() {
      _items.add({
        'level': _items.length + 1,
        'title': strings.tr('strategy_visual.hierarchy.new_level'),
        'description': '',
      });
    });
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _save() async {
    final strings = AppStrings.read(context);
    setState(() => _saving = true);
    try {
      final titleToSave =
          _title.trim().isEmpty ? strings.tr('strategy.hierarchy') : _title.trim();
      for (var i = 0; i < _items.length; i++) {
        _items[i]['level'] = i + 1;
      }
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'title': titleToSave,
          'hierarchyMap': _items,
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
    final displayTitle =
        _title.trim().isEmpty ? strings.tr('strategy.hierarchy') : _title;
    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.tr('strategy_visual.hierarchy.title')),
          centerTitle: true,
          actions: [
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
                controller: TextEditingController(text: displayTitle),
                onChanged: (v) => _title = v,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.title'),
                  border: const OutlineInputBorder(),
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
                            tooltip: strings.tr('strategy_visual.edit'),
                            onPressed: () => _editItem(index),
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

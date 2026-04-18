import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class ComparisonTableEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const ComparisonTableEditorPage({super.key, required this.strategy});

  @override
  State<ComparisonTableEditorPage> createState() =>
      _ComparisonTableEditorPageState();
}

class _ComparisonTableEditorPageState extends State<ComparisonTableEditorPage> {
  bool _saving = false;
  late String _title;
  late List<Map<String, dynamic>> _table;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _title = (json['title']?.toString().trim().isNotEmpty ?? false)
        ? json['title'].toString()
        : 'جدول المقارنة';

    _table = (json['comparisonTable'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final options = <String>{};
    for (final row in _table) {
      final criterion = row.keys.isEmpty ? null : row.keys.first;
      if (criterion == null) continue;
      final values = row[criterion];
      if (values is Map) {
        options.addAll(values.keys.map((e) => e.toString()));
      }
    }
    _options = options.toList();
    if (_options.isEmpty) {
      _options = ['الخيار 1', 'الخيار 2'];
    }
  }

  void _addOption() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عمود'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'اسم العمود',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _options.add(name));
  }

  void _removeOption(String opt) {
    setState(() {
      _options.remove(opt);
      for (final row in _table) {
        final criterion = row.keys.first;
        final values = (row[criterion] as Map?)?.cast<String, dynamic>() ?? {};
        values.remove(opt);
        row[criterion] = values;
      }
    });
  }

  void _addCriterion() {
    setState(() {
      _table.add({
        'معيار جديد': {for (final o in _options) o: ''},
      });
    });
  }

  void _removeCriterion(int index) => setState(() => _table.removeAt(index));

  Future<void> _editCell({
    required int rowIndex,
    required String criterion,
    required String option,
  }) async {
    final values = (_table[rowIndex][criterion] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final c = TextEditingController(text: values[option]?.toString() ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل: $criterion / $option'),
        content: TextField(
          controller: c,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() {
      values[option] = result;
      _table[rowIndex][criterion] = values;
    });
  }

  Future<void> _renameCriterion(int index) async {
    final row = _table[index];
    if (row.keys.isEmpty) return;
    final old = row.keys.first.toString();
    final c = TextEditingController(text: old);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المعيار'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty) return;
    setState(() {
      final values = row[old];
      _table[index] = {next: values};
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Ensure each row contains all options
      for (final row in _table) {
        if (row.keys.isEmpty) continue;
        final criterion = row.keys.first.toString();
        final values = (row[criterion] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        for (final o in _options) {
          values.putIfAbsent(o, () => '');
        }
        row[criterion] = values;
      }

      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'title': _title,
          'comparisonTable': _table,
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
          title: const Text('محرّر جدول المقارنة'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'إضافة معيار',
              onPressed: _saving ? null : _addCriterion,
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              tooltip: 'إضافة عمود',
              onPressed: _saving ? null : _addOption,
              icon: const Icon(Icons.view_column_rounded),
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
            SizedBox(
              height: 54,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: _options
                    .map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: InputChip(
                          label: Text(o),
                          onDeleted: _options.length <= 1
                              ? null
                              : () => _removeOption(o),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _table.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _table.removeAt(oldIndex);
                    _table.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final row = _table[index];
                  final criterion = row.keys.isEmpty ? '' : row.keys.first.toString();
                  final values =
                      (row[criterion] as Map?)?.cast<String, dynamic>() ?? {};
                  return Card(
                    key: ValueKey('cmp-$index-$criterion'),
                    child: ExpansionTile(
                      title: Text(criterion),
                      subtitle: const Text('اضغط لتعديل الخلايا'),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'تعديل المعيار',
                            onPressed: () => _renameCriterion(index),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف المعيار',
                            onPressed: () => _removeCriterion(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                      children: [
                        for (final o in _options)
                          ListTile(
                            title: Text(o),
                            subtitle: Text(values[o]?.toString() ?? '-'),
                            onTap: () => _editCell(
                              rowIndex: index,
                              criterion: criterion,
                              option: o,
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
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


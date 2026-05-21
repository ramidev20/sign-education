import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/utils/app_strings.dart';

class EducationalStoryEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const EducationalStoryEditorPage({super.key, required this.strategy});

  @override
  State<EducationalStoryEditorPage> createState() =>
      _EducationalStoryEditorPageState();
}

class _EducationalStoryEditorPageState extends State<EducationalStoryEditorPage> {
  bool _saving = false;

  late Map<String, dynamic> _story;
  late TextEditingController _title;
  late TextEditingController _setting;
  late TextEditingController _moral;
  late List<String> _characters;
  late List<String> _plot;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    final raw = json['educationalStory'];
    _story = raw is Map ? Map<String, dynamic>.from(raw) : {};

    _title = TextEditingController(text: _story['title']?.toString() ?? '');
    _setting = TextEditingController(text: _story['setting']?.toString() ?? '');
    _moral = TextEditingController(text: _story['moral']?.toString() ?? '');
    _characters = (_story['characters'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    _plot = (_story['plot'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (_plot.isEmpty) _plot = [''];
  }

  @override
  void dispose() {
    _title.dispose();
    _setting.dispose();
    _moral.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = AppStrings.read(context);
    setState(() => _saving = true);
    try {
      final payload = {
        'educationalStory': {
          'title': _title.text.trim(),
          'setting': _setting.text.trim(),
          'characters': _characters,
          'plot': _plot.where((e) => e.trim().isNotEmpty).toList(),
          'moral': _moral.text.trim(),
        },
      };
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: payload,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('strategy_visual.error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCharacter() async {
    final strings = AppStrings.read(context);
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.tr('strategy_visual.story.add_character_title')),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.tr('strategy_visual.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(strings.tr('strategy_visual.add')),
          ),
        ],
      ),
    );
    if (v == null || v.trim().isEmpty) return;
    setState(() => _characters.add(v.trim()));
  }

  Future<void> _addPlot() async {
    setState(() => _plot.add(''));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.tr('strategy_visual.story.title')),
          centerTitle: true,
          actions: [
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.story.story_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _setting,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.story.place_time'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'الشخصيات',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: strings.tr('strategy_visual.add'),
                            onPressed: _saving ? null : _addCharacter,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_characters.isEmpty)
                        Text(strings.tr('strategy_visual.story.no_characters_yet'))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in _characters)
                              InputChip(
                                label: Text(c),
                                onDeleted:
                                    _saving ? null : () => setState(() => _characters.remove(c)),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'أحداث القصة',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: strings.tr('strategy_visual.story.add_paragraph'),
                            onPressed: _saving ? null : _addPlot,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _plot.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _plot.removeAt(oldIndex);
                            _plot.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          return ListTile(
                            key: ValueKey('plot-$index'),
                            leading: const Icon(Icons.drag_handle),
                            title: TextFormField(
                              enabled: !_saving,
                              onChanged: (v) => _plot[index] = v,
                              decoration: InputDecoration(
                                labelText: strings
                                    .tr('strategy_visual.story.paragraph_n')
                                    .replaceAll('{n}', '${index + 1}'),
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              initialValue: _plot[index],
                            ),
                            trailing: IconButton(
                              tooltip: strings.tr('strategy_visual.delete'),
                              onPressed: _saving || _plot.length <= 1
                                  ? null
                                  : () => setState(() => _plot.removeAt(index)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _moral,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.story.moral'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

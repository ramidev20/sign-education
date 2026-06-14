import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/strategy_catalog.dart';
import 'package:sign_education/utils/strategy_functions.dart';

class LessonStrategyEditorPage extends StatefulWidget {
  final String lessonId;
  final LessonStrategyModel? existing;
  final String? initialLessonText;

  const LessonStrategyEditorPage({
    super.key,
    required this.lessonId,
    this.existing,
    this.initialLessonText,
  });

  @override
  State<LessonStrategyEditorPage> createState() =>
      _LessonStrategyEditorPageState();
}

class _LessonStrategyEditorPageState extends State<LessonStrategyEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _titleController = TextEditingController();

  bool _loading = false;
  String? _strategyType;

  @override
  void initState() {
    super.initState();
    _strategyType = widget.existing?.strategyType;
    _titleController.text = widget.existing?.title ?? '';
    _textController.text = widget.initialLessonText?.trim() ?? '';
    _loadLessonTextIfNeeded();
  }

  Future<void> _loadLessonTextIfNeeded() async {
    if (_textController.text.trim().isNotEmpty) return;
    try {
      final lesson = await DbHelperLessons.getLessonById(widget.lessonId);
      final text = lesson?.description?.trim() ?? '';
      if (!mounted || text.isEmpty) return;
      setState(() => _textController.text = text);
    } catch (_) {
      // best-effort prefill
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _generate(String type, String text) async {
    switch (type) {
      case 'type_0':
        return await generateMindMapFromText(text);
      case 'type_5':
        return await generateTimeLineFromText(text);
      case 'type_6':
        return await generateHierarchyFromText(text);
      case 'type_9':
        return await generateColoredCardsFromText(text);
      case 'type_10':
        return await generateComparisonTableFromText(text);
      case 'type_11':
        return await generateTriangleFromText(text);
      case 'type_12':
        return await generatesixHatFromText(text);
      case 'type_13':
        return await generateJournalisticQuestionsFromText(text);
      case 'type_14':
        return await generateEducationalStoryFromText(text);
      default:
        throw Exception('Unsupported strategy: $type');
    }
  }

  Future<void> _submit() async {
    final strings = AppStrings.read(context);

    if (!_formKey.currentState!.validate()) return;
    final type = _strategyType;
    if (type == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    try {
      final json = await _generate(type, text);
      final jsonWithResultType = Map<String, dynamic>.from(json)
        ..['_result_type'] = 'cardboard';
      final title = _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();

      if (widget.existing == null) {
        await DbHelperLessonStrategies.createStrategy(
          lessonId: widget.lessonId,
          strategyType: type,
          contentJson: jsonWithResultType,
          title: title,
        );
      } else {
        await DbHelperLessonStrategies.updateStrategy(
          lessonStrategyId: widget.existing!.lessonStrategyId,
          contentJson: jsonWithResultType,
          title: title,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('app.error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? strings.tr('lesson_strategy_editor.edit_title')
              : strings.tr('lesson_strategy_editor.add_title'),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _strategyType,
                    decoration: InputDecoration(
                      labelText: strings.tr('lesson_strategy_editor.strategy'),
                      border: const OutlineInputBorder(),
                    ),
                    items: StrategyCatalog.all
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.label(strings)),
                          ),
                        )
                        .toList(),
                    onChanged:
                        isEdit ? null : (v) => setState(() => _strategyType = v),
                    validator: (v) => v == null
                        ? strings.tr('lesson_strategy_editor.validation.pick')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: strings.tr('lesson_strategy_editor.custom_title'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _textController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: strings.tr('lesson_strategy_editor.lesson_text'),
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? strings.tr('lesson_strategy_editor.validation.text')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _loading
                          ? strings.tr('lesson_strategy_editor.generating')
                          : (isEdit
                              ? strings.tr('lesson_strategy_editor.update')
                              : strings.tr('lesson_strategy_editor.create')),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.tr('lesson_strategy_editor.note'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
        ],
      ),
    );
  }
}


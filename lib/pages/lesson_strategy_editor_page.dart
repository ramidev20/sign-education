import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
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
      // ignore: best-effort prefill
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
    if (!_formKey.currentState!.validate()) return;
    final type = _strategyType;
    if (type == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    try {
      final json = await _generate(type, text);
      final title = _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();

      if (widget.existing == null) {
        await DbHelperLessonStrategies.createStrategy(
          lessonId: widget.lessonId,
          strategyType: type,
          contentJson: json,
          title: title,
        );
      } else {
        await DbHelperLessonStrategies.updateStrategy(
          lessonStrategyId: widget.existing!.lessonStrategyId,
          contentJson: json,
          title: title,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'تحديث الاستراتيجية' : 'إضافة استراتيجية'),
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
                      value: _strategyType,
                      decoration: const InputDecoration(
                        labelText: 'الاستراتيجية',
                        border: OutlineInputBorder(),
                      ),
                      items: StrategyCatalog.all
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged:
                          isEdit ? null : (v) => setState(() => _strategyType = v),
                      validator: (v) =>
                          v == null ? 'الرجاء اختيار الاستراتيجية' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _textController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'نص الدرس (الصقه هنا)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'أدخل نص الدرس'
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
                        _loading ? 'جارٍ الإنشاء...' : (isEdit ? 'تحديث' : 'إنشاء'),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ملاحظة: سيتم إنشاء JSON وحفظه للطلاب.',
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
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

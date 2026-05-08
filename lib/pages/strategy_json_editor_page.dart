import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/pages/lesson_strategy_viewer.dart';

class StrategyJsonEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;

  const StrategyJsonEditorPage({super.key, required this.strategy});

  @override
  State<StrategyJsonEditorPage> createState() => _StrategyJsonEditorPageState();
}

class _StrategyJsonEditorPageState extends State<StrategyJsonEditorPage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.strategy.contentJson),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _hint {
    switch (widget.strategy.strategyType) {
      case 'type_0':
        return 'MindMap: يمكنك تعديل أسماء العقد والروابط (edges) داخل JSON.';
      case 'type_5':
        return 'Timeline: عدّل الأحداث (العنوان/الوصف/الترتيب) داخل JSON.';
      case 'type_6':
        return 'Hierarchy: عدّل العناصر والتفرعات داخل JSON.';
      case 'type_9':
        return 'Colored Cards: عدّل البطاقات/العناوين/المحتوى داخل JSON.';
      case 'type_10':
        return 'Comparison Table: عدّل الأعمدة/الصفوف/الخلايا داخل JSON.';
      case 'type_11':
        return 'Triangle: عدّل الأجزاء داخل JSON.';
      case 'type_13':
        return 'الأسئلة الصحفية: عدّل الأسئلة والأجوبة (من/ماذا/متى/أين/لماذا/كيف).';
      case 'type_14':
        return 'القصة التعليمية: عدّل العنوان والشخصيات والأحداث والخلاصة.';
      default:
        return 'عدّل JSON ثم احفظ.';
    }
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_controller.text);
      _controller.text = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      // ignore; user will see validation on save
    }
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON غير صالح: $e')),
      );
      return;
    }

    if (decoded is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يكون JSON من نوع Object (Map)')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: Map<String, dynamic>.from(decoded as Map),
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
    final title = (widget.strategy.title?.trim().isNotEmpty ?? false)
        ? widget.strategy.title!.trim()
        : strategyLabelForType(widget.strategy.strategyType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تعديل يدوي: $title'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تنسيق JSON',
              onPressed: _saving ? null : _formatJson,
              icon: const Icon(Icons.format_align_left_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _hint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Strategy JSON',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

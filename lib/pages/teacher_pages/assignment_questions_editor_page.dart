import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AssignmentQuestionsEditorPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialQuestions;

  const AssignmentQuestionsEditorPage({
    super.key,
    required this.initialQuestions,
  });

  @override
  State<AssignmentQuestionsEditorPage> createState() =>
      _AssignmentQuestionsEditorPageState();
}

class _AssignmentQuestionsEditorPageState
    extends State<AssignmentQuestionsEditorPage> {
  final List<_QuestionDraft> _drafts = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestions.isEmpty) {
      _drafts.add(_QuestionDraft(type: 'mcq'));
      return;
    }

    for (final q in widget.initialQuestions) {
      _drafts.add(_QuestionDraft.fromJson(q));
    }
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _drafts.add(_QuestionDraft(type: 'mcq')));
  }

  void _removeQuestion(int index) {
    if (_drafts.length <= 1) return;
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  void _confirm() {
    final payload = <Map<String, dynamic>>[];
    for (final d in _drafts) {
      final json = d.toJson();
      if (json == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أكمل جميع الحقول المطلوبة في الأسئلة')),
        );
        return;
      }
      payload.add(json);
    }

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أسئلة الواجب'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _confirm,
              child: Text(
                'تأكيد',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'إدارة الأسئلة',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('سؤال'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._drafts.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;
              return _AssignmentQuestionCard(
                index: index,
                question: draft,
                onRemove: () => _removeQuestion(index),
              );
            }),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('حفظ الأسئلة'),
          ),
        ),
      ),
    );
  }
}

class _AssignmentQuestionCard extends StatefulWidget {
  final int index;
  final _QuestionDraft question;
  final VoidCallback onRemove;

  const _AssignmentQuestionCard({
    required this.index,
    required this.question,
    required this.onRemove,
  });

  @override
  State<_AssignmentQuestionCard> createState() => _AssignmentQuestionCardState();
}

class _AssignmentQuestionCardState extends State<_AssignmentQuestionCard> {
  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isMcq = q.type == 'mcq';
    final isMultiSelect = q.type == 'multi_select';
    final isNumber = q.type == 'number';

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('السؤال ${widget.index + 1}')),
                DropdownButton<String>(
                  value: q.type,
                  items: const [
                    DropdownMenuItem(
                      value: 'mcq',
                      child: Text('اختيار من متعدد'),
                    ),
                    DropdownMenuItem(
                      value: 'multi_select',
                      child: Text('تعدد الاختيارات'),
                    ),
                    DropdownMenuItem(
                      value: 'true_false',
                      child: Text('صح / خطأ'),
                    ),
                    DropdownMenuItem(
                      value: 'short_text',
                      child: Text('إجابة قصيرة'),
                    ),
                    DropdownMenuItem(
                      value: 'paragraph',
                      child: Text('فقرة'),
                    ),
                    DropdownMenuItem(
                      value: 'number',
                      child: Text('رقم'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => q.type = v);
                  },
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextField(
              controller: q.promptController,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
            ),
            if (isNumber) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: q.minNumberController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'أدنى قيمة (اختياري)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: q.maxNumberController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'أقصى قيمة (اختياري)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: q.allowDecimal,
                onChanged: (v) => setState(() => q.allowDecimal = v),
                contentPadding: EdgeInsets.zero,
                title: const Text('السماح بالكسور'),
              ),
            ],
            if (isMcq || isMultiSelect) ...[
              const SizedBox(height: 8),
              ...q.optionsControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'خيار ${index + 1}',
                          ),
                        ),
                      ),
                      if (q.optionsControllers.length > 2)
                        IconButton(
                          onPressed: () => setState(
                            () => q.optionsControllers.removeAt(index),
                          ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => q.optionsControllers.add(TextEditingController()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة خيار'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  String id;
  String type;
  final TextEditingController promptController;
  final List<TextEditingController> optionsControllers;
  final TextEditingController minNumberController;
  final TextEditingController maxNumberController;
  bool allowDecimal;

  _QuestionDraft({
    required this.type,
    String? id,
    String? prompt,
    List<String>? options,
    String? minNumber,
    String? maxNumber,
    bool? allowDecimal,
  })  : id = id ?? const Uuid().v4(),
        promptController = TextEditingController(text: prompt ?? ''),
        optionsControllers = (options == null || options.isEmpty)
            ? [TextEditingController(), TextEditingController()]
            : options.map((o) => TextEditingController(text: o)).toList(),
        minNumberController = TextEditingController(text: minNumber ?? ''),
        maxNumberController = TextEditingController(text: maxNumber ?? ''),
        allowDecimal = allowDecimal ?? true;

  factory _QuestionDraft.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'mcq').toString();
    final prompt = (json['prompt'] ?? '').toString();
    final id = (json['id'] ?? '').toString();
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).toList()
        : const <String>[];
    final minNumber = (json['min'] ?? '').toString();
    final maxNumber = (json['max'] ?? '').toString();
    final allowDecimal = json['allow_decimal'] is bool
        ? (json['allow_decimal'] as bool)
        : true;
    return _QuestionDraft(
      type: type,
      id: id.isEmpty ? null : id,
      prompt: prompt,
      options: options,
      minNumber: minNumber,
      maxNumber: maxNumber,
      allowDecimal: allowDecimal,
    );
  }

  Map<String, dynamic>? toJson() {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) return null;

    final map = <String, dynamic>{
      'id': id,
      'type': type,
      'prompt': prompt,
    };

    if (type == 'mcq' || type == 'multi_select') {
      final options = optionsControllers
          .map((c) => c.text.trim())
          .where((v) => v.isNotEmpty)
          .toList();
      if (options.length < 2) return null;
      map['options'] = options;
    }

    if (type == 'number') {
      map['allow_decimal'] = allowDecimal;

      final minStr = minNumberController.text.trim();
      final maxStr = maxNumberController.text.trim();
      if (minStr.isNotEmpty) {
        final min = double.tryParse(minStr);
        if (min == null) return null;
        map['min'] = min;
      }
      if (maxStr.isNotEmpty) {
        final max = double.tryParse(maxStr);
        if (max == null) return null;
        map['max'] = max;
      }

      final min = map['min'] is num ? (map['min'] as num).toDouble() : null;
      final max = map['max'] is num ? (map['max'] as num).toDouble() : null;
      if (min != null && max != null && min > max) return null;
    }

    return map;
  }

  void dispose() {
    promptController.dispose();
    for (final c in optionsControllers) {
      c.dispose();
    }
    minNumberController.dispose();
    maxNumberController.dispose();
  }
}

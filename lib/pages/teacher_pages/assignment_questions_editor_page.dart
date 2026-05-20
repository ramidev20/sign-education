import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_strings.dart';
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

  AppStrings get _strings =>
      AppStrings(Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestions.isEmpty) {
      _drafts.add(_QuestionDraft(type: 'mcq'));
      return;
    }

    for (final question in widget.initialQuestions) {
      _drafts.add(_QuestionDraft.fromJson(question));
    }
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
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
    final strings = _strings;
    final payload = <Map<String, dynamic>>[];
    for (final draft in _drafts) {
      final json = draft.toJson();
      if (json == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.text(
                'أكمل جميع الحقول المطلوبة في الأسئلة',
                'Complete all required question fields',
                'Completez tous les champs obligatoires des questions',
              ),
            ),
          ),
        );
        return;
      }
      payload.add(json);
    }

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.text('أسئلة الواجب', 'Assignment questions', 'Questions du devoir'),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text(
              strings.text('تأكيد', 'Done', 'Valider'),
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
                  Expanded(
                    child: Text(
                      strings.text('إدارة الأسئلة', 'Manage questions', 'Gerer les questions'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: Text(strings.text('سؤال', 'Question', 'Question')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._drafts.asMap().entries.map((entry) {
            return _AssignmentQuestionCard(
              index: entry.key,
              question: entry.value,
              onRemove: () => _removeQuestion(entry.key),
            );
          }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check_rounded),
          label: Text(strings.text('حفظ الأسئلة', 'Save questions', 'Enregistrer les questions')),
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
    final strings = AppStrings.of(context);
    final question = widget.question;
    final isMcq = question.type == 'mcq';
    final isMultiSelect = question.type == 'multi_select';
    final isNumber = question.type == 'number';

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${strings.text('السؤال', 'Question', 'Question')} ${widget.index + 1}',
                  ),
                ),
                DropdownButton<String>(
                  value: question.type,
                  items: [
                    DropdownMenuItem(
                      value: 'mcq',
                      child: Text(strings.text('اختيار من متعدد', 'Multiple choice', 'Choix multiple')),
                    ),
                    DropdownMenuItem(
                      value: 'multi_select',
                      child: Text(strings.text('تعدد الاختيارات', 'Multi-select', 'Selection multiple')),
                    ),
                    DropdownMenuItem(
                      value: 'true_false',
                      child: Text(strings.text('صح / خطأ', 'True / False', 'Vrai / Faux')),
                    ),
                    DropdownMenuItem(
                      value: 'short_text',
                      child: Text(strings.text('إجابة قصيرة', 'Short answer', 'Reponse courte')),
                    ),
                    DropdownMenuItem(
                      value: 'paragraph',
                      child: Text(strings.text('فقرة', 'Paragraph', 'Paragraphe')),
                    ),
                    DropdownMenuItem(
                      value: 'number',
                      child: Text(strings.text('رقم', 'Number', 'Nombre')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => question.type = value);
                  },
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextField(
              controller: question.promptController,
              decoration: InputDecoration(
                labelText: strings.text('نص السؤال', 'Question text', 'Texte de la question'),
              ),
            ),
            if (isNumber) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: question.minNumberController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        labelText: strings.text(
                          'أدنى قيمة (اختياري)',
                          'Minimum value (optional)',
                          'Valeur minimale (optionnel)',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: question.maxNumberController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        labelText: strings.text(
                          'أقصى قيمة (اختياري)',
                          'Maximum value (optional)',
                          'Valeur maximale (optionnel)',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: question.allowDecimal,
                onChanged: (value) => setState(() => question.allowDecimal = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.text('السماح بالكسور', 'Allow decimals', 'Autoriser les decimales'),
                ),
              ),
            ],
            if (isMcq || isMultiSelect) ...[
              const SizedBox(height: 8),
              ...question.optionsControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText:
                                '${strings.text('خيار', 'Option', 'Option')} ${entry.key + 1}',
                          ),
                        ),
                      ),
                      if (question.optionsControllers.length > 2)
                        IconButton(
                          onPressed: () => setState(
                            () => question.optionsControllers.removeAt(entry.key),
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
                    () => question.optionsControllers.add(TextEditingController()),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    strings.text('إضافة خيار', 'Add option', 'Ajouter une option'),
                  ),
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
            : options.map((option) => TextEditingController(text: option)).toList(),
        minNumberController = TextEditingController(text: minNumber ?? ''),
        maxNumberController = TextEditingController(text: maxNumber ?? ''),
        allowDecimal = allowDecimal ?? true;

  factory _QuestionDraft.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'mcq').toString();
    final prompt = (json['prompt'] ?? '').toString();
    final id = (json['id'] ?? '').toString();
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.map((item) => item.toString()).toList()
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
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
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
    for (final controller in optionsControllers) {
      controller.dispose();
    }
    minNumberController.dispose();
    maxNumberController.dispose();
  }
}

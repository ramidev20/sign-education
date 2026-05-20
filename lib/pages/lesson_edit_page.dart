import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/utils/app_strings.dart';

class LessonEditPage extends StatefulWidget {
  final LessonModel lesson;
  const LessonEditPage({super.key, required this.lesson});

  @override
  State<LessonEditPage> createState() => _LessonEditPageState();
}

class _LessonEditPageState extends State<LessonEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  late String _title;
  late String _subject;
  bool _saving = false;

  static const _subjects = <String>[
    'math',
    'physics',
    'chemistry',
    'natural_sciences',
    'history',
    'geography',
    'philosophy',
    'arabic',
    'french',
    'english',
  ];

  @override
  void initState() {
    super.initState();
    _title = widget.lesson.title ?? '';
    _subject = widget.lesson.subject;
    _contentController.text = widget.lesson.description ?? '';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);

    if (!_formKey.currentState!.validate()) return;
    final id = widget.lesson.lessonId;
    if (id == null || id.isEmpty) return;

    setState(() => _saving = true);
    try {
      await DbHelperLessons.updateLesson(id, {
        'title': _title.trim(),
        'subject': _subject,
        'description': _contentController.text.trim(),
      });

      final updated = await DbHelperLessons.getLessonById(id);
      if (!mounted) return;
      Navigator.pop(context, updated ?? widget.lesson);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('app.error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('lesson_edit.title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: strings.tr('lesson_edit.lesson_title'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _title = v,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? strings.tr('lesson_edit.validation.title')
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: InputDecoration(
                  labelText: strings.tr('lesson_edit.subject'),
                  border: const OutlineInputBorder(),
                ),
                items: _subjects
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(strings.tr('subject.$id')),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _subject = v ?? _subject),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: strings.tr('lesson_edit.lesson_text'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? strings.tr('lesson_edit.validation.text')
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? strings.tr('lesson_edit.saving')
                      : strings.tr('app.save'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


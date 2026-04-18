import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/lesson_model.dart';

class LessonEditPage extends StatefulWidget {
  final LessonModel lesson;
  const LessonEditPage({super.key, required this.lesson});

  @override
  State<LessonEditPage> createState() => _LessonEditPageState();
}

class _LessonEditPageState extends State<LessonEditPage> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _subject;
  String? _description;
  String? _filePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = widget.lesson.title ?? '';
    _subject = widget.lesson.subject;
    _description = widget.lesson.description;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["pdf", "doc", "docx"],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _filePath = result.files.single.path!);
    }
  }

  Future<String?> _uploadFileFromPath() async {
    if (_filePath == null || _filePath!.isEmpty) return null;
    final file = File(_filePath!);
    if (!await file.exists()) return null;

    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}";

    await Supabase.instance.client.storage.from('lessons').upload(fileName, file);
    return Supabase.instance.client.storage.from('lessons').getPublicUrl(fileName);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.lesson.lessonId == null || widget.lesson.lessonId!.isEmpty) return;

    setState(() => _saving = true);
    try {
      final newUrl = await _uploadFileFromPath();

      await DbHelperLessons.updateLesson(
        widget.lesson.lessonId!,
        {
          'title': _title,
          'subject': _subject,
          'description': _description,
        },
        oldFileUrl: widget.lesson.fileUrl,
        newFileUrl: newUrl,
      );

      final updated = await DbHelperLessons.getLessonById(widget.lesson.lessonId!);
      if (!mounted) return;
      Navigator.pop(context, updated ?? widget.lesson);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التعديلات: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الدرس'),
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
                  decoration: const InputDecoration(
                    labelText: 'عنوان الدرس',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _title = v,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل العنوان' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _subject,
                  decoration: const InputDecoration(
                    labelText: 'المادة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "math", child: Text("رياضيات")),
                    DropdownMenuItem(value: "physics", child: Text("فيزياء")),
                    DropdownMenuItem(value: "chemistry", child: Text("كيمياء")),
                    DropdownMenuItem(
                      value: "natural_sciences",
                      child: Text("علوم طبيعية"),
                    ),
                    DropdownMenuItem(value: "history", child: Text("تاريخ")),
                    DropdownMenuItem(value: "geography", child: Text("جغرافيا")),
                    DropdownMenuItem(
                      value: "philosophy",
                      child: Text("فلسفة"),
                    ),
                    DropdownMenuItem(value: "arabic", child: Text("لغة عربية")),
                    DropdownMenuItem(value: "french", child: Text("فرنسية")),
                    DropdownMenuItem(value: "english", child: Text("إنجليزية")),
                  ],
                  onChanged: (v) => setState(() => _subject = v ?? _subject),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) => _description = v,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _filePath == null
                        ? 'تغيير ملف الدرس (اختياري)'
                        : 'تم اختيار: ${_filePath!.split('/').last}',
                  ),
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
                  label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


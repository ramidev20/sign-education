import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_live_quizzes.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/live_quiz_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_select_group_page.dart';

class LiveQuizCreatePage extends StatefulWidget {
  final UserModel user;

  const LiveQuizCreatePage({super.key, required this.user});

  @override
  State<LiveQuizCreatePage> createState() => _LiveQuizCreatePageState();
}

class _LiveQuizCreatePageState extends State<LiveQuizCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final _visualController = TextEditingController();
  final _timeLimitController = TextEditingController();

  ClassGroupModel? _selectedGroup;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _visualController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickGroup() async {
    final selected = await Navigator.push<ClassGroupModel>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonSelectGroupPage(
          user: widget.user,
          initiallySelectedGroupId: _selectedGroup?.classGroupId,
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selectedGroup = selected);
    }
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر مجموعة أولاً')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final timeLimit = int.tryParse(_timeLimitController.text.trim());
      final quiz = LiveQuizModel(
        teacherId: widget.user.id,
        classGroupId: _selectedGroup!.classGroupId,
        title: _titleController.text.trim(),
        promptText: _promptController.text.trim(),
        visualPromptUrl: _visualController.text.trim().isEmpty
            ? null
            : _visualController.text.trim(),
        strategyKey: 'brainstorming_visual',
        status: 'active',
        createdAt: DateTime.now(),
        startsAt: DateTime.now(),
        timeLimitMinutes: timeLimit,
      );

      await DbHelperLiveQuizzes.createQuiz(quiz);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الاختبار المباشر')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء الاختبار: $e')),
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
          title: const Text('إنشاء اختبار مباشر'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'استراتيجية العصف الذهني البصري',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اعرض سؤالاً فلسفياً أو مشكلة مفاهيمية واسمح للطلاب بتوليد أكبر عدد من الرموز والإشارات بشكل تعاوني مباشر.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الاختبار',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل عنواناً';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _promptController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'التساؤل الفلسفي / المشكلة المفاهيمية',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل نص السؤال';
                  if (v.trim().length < 10) return 'النص قصير جداً';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _visualController,
                decoration: const InputDecoration(
                  labelText: 'رابط وسيط بصري (اختياري)',
                  hintText: 'رابط صورة/فيديو إشارة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _timeLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المدة بالدقائق (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(
                    _selectedGroup == null
                        ? 'اختر المجموعة'
                        : _selectedGroup!.name,
                  ),
                  subtitle: _selectedGroup == null
                      ? const Text('لم يتم اختيار مجموعة بعد')
                      : Text(
                          '${_selectedGroup!.level} • ${_selectedGroup!.subject}',
                        ),
                  trailing: const Icon(Icons.groups_rounded),
                  onTap: _pickGroup,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _createQuiz,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline_rounded),
            label: Text(_saving ? 'جارٍ الإنشاء...' : 'بدء الاختبار المباشر'),
          ),
        ),
      ),
    );
  }
}


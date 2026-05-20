import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_select_group_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/app_theme.dart';

class LessonCreatePage extends StatefulWidget {
  final UserModel user;

  const LessonCreatePage({super.key, required this.user});

  @override
  State<LessonCreatePage> createState() => _LessonCreatePageState();
}

class _LessonCreatePageState extends State<LessonCreatePage> {
  final _formKey = GlobalKey<FormState>();

  String? title;
  String? subject;
  String? description;
  bool isUploading = false;

  String? selectedGroupId;
  ClassGroupModel? _selectedGroup;

  AppStrings get _strings =>
      AppStrings(Localizations.localeOf(context).languageCode);

  Future<void> _selectGroup() async {
    final result = await Navigator.push<ClassGroupModel>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonSelectGroupPage(
          user: widget.user,
          initiallySelectedGroupId: selectedGroupId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedGroup = result;
      selectedGroupId = result.classGroupId;
    });
  }

  Color _parseColor(String hex) {
    try {
      var clean = hex.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse('0x$clean'));
    } catch (_) {
      return AppTheme.brand;
    }
  }

  String _subjectLabel(AppStrings strings, String subjectKey) {
    switch (subjectKey) {
      case 'math':
        return strings.text('رياضيات', 'Mathematics', 'Mathematiques');
      case 'physics':
        return strings.text('فيزياء', 'Physics', 'Physique');
      case 'chemistry':
        return strings.text('كيمياء', 'Chemistry', 'Chimie');
      default:
        return subjectKey;
    }
  }

  Future<void> _saveLesson() async {
    final strings = _strings;
    if (!_formKey.currentState!.validate()) return;

    if (selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.text(
              'الرجاء اختيار المجموعة',
              'Please select a group',
              'Veuillez selectionner un groupe',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => isUploading = true);

    final lesson = LessonModel(
      subject: subject!,
      strategyType: 'Default',
      teacherId: widget.user.id,
      classGroupId: selectedGroupId!,
      title: title!,
      description: description?.trim(),
      createdAt: DateTime.now(),
    );

    await DbHelperLessons.createLesson(lesson);
    if (!mounted) return;

    setState(() => isUploading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.text(
            'تم حفظ الدرس ومشاركته بنجاح',
            'Lesson saved and shared',
            'Lecon enregistree et partagee',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.text('إضافة درس جديد', 'Add lesson', 'Ajouter une lecon')),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration:
                    _inputDecoration(strings.text('عنوان الدرس', 'Lesson title', 'Titre de la lecon'), colorScheme),
                onChanged: (v) => title = v,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? strings.text('أدخل العنوان', 'Enter a title', 'Saisissez un titre')
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration(
                  strings.text('المادة', 'Subject', 'Matiere'),
                  colorScheme,
                ),
                items: const ['math', 'physics', 'chemistry']
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(_subjectLabel(strings, key)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => subject = v,
                validator: (v) => v == null
                    ? strings.text('اختر مادة', 'Select a subject', 'Selectionnez une matiere')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration(
                  strings.text('نص الدرس', 'Lesson text', 'Texte de la lecon'),
                  colorScheme,
                ).copyWith(alignLabelWithHint: true),
                onChanged: (v) => description = v,
                maxLines: 10,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? strings.text('أدخل نص الدرس', 'Enter lesson text', 'Saisissez le texte de la lecon')
                    : null,
              ),
              const SizedBox(height: 30),
              Text(
                strings.text('اختر المجموعة:', 'Select group:', 'Selectionner le groupe :'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _selectedGroup == null
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : _parseColor(_selectedGroup!.avatarColor),
                    child: Icon(
                      Icons.group,
                      color: _selectedGroup == null ? colorScheme.primary : Colors.white,
                    ),
                  ),
                  title: Text(
                    _selectedGroup?.name ??
                        strings.text(
                          'اضغط لاختيار المجموعة',
                          'Tap to choose a group',
                          'Touchez pour choisir un groupe',
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _selectedGroup == null
                      ? Text(
                          strings.text(
                            'سيتم اختيار المجموعة في صفحة منفصلة.',
                            'The group will be selected on a separate page.',
                            'Le groupe sera selectionne sur une page separee.',
                          ),
                        )
                      : Text(
                          '${_selectedGroup!.level} • ${_selectedGroup!.subject}',
                        ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _selectGroup,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isUploading ? null : _saveLesson,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(
                  isUploading
                      ? strings.text('جارٍ الحفظ...', 'Saving...', 'Enregistrement...')
                      : strings.text(
                          'حفظ ومشاركة الدرس',
                          'Save and share lesson',
                          'Enregistrer et partager la lecon',
                        ),
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}


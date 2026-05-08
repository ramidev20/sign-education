import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_select_group_page.dart';
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
      var clean = hex.replaceAll("#", "");
      if (clean.length == 6) clean = "FF$clean";
      return Color(int.parse("0x$clean"));
    } catch (_) {
      return AppTheme.brand;
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار المجموعة")),
      );
      return;
    }

    setState(() => isUploading = true);

    final lesson = LessonModel(
      subject: subject!,
      strategyType: "Default",
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
      const SnackBar(content: Text("✅ تم حفظ الدرس ومشاركته بنجاح")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("إضافة درس جديد"),
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
                  decoration: _inputDecoration("عنوان الدرس", colorScheme),
                  onChanged: (v) => title = v,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "أدخل العنوان" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("المادة", colorScheme),
                  items: const [
                    DropdownMenuItem(value: "math", child: Text("رياضيات")),
                    DropdownMenuItem(value: "physics", child: Text("فيزياء")),
                    DropdownMenuItem(value: "chemistry", child: Text("كيمياء")),
                  ],
                  onChanged: (v) => subject = v,
                  validator: (v) => v == null ? "اختر مادة" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _inputDecoration("نص الدرس", colorScheme).copyWith(
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => description = v,
                  maxLines: 10,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "أدخل نص الدرس"
                      : null,
                ),
                const SizedBox(height: 30),
                const Text(
                  "اختر المجموعة:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _selectedGroup == null
                          ? colorScheme.primary.withOpacity(0.12)
                          : _parseColor(_selectedGroup!.avatarColor),
                      child: Icon(
                        Icons.group,
                        color: _selectedGroup == null
                            ? colorScheme.primary
                            : Colors.white,
                      ),
                    ),
                    title: Text(
                      _selectedGroup?.name ?? 'اضغط لاختيار المجموعة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: _selectedGroup == null
                        ? const Text('سيتم اختيار المجموعة في صفحة منفصلة.')
                        : Text(
                            '${_selectedGroup!.level} • ${_selectedGroup!.subject}',
                          ),
                    trailing: const Icon(Icons.chevron_left_rounded),
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
                    isUploading ? "جاري الحفظ..." : "حفظ ومشاركة الدرس",
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

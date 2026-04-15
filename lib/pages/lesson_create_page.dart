import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/data/models/lesson_model.dart';
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
  String? filePath;
  bool isUploading = false;
  String? selectedGroupId;
  List<ClassGroupModel> teacherGroups = [];
  Map<String, int> memberCounts = {};
  String? fileUrl;

  @override
  void initState() {
    super.initState();
    _fetchTeacherGroups();
  }

  // Fetch teacher groups and members
  Future<void> _fetchTeacherGroups() async {
    final groups = await DbHelperClasses.getClassesByTeacher(widget.user.id);
    final counts = <String, int>{};
    for (final g in groups) {
      final members = await DbHelperClasses.getMembers(g.classGroupId);
      counts[g.classGroupId] = members.length;
    }
    setState(() {
      teacherGroups = groups;
      memberCounts = counts;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "doc", "docx"],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        filePath = result.files.single.path!;
      });
    }
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

  Future<String?> _uploadFileFromPath() async {
    if (filePath == null || filePath!.isEmpty) return null;
    final file = File(filePath!);
    if (!await file.exists()) return null;

    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}";

    try {
      setState(() => isUploading = true);
      await Supabase.instance.client.storage
          .from('lessons')
          .upload(fileName, file);
      final publicUrl = Supabase.instance.client.storage
          .from('lessons')
          .getPublicUrl(fileName);
      setState(() {
        isUploading = false;
        fileUrl = publicUrl;
      });
      return publicUrl;
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ فشل رفع الملف: $e")));
      return null;
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;
    if (filePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("الرجاء اختيار ملف الدرس")));
      return;
    }
    if (selectedGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("الرجاء اختيار المجموعة")));
      return;
    }

    setState(() => isUploading = true);
    final uploadedUrl = await _uploadFileFromPath();
    if (uploadedUrl == null) {
      setState(() => isUploading = false);
      return;
    }

    final lesson = LessonModel(
      subject: subject!,
      strategyType: "Default",
      teacherId: widget.user.id,
      classGroupId: selectedGroupId!,
      title: title!,
      description: description,
      fileUrl: uploadedUrl,
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

    return Scaffold(
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
              // 📘 Title
              TextFormField(
                decoration: _inputDecoration("عنوان الدرس", colorScheme),
                onChanged: (v) => title = v,
                validator: (v) => v!.isEmpty ? "أدخل العنوان" : null,
              ),
              const SizedBox(height: 16),

              // 📚 Subject
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

              // 📝 Description
              TextFormField(
                decoration: _inputDecoration("الوصف (اختياري)", colorScheme),
                onChanged: (v) => description = v,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // 📂 File picker
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  filePath == null
                      ? "اختر ملف الدرس"
                      : "تم اختيار الملف: ${filePath!.split('/').last}",
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

              const SizedBox(height: 30),

              // 👥 Groups selection
              const Text(
                "اختر المجموعة:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              teacherGroups.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: teacherGroups.length,
                      itemBuilder: (context, index) {
                        final group = teacherGroups[index];
                        final isSelected =
                            group.classGroupId == selectedGroupId;
                        final color = _parseColor(group.avatarColor);
                        final memberCount =
                            memberCounts[group.classGroupId] ?? 0;

                        return GestureDetector(
                          onTap: () {
                            setState(
                              () => selectedGroupId = group.classGroupId,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.10)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor: color,
                                  radius: 30,
                                  child: const Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${group.level} • ${group.subject}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "$memberCount طالب",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 16),

              // 💾 Save button
              ElevatedButton.icon(
                onPressed: isUploading ? null : _saveLesson,
                icon: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentAddPage extends StatefulWidget {
  final UserModel user;
  const AssignmentAddPage({super.key, required this.user});

  @override
  State<AssignmentAddPage> createState() => _AssignmentAddPageState();
}

class _AssignmentAddPageState extends State<AssignmentAddPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  String title = '';
  String description = '';
  String? subject;
  DateTime? endTime;
  PlatformFile? pickedFile;

  List<Map<String, dynamic>> groups = [];
  Map<String, List<Map<String, dynamic>>> groupStudents = {};
  Map<String, Set<String>> selectedStudents = {};

  final List<Map<String, dynamic>> subjectsList = [
    {'name': "math", 'label': 'رياضيات'},
    {'name': "physics", 'label': 'فيزياء'},
    {'name': "chemistry", 'label': 'كيمياء'},
    {'name': "natural_sciences", 'label': 'علوم طبيعية'},
    {'name': "history_geography", 'label': 'تاريخ وجغرافيا'},
    {'name': "philosophy", 'label': 'فلسفة'},
    {'name': "languages", 'label': 'لغات'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final result = await supabase
        .from('class_groups')
        .select('class_group_id, name')
        .eq('teacher_id', widget.user.id);

    final fetchedGroups = List<Map<String, dynamic>>.from(result);

    for (var g in fetchedGroups) {
      final members = await supabase
          .from('class_group_members')
          .select('user_id, users(name)')
          .eq('class_group_id', g['class_group_id'])
          .eq('role', 'student');

      groupStudents[g['class_group_id']] = List<Map<String, dynamic>>.from(
        members.map((m) => {'id': m['user_id'], 'name': m['users']['name']}),
      );
      selectedStudents[g['class_group_id']] = {};
    }

    setState(() => groups = fetchedGroups);
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (endTime == null || pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تحديد الملف وموعد التسليم")),
      );
      return;
    }

    try {
      // ✅ 1. Upload the assignment file to Supabase Storage
      final filePath = pickedFile!.path!;
      final fileName =
          "assignments/${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}";

      await supabase.storage
          .from('assignments')
          .upload(
            fileName,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      final fileUrl = supabase.storage
          .from('assignments')
          .getPublicUrl(fileName);

      // ✅ 2. Create the assignment in the database
      final assignment = AssignmentModel(
        subject: subject!,
        teacherId: widget.user.id,
        classGroupId: "multi",
        title: title,
        description: description,
        status: "pending",
        createdAt: DateTime.now(),
        completeAt: endTime!,
        fileUrl: fileUrl, // ✅ real online link now!
      );

      final assignmentId = await DbHelperAssignments.createAssignment(
        assignment,
      );

      // ✅ 3. Share assignment with selected students
      final selectedStudentIds = selectedStudents.values
          .expand((set) => set)
          .toSet()
          .toList();

      for (final studentId in selectedStudentIds) {
        await DbHelperAssignments.shareAssignment(assignmentId, studentId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إنشاء الواجب ومشاركته بنجاح")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("❌ فشل في رفع أو إنشاء الواجب: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء إنشاء الواجب: $e")),
      );
    }
  }

  void _toggleSelectAll(String groupId, bool selectAll) {
    setState(() {
      if (selectAll) {
        selectedStudents[groupId] = groupStudents[groupId]!
            .map((s) => s['id'] as String)
            .toSet();
      } else {
        selectedStudents[groupId]!.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة واجب")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.globalRadius,
                  ),
                ),
                onSaved: (v) => title = v ?? '',
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "المادة",
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.globalRadius,
                  ),
                ),
                items: subjectsList
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s['name'] as String,
                        child: Text(s['label'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => subject = v,
                validator: (v) => v == null ? "اختر مادة" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'التعليمات',
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.globalRadius,
                  ),
                ),
                maxLines: 3,
                onSaved: (v) => description = v ?? '',
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // 🔽 Group and student selection section
              const Text(
                "اختر المجموعات والطلاب:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (groups.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ...groups.map((group) {
                  final groupId = group['class_group_id'];
                  final students = groupStudents[groupId] ?? [];
                  final selected = selectedStudents[groupId]!;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.globalRadius,
                    ),
                    elevation: 2,
                    child: ExpansionTile(
                      title: Text(group['name'] ?? 'مجموعة'),
                      children: [
                        ListTile(
                          title: const Text('تحديد الكل'),
                          trailing: Checkbox(
                            value:
                                selected.length == students.length &&
                                students.isNotEmpty,
                            onChanged: (v) =>
                                _toggleSelectAll(groupId, v ?? false),
                          ),
                        ),
                        ...students.map((student) {
                          final isChecked = selected.contains(student['id']);
                          return CheckboxListTile(
                            title: Text(student['name']),
                            value: isChecked,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selected.add(student['id']);
                                } else {
                                  selected.remove(student['id']);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.globalRadius,
                ),
                tileColor: Theme.of(context).cardColor,
                title: Text(
                  endTime == null
                      ? 'اختر موعد التسليم'
                      : '${endTime!.day}/${endTime!.month}/${endTime!.year} - '
                            '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Icon(Icons.calendar_today, color: AppTheme.brand),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        endTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text("اختر ملف"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.globalRadius,
                  ),
                ),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ["pdf", "doc", "docx"],
                  );
                  if (result != null) {
                    setState(() => pickedFile = result.files.first);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("تم اختيار الملف: ${pickedFile!.name}"),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ الواجب'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.globalRadius,
                  ),
                ),
                onPressed: _saveAssignment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

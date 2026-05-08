import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/teacher_pages/assignment_questions_editor_page.dart';
import 'package:sign_education/pages/lesson_select_group_page.dart';


class AssignmentAddPage extends StatefulWidget {
  final UserModel user;
  const AssignmentAddPage({super.key, required this.user});

  @override
  State<AssignmentAddPage> createState() => _AssignmentAddPageState();
}

class _AssignmentAddPageState extends State<AssignmentAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();

  String? subject;
  DateTime? endTime;
  String? selectedGroupId;
  ClassGroupModel? _selectedGroup;

  List<Map<String, dynamic>> _questionsPayload = const [];

  final List<Map<String, dynamic>> subjectsList = const [
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
    _questionsPayload = const [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

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

  Future<void> _editQuestions() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentQuestionsEditorPage(
          initialQuestions: _questionsPayload,
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() => _questionsPayload = result);
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
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

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تحديد موعد التسليم")),
      );
      return;
    }

    if (selectedGroupId == null || selectedGroupId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("اختر مجموعة واحدة على الأقل")),
      );
      return;
    }

    if (_questionsPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("أضف سؤالاً واحداً على الأقل")),
      );
      return;
    }

    try {
      final groupStudents = await DbHelperClasses.getStudentsByGroup(
        selectedGroupId!,
      );
      final selectedStudentIds = groupStudents.map((s) => s.id).toSet().toList();
      if (selectedStudentIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا يوجد طلاب داخل هذه المجموعة")),
        );
        return;
      }

      final assignment = AssignmentModel(
        subject: subject!,
        teacherId: widget.user.id,
        classGroupId: selectedGroupId!,
        title: _titleController.text.trim(),
        description: _instructionsController.text.trim(),
        status: "pending",
        createdAt: DateTime.now(),
        completeAt: endTime!,
        fileUrl: null,
        assignmentContentJson: {
          'version': 1,
          'questions': _questionsPayload,
        },
      );

      final assignmentId = await DbHelperAssignments.createAssignment(assignment);
      for (final studentId in selectedStudentIds) {
        await DbHelperAssignments.shareAssignment(assignmentId, studentId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إنشاء الواجب الديناميكي ومشاركته")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء إنشاء الواجب: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة واجب ديناميكي")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'العنوان'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'العنوان مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "المادة"),
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
                      controller: _instructionsController,
                      decoration: const InputDecoration(labelText: 'تعليمات الواجب'),
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'أدخل تعليمات الواجب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: cs.surfaceContainerHighest.withOpacity(0.5),
                      title: Text(
                        endTime == null
                            ? 'اختر موعد التسليم'
                            : '${endTime!.day}/${endTime!.month}/${endTime!.year} - '
                                '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: _pickDeadline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "أسئلة الواجب",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.quiz_outlined),
                        ),
                        title: const Text('إدارة الأسئلة'),
                        subtitle: Text(
                          _questionsPayload.isEmpty
                              ? 'لم تتم إضافة أسئلة بعد'
                              : 'عدد الأسئلة: ${_questionsPayload.length}',
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: _editQuestions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("اختر المجموعة", style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.group),
                        ),
                        title: Text(_selectedGroup?.name ?? 'اضغط لاختيار المجموعة'),
                        subtitle: _selectedGroup == null
                            ? const Text('سيتم اختيار المجموعة في صفحة منفصلة.')
                            : Text(
                                '${_selectedGroup!.level} • ${_selectedGroup!.subject}',
                              ),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: _selectGroup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saveAssignment,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ ومشاركة الواجب'),
            ),
          ],
        ),
      ),
    );
  }
}

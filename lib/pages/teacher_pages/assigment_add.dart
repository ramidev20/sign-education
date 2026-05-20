import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_select_group_page.dart';
import 'package:sign_education/pages/teacher_pages/assignment_questions_editor_page.dart';
import 'package:sign_education/utils/app_strings.dart';

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

  AppStrings get _strings =>
      AppStrings(Localizations.localeOf(context).languageCode);

  static const List<String> _subjectKeys = [
    'math',
    'physics',
    'chemistry',
    'natural_sciences',
    'history_geography',
    'philosophy',
    'languages',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String _subjectLabel(AppStrings strings, String subjectKey) {
    switch (subjectKey) {
      case 'math':
        return strings.text('رياضيات', 'Mathematics', 'Mathematiques');
      case 'physics':
        return strings.text('فيزياء', 'Physics', 'Physique');
      case 'chemistry':
        return strings.text('كيمياء', 'Chemistry', 'Chimie');
      case 'natural_sciences':
        return strings.text('علوم طبيعية', 'Natural sciences', 'Sciences naturelles');
      case 'history_geography':
        return strings.text('تاريخ وجغرافيا', 'History and geography', 'Histoire et geographie');
      case 'philosophy':
        return strings.text('فلسفة', 'Philosophy', 'Philosophie');
      case 'languages':
        return strings.text('لغات', 'Languages', 'Langues');
      default:
        return subjectKey;
    }
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
    final strings = _strings;
    if (!_formKey.currentState!.validate()) return;

    if (endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.text(
              'يرجى تحديد موعد التسليم',
              'Please choose a due date',
              'Veuillez choisir une date limite',
            ),
          ),
        ),
      );
      return;
    }

    if (selectedGroupId == null || selectedGroupId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.text(
              'اختر مجموعة واحدة على الأقل',
              'Please select a group',
              'Veuillez selectionner un groupe',
            ),
          ),
        ),
      );
      return;
    }

    if (_questionsPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.text(
              'أضف سؤالا واحدا على الأقل',
              'Add at least one question',
              'Ajoutez au moins une question',
            ),
          ),
        ),
      );
      return;
    }

    try {
      final groupStudents = await DbHelperClasses.getStudentsByGroup(
        selectedGroupId!,
      );
      final selectedStudentIds = groupStudents.map((student) => student.id).toSet().toList();
      if (selectedStudentIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.text(
                'لا يوجد طلاب داخل هذه المجموعة',
                'This group has no students',
                'Ce groupe ne contient aucun eleve',
              ),
            ),
          ),
        );
        return;
      }

      final assignment = AssignmentModel(
        subject: subject!,
        teacherId: widget.user.id,
        classGroupId: selectedGroupId!,
        title: _titleController.text.trim(),
        description: _instructionsController.text.trim(),
        status: 'pending',
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
        SnackBar(
          content: Text(
            strings.text(
              'تم إنشاء الواجب ومشاركته',
              'Assignment created and shared',
              'Devoir cree et partage',
            ),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.text(
              'حدث خطأ أثناء إنشاء الواجب',
              'An error occurred while creating the assignment',
              'Une erreur est survenue lors de la creation du devoir',
            ) +
                ': $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.text(
            'إضافة واجب',
            'Add assignment',
            'Ajouter un devoir',
          ),
        ),
      ),
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
                      decoration: InputDecoration(
                        labelText: strings.text('العنوان', 'Title', 'Titre'),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return strings.text(
                            'العنوان مطلوب',
                            'Title is required',
                            'Le titre est requis',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: strings.text('المادة', 'Subject', 'Matiere'),
                      ),
                      items: _subjectKeys
                          .map(
                            (subjectKey) => DropdownMenuItem<String>(
                              value: subjectKey,
                              child: Text(_subjectLabel(strings, subjectKey)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => subject = value,
                      validator: (value) => value == null
                          ? strings.text(
                              'اختر مادة',
                              'Select a subject',
                              'Selectionnez une matiere',
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        labelText: strings.text(
                          'تعليمات الواجب',
                          'Assignment instructions',
                          'Consignes du devoir',
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return strings.text(
                            'أدخل تعليمات الواجب',
                            'Enter assignment instructions',
                            'Saisissez les consignes du devoir',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      title: Text(
                        endTime == null
                            ? strings.text(
                                'اختر موعد التسليم',
                                'Choose due date',
                                'Choisir la date limite',
                              )
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
                    Text(
                      strings.text('أسئلة الواجب', 'Assignment questions', 'Questions du devoir'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.quiz_outlined),
                        ),
                        title: Text(
                          strings.text(
                            'إدارة الأسئلة',
                            'Manage questions',
                            'Gerer les questions',
                          ),
                        ),
                        subtitle: Text(
                          _questionsPayload.isEmpty
                              ? strings.text(
                                  'لم تتم إضافة أسئلة بعد',
                                  'No questions added yet',
                                  'Aucune question ajoutee pour le moment',
                                )
                              : '${strings.text('عدد الأسئلة', 'Questions', 'Questions')}: ${_questionsPayload.length}',
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
                    Text(
                      strings.text('اختر المجموعة', 'Select group', 'Selectionner le groupe'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.group),
                        ),
                        title: Text(
                          _selectedGroup?.name ??
                              strings.text(
                                'اضغط لاختيار المجموعة',
                                'Tap to choose a group',
                                'Touchez pour choisir un groupe',
                              ),
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
              label: Text(
                strings.text(
                  'حفظ ومشاركة الواجب',
                  'Save and share assignment',
                  'Enregistrer et partager le devoir',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

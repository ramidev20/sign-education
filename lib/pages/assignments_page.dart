import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/student_pages/student_assignments_page.dart';
import 'package:sign_education/pages/teacher_pages/teacher_assignments_page.dart';

enum UserType { student, teacher }

class AssignmentsPage extends StatelessWidget {
  final UserModel user;
  final int initialTabIndex;

  const AssignmentsPage({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStudent =
        user.role == "student" || user.role == UserType.student.name;
    final bool isTeacher =
        user.role == "teacher" || user.role == UserType.teacher.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الواجبات'),
        centerTitle: true,
      ),
      body: isStudent
          ? StudentAssignmentsPage(user: user, initialTabIndex: initialTabIndex)
          : isTeacher
          ? TeacherAssignmentsPage(user: user, initialTabIndex: initialTabIndex)
          : null,
    );
  }
}

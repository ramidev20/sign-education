import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/student_pages/student_live_quizzes_page.dart';
import 'package:sign_education/pages/teacher_pages/teacher_live_quizzes_page.dart';
import 'package:sign_education/utils/app_strings.dart';

enum QuizUserType { student, teacher }

class QuizzesPage extends StatelessWidget {
  final UserModel user;
  final int initialTabIndex;

  const QuizzesPage({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isStudent =
        user.role == 'student' || user.role == QuizUserType.student.name;
    final isTeacher =
        user.role == 'teacher' || user.role == QuizUserType.teacher.name;

    return Scaffold(
      appBar: AppBar(title: Text(strings.liveQuiz), centerTitle: true),
      body: isStudent
          ? StudentLiveQuizzesPage(user: user, initialTabIndex: initialTabIndex)
          : isTeacher
              ? TeacherLiveQuizzesPage(
                  user: user,
                  initialTabIndex: initialTabIndex,
                )
              : const SizedBox.shrink(),
    );
  }
}


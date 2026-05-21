import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_view_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/subject_localization.dart';
import 'package:sign_education/widgets/app_state.dart';

class TeacherLessonStrategiesPage extends StatelessWidget {
  final UserModel user;
  const TeacherLessonStrategiesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('teacher_lesson_strategies.title')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<LessonModel>>(
        future: DbHelperLessons.getLessonsByTeacher(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: strings.tr('teacher_lesson_strategies.load_failed'),
              message: snapshot.error?.toString(),
              actionLabel: strings.tr('app.refresh'),
              onAction: () => (context as Element).markNeedsBuild(),
            );
          }

          final lessons = snapshot.data ?? [];
          if (lessons.isEmpty) {
            return AppEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: strings.tr('teacher_lesson_strategies.empty.title'),
              message: strings.tr('teacher_lesson_strategies.empty.message'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final subjectText = localizedSubject(strings, lesson.subject);

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(
                    lesson.title?.trim().isNotEmpty == true
                        ? lesson.title!.trim()
                        : strings.tr('lessons.lesson_fallback_title'),
                  ),
                  subtitle: Text(
                    '${strings.tr('lessons.subject_label')}: $subjectText',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonViewPage(lesson: lesson, user: user),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


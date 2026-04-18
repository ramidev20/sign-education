import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_view_page.dart';
import 'package:sign_education/widgets/app_state.dart';

class TeacherLessonStrategiesPage extends StatelessWidget {
  final UserModel user;
  const TeacherLessonStrategiesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('استراتيجيات الدروس'),
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
                title: 'تعذر تحميل الدروس',
                message: snapshot.error?.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => (context as Element).markNeedsBuild(),
              );
            }

            final lessons = snapshot.data ?? [];
            if (lessons.isEmpty) {
              return const AppEmptyState(
                icon: Icons.auto_awesome_outlined,
                title: 'لا توجد دروس بعد',
                message: 'أضف درساً ثم أنشئ له استراتيجيات.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(lesson.title ?? 'درس'),
                    subtitle: Text('المادة: ${subjectLabels[lesson.subject]}'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonViewPage(
                            lesson: lesson,
                            user: user,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


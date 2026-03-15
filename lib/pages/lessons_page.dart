import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/pages/assignments_page.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:sign_education/pages/lesson_create_page.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/pages/strategies_page.dart'; // ✅ Make sure this import exists

class LessonsPage extends StatefulWidget {
  final UserModel user;
  const LessonsPage({super.key, required this.user});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  Future<List<LessonModel>> _fetchTeacherLessons() async {
    return await DbHelperLessons.getLessonsByTeacher(widget.user.id);
  }

  void _viewLessonPdf(LessonModel lesson) {
    if (lesson.fileUrl != null && lesson.fileUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonPdfPage(lesson: lesson)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("لا يوجد PDF لهذا الدرس")));
    }
  }

  void _openStrategiesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StrategiesPage(
          user: widget.user,
          title: "درس جديد",
          subject: "غير محدد",
        ),
      ),
    );
  }

  void _openLessonArchive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("أرشيف الدروس")),
          body: _lessonsArchive(),
        ),
      ),
    );
  }

  Widget _buildStudentView() {
    return FutureBuilder<List<ClassGroupModel>>(
      future: DbHelperClasses.getClassesByStudent(widget.user.id),
      builder: (context, classSnapshot) {
        if (classSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (classSnapshot.hasError) {
          return Center(child: Text("حدث خطأ أثناء تحميل الأقسام"));
        }

        final classGroups = classSnapshot.data ?? [];
        if (classGroups.isEmpty) {
          return const Center(child: Text("أنت لست مسجلاً في أي قسم بعد"));
        }

        return FutureBuilder<List<LessonModel>>(
          future: _fetchLessonsForStudent(classGroups),
          builder: (context, lessonSnapshot) {
            if (lessonSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (lessonSnapshot.hasError) {
              return Center(child: Text("حدث خطأ أثناء تحميل الدروس"));
            }

            final lessons = lessonSnapshot.data ?? [];
            if (lessons.isEmpty) {
              return const Center(child: Text("لا توجد دروس متاحة لك حاليًا"));
            }

            return ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.globalRadius,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: Text(
                      lesson.title!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("المادة: ${subjectLabels[lesson.subject]}"),
                      ],
                    ),
                    onTap: () => _viewLessonPdf(lesson),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔹 Helper function: Fetch all lessons for the student’s class groups
  Future<List<LessonModel>> _fetchLessonsForStudent(
    List<ClassGroupModel> classGroups,
  ) async {
    List<LessonModel> allLessons = [];

    for (final group in classGroups) {
      final groupId = group.classGroupId;
      if (groupId.isNotEmpty) {
        final lessons = await DbHelperLessons.getLessonsByClassGroup(groupId);
        allLessons.addAll(lessons);
      }
    }

    return allLessons;
  }

  Widget _buildTeacherView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // أرشيف الدروس
          GestureDetector(
            onTap: _openLessonArchive,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppTheme.globalRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade200
                          : Colors.grey.shade700,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text("أرشيف الدروس"),
                  ],
                ),
              ),
            ),
          ),

          // إضافة درس
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonCreatePage(user: widget.user),
                ),
              );
              setState(() {}); // refresh after returning
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: AppTheme.globalRadius,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "إضافة درس",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // إستراتيجيات التعلم
          GestureDetector(
            onTap: _openStrategiesPage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: AppTheme.globalRadius,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      "إستراتيجيات التعلم",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonsArchive() {
    return FutureBuilder<List<LessonModel>>(
      future: _fetchTeacherLessons(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lessons = snapshot.data!;
        if (lessons.isEmpty) {
          return const Center(child: Text("لا توجد دروس بعد"));
        }

        return ListView.builder(
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.globalRadius,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                title: Text(
                  lesson.title ?? "بدون عنوان",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("المادة: ${subjectLabels[lesson.subject]}"),
                    Text(
                      "نوع الاستراتيجية: ${strategyTypeLabels[lesson.strategyType]}",
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تأكيد الحذف'),
                          content: const Text('هل أنت متأكد من حذف هذا الدرس؟'),
                          actions: [
                            TextButton(
                              child: const Text('إلغاء'),
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                              ),
                              child: const Text('حذف'),
                              onPressed: () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await DbHelperLessons.deleteLesson(lesson.lessonId!);
                        setState(() {});
                      }
                    } else if (value == 'view') {
                      _viewLessonPdf(lesson);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'view',
                          child: Text('عرض'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.user.role);
    return Scaffold(
      appBar: AppBar(title: const Text("الدروس")),
      body: widget.user.role == 'teacher'
          ? _buildTeacherView(context)
          : _buildStudentView(),
    );
  }
}

class LessonPdfPage extends StatelessWidget {
  final LessonModel lesson;
  const LessonPdfPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title ?? 'عرض الدرس')),
      body: lesson.fileUrl != null && lesson.fileUrl!.isNotEmpty
          ? SfPdfViewer.network(lesson.fileUrl!)
          : Center(
              child: Text(
                'لا يوجد ملف PDF لهذا الدرس',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
    );
  }
}

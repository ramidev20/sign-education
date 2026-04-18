import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/dictionary_subjects.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_create_page.dart';
import 'package:sign_education/pages/lesson_strategies_info_page.dart';
import 'package:sign_education/pages/lesson_view_page.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/widgets/app_state.dart';

class LessonsPage extends StatefulWidget {
  final UserModel user;
  const LessonsPage({super.key, required this.user});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final List<LessonModel> _lessons = [];
  bool _loading = true;
  List<String> _groupIds = [];
  String? _selectedStudentSubject;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    if (widget.user.role == 'student') {
      _initStudent();
    }
  }

  Future<void> _initStudent() async {
    try {
      final groups = await DbHelperClasses.getClassesByStudent(widget.user.id);
      _groupIds = groups.map((g) => g.classGroupId).where((id) => id.isNotEmpty).toList();
      await _refreshStudent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل المجموعات: $e')),
      );
    }
  }

  Future<void> _refreshStudent() async {
    setState(() => _loading = true);
    _lessons.clear();
    if (_groupIds.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      var offset = 0;
      while (true) {
        final page = await DbHelperLessons.getLessonsByClassGroupsPaged(
          classGroupIds: _groupIds,
          offset: offset,
          limit: _pageSize,
        );
        _lessons.addAll(page);
        if (page.length < _pageSize) break;
        offset += page.length;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الدروس: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewLessonPdf(LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonViewPage(lesson: lesson, user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.user.role == 'teacher';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدروس'),
          centerTitle: true,
        ),
        body: isTeacher ? _buildTeacherView(context) : _buildStudentView(),
      ),
    );
  }

  Widget _buildStudentView() {
    if (_loading) return const AppLoading();

    if (_groupIds.isEmpty) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'أنت لست مسجلاً في أي قسم بعد',
        message: 'اطلب من المعلم إضافتك إلى مجموعة.',
      );
    }

    if (_lessons.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'لا توجد دروس متاحة لك حالياً',
        actionLabel: 'تحديث',
        onAction: _refreshStudent,
      );
    }

    if (_selectedStudentSubject == null) {
      final subjects = _allStudentSubjects(_lessons);
      return _LessonsSubjectsGrid(
        title: 'اختر المادة',
        subjects: subjects,
        onTap: (subjectId) {
          setState(() => _selectedStudentSubject = subjectId);
        },
      );
    }

    final selected = _selectedStudentSubject!;
    final filtered = _lessons.where((l) => l.subject == selected).toList();
    return _LessonsBySubjectList(
      subjectId: selected,
      lessons: filtered,
      onBackToSubjects: () => setState(() => _selectedStudentSubject = null),
      onOpenLesson: _viewLessonPdf,
    );
  }

  Widget _buildTeacherView(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = <_TeacherTile>[
      _TeacherTile(
        title: 'إضافة درس',
        icon: Icons.add_circle_outline,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonCreatePage(user: widget.user)),
          );
          if (!mounted) return;
          setState(() {});
        },
      ),
      _TeacherTile(
        title: 'أرشيف الدروس',
        icon: Icons.archive_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _TeacherLessonsArchive(user: widget.user)),
          );
        },
      ),
      _TeacherTile(
        title: 'استراتيجيات التعلم',
        icon: Icons.auto_awesome_outlined,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonStrategiesInfoPage(user: widget.user),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: tiles
            .map(
              (t) => InkWell(
                borderRadius: AppTheme.globalRadius,
                onTap: t.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.gradient == null ? theme.colorScheme.surface : null,
                    gradient: t.gradient,
                    borderRadius: AppTheme.globalRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          t.icon,
                          size: 48,
                          color: t.gradient != null
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.gradient != null
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TeacherTile {
  final String title;
  final IconData icon;
  final LinearGradient? gradient;
  final VoidCallback onTap;

  _TeacherTile({
    required this.title,
    required this.icon,
    this.gradient,
    required this.onTap,
  });
}

class _TeacherLessonsArchive extends StatefulWidget {
  final UserModel user;
  const _TeacherLessonsArchive({required this.user});

  @override
  State<_TeacherLessonsArchive> createState() => _TeacherLessonsArchiveState();
}

class _TeacherLessonsArchiveState extends State<_TeacherLessonsArchive> {
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('أرشيف الدروس')),
        body: FutureBuilder<List<LessonModel>>(
          future: DbHelperLessons.getLessonsByTeacher(widget.user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoading();
            }
            if (snapshot.hasError) {
              return AppErrorState(
                title: 'تعذر تحميل الأرشيف',
                message: snapshot.error?.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => (context as Element).markNeedsBuild(),
              );
            }

            final lessons = snapshot.data ?? [];
            if (lessons.isEmpty) {
              return const AppEmptyState(
                icon: Icons.archive_outlined,
                title: 'لا توجد دروس بعد',
              );
            }

            if (_selectedSubject == null) {
              final subjects = _buildSubjectsFromLessons(lessons);
              return _LessonsSubjectsGrid(
                title: 'اختر المادة',
                subjects: subjects,
                onTap: (subjectId) => setState(() => _selectedSubject = subjectId),
              );
            }

            final selected = _selectedSubject!;
            final filtered = lessons.where((l) => l.subject == selected).toList();
            return _LessonsBySubjectList(
              subjectId: selected,
              lessons: filtered,
              onBackToSubjects: () => setState(() => _selectedSubject = null),
              onOpenLesson: (lesson) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonViewPage(
                      lesson: lesson,
                      user: widget.user,
                    ),
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

class _LessonsBySubjectList extends StatelessWidget {
  final String subjectId;
  final List<LessonModel> lessons;
  final VoidCallback onBackToSubjects;
  final void Function(LessonModel lesson) onOpenLesson;

  const _LessonsBySubjectList({
    required this.subjectId,
    required this.lessons,
    required this.onBackToSubjects,
    required this.onOpenLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBackToSubjects,
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('كل المواد'),
              ),
              const Spacer(),
              Text(
                _subjectLabel(subjectId),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: lessons.isEmpty
              ? const AppEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'لا توجد دروس لهذه المادة',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(lesson.title ?? 'درس'),
                        subtitle: Text('المادة: ${_subjectLabel(lesson.subject)}'),
                        trailing: const Icon(Icons.picture_as_pdf_outlined),
                        onTap: () => onOpenLesson(lesson),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LessonsSubjectsGrid extends StatelessWidget {
  final String title;
  final List<_SubjectUiItem> subjects;
  final void Function(String subjectId) onTap;

  const _LessonsSubjectsGrid({
    required this.title,
    required this.subjects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'لا توجد مواد متاحة',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: subjects.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final item = subjects[index];
                return _SubjectTile(
                  title: item.title,
                  icon: item.icon,
                  color: item.color,
                  onTap: () => onTap(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: onColor, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectUiItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const _SubjectUiItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

List<_SubjectUiItem> _buildSubjectsFromLessons(List<LessonModel> lessons) {
  final ids = <String>{};
  for (final lesson in lessons) {
    if (lesson.subject.trim().isNotEmpty) {
      ids.add(lesson.subject.trim());
    }
  }

  final subjects = ids.map((id) => _subjectUi(id)).toList();
  subjects.sort((a, b) => a.title.compareTo(b.title));
  return subjects;
}

List<_SubjectUiItem> _allStudentSubjects(List<LessonModel> lessons) {
  final all = <_SubjectUiItem>[
    for (final s in dictionarySubjects)
      _SubjectUiItem(
        id: s.id,
        title: s.titleAr,
        icon: s.icon,
        color: s.color,
      ),
  ];

  final existingIds = all.map((s) => s.id).toSet();
  for (final lesson in lessons) {
    final id = lesson.subject.trim();
    if (id.isEmpty || existingIds.contains(id)) continue;
    all.add(_subjectUi(id));
    existingIds.add(id);
  }
  return all;
}

_SubjectUiItem _subjectUi(String id) {
  for (final ds in dictionarySubjects) {
    if (ds.id != id) continue;
    return _SubjectUiItem(
      id: id,
      title: ds.titleAr,
      icon: ds.icon,
      color: ds.color,
    );
  }

  final colors = <Color>[
    const Color(0xFF5B8DEF),
    const Color(0xFF22C55E),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF0EA5E9),
    const Color(0xFF8B5CF6),
  ];
  final index = id.codeUnits.fold<int>(0, (p, n) => p + n) % colors.length;
  return _SubjectUiItem(
    id: id,
    title: _subjectLabel(id),
    icon: Icons.menu_book_rounded,
    color: colors[index],
  );
}

String _subjectLabel(String subjectId) {
  return subjectLabels[subjectId] ?? subjectId;
}

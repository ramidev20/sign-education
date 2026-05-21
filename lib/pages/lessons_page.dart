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
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/subject_localization.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/utils/offline_lesson_cache.dart';
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
  bool _studentOffline = false;
  String? _studentOnlineError;
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
      _studentOffline = false;
      _studentOnlineError = null;
      await _refreshStudent();
    } catch (e) {
      final cached = await OfflineLessonCache.getSavedLessons();
      if (!mounted) return;

      if (cached.isNotEmpty) {
        setState(() {
          _lessons
            ..clear()
            ..addAll(cached);
          _studentOffline = true;
          _studentOnlineError = '$e';
          _loading = false;
          _selectedStudentSubject = null;
        });
        return;
      }

      setState(() {
        _studentOffline = true;
        _studentOnlineError = '$e';
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context).tr('lessons.load_failed_internet')}: $e')),
      );
    }
  }

  Future<void> _refreshStudent() async {
    setState(() => _loading = true);
    _lessons.clear();
    if (_groupIds.isEmpty) {
      final cached = await OfflineLessonCache.getSavedLessons();
      if (!mounted) return;
      setState(() {
        _lessons.addAll(cached);
        _studentOffline = true;
        _loading = false;
      });
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
      _studentOffline = false;
      _studentOnlineError = null;
    } catch (e) {
      final cached = await OfflineLessonCache.getSavedLessons();
      if (!mounted) return;
      if (cached.isNotEmpty) {
        setState(() {
          _lessons
            ..clear()
            ..addAll(cached);
          _studentOffline = true;
          _studentOnlineError = '$e';
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context).tr('lessons.load_failed')}: $e')),
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
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('lessons.title')),
        centerTitle: true,
      ),
      body: isTeacher ? _buildTeacherView(context) : _buildStudentView(),
    );
  }

  Widget _buildStudentView() {
    if (_loading) return const AppLoading();

    if (!_studentOffline && _groupIds.isEmpty) {
      final strings = AppStrings.of(context);
      return AppEmptyState(
        icon: Icons.school_outlined,
        title: strings.tr('lessons.student.no_group.title'),
        message: strings.tr('lessons.student.no_group.message'),
      );
    }

    if (_lessons.isEmpty) {
      final strings = AppStrings.of(context);
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: _studentOffline
            ? strings.tr('lessons.student.empty_offline')
            : strings.tr('lessons.student.empty_online'),
        actionLabel: strings.tr('app.refresh'),
        onAction: _refreshStudent,
      );
    }

    if (_selectedStudentSubject == null) {
      final strings = AppStrings.of(context);
      final subjects = _allStudentSubjects(strings, _lessons);
      final grid = _LessonsSubjectsGrid(
        title: strings.tr('lessons.choose_subject'),
        subjects: subjects,
        onTap: (subjectId) {
          setState(() => _selectedStudentSubject = subjectId);
        },
      );
      if (!_studentOffline) return grid;
      return Column(
        children: [
          _OfflineArchiveBanner(
            onRefreshOnline: _refreshStudent,
            errorText: _studentOnlineError,
          ),
          Expanded(child: grid),
        ],
      );
    }

    final selected = _selectedStudentSubject!;
    final filtered = _lessons.where((l) => l.subject == selected).toList();
    final list = _LessonsBySubjectList(
      subjectId: selected,
      lessons: filtered,
      onBackToSubjects: () => setState(() => _selectedStudentSubject = null),
      onOpenLesson: _viewLessonPdf,
    );
    if (!_studentOffline) return list;
    return Column(
      children: [
        _OfflineArchiveBanner(
          onRefreshOnline: _refreshStudent,
          errorText: _studentOnlineError,
        ),
        Expanded(child: list),
      ],
    );
  }

  Widget _buildTeacherView(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final tiles = <_TeacherTile>[
      _TeacherTile(
        title: strings.tr('lessons.teacher.add_lesson'),
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
        title: strings.tr('lessons.teacher.archive'),
        icon: Icons.archive_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _TeacherLessonsArchive(user: widget.user)),
          );
        },
      ),
      _TeacherTile(
        title: strings.tr('lessons.teacher.strategy_guide'),
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
  late Future<_ArchiveLessonsResult> _archiveFuture;

  @override
  void initState() {
    super.initState();
    _archiveFuture = _loadArchiveLessons();
  }

  Future<_ArchiveLessonsResult> _loadArchiveLessons() async {
    try {
      final lessons = await DbHelperLessons.getLessonsByTeacher(widget.user.id);
      return _ArchiveLessonsResult(lessons: lessons, isOffline: false);
    } catch (e) {
      final cached = await OfflineLessonCache.getSavedLessonsByTeacher(
        widget.user.id,
      );
      if (cached.isNotEmpty) {
        return _ArchiveLessonsResult(
          lessons: cached,
          isOffline: true,
          onlineError: '$e',
        );
      }
      rethrow;
    }
  }

  void _retryLoad() {
    setState(() {
      _archiveFuture = _loadArchiveLessons();
    });
  }

  Future<void> _confirmDeleteLesson(LessonModel lesson) async {
    final strings = AppStrings.of(context);
    final lessonId = lesson.lessonId;
    if (lessonId == null || lessonId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tr('lessons.delete.id_missing'))),
      );
      return;
    }

    final title = (lesson.title?.trim().isNotEmpty ?? false)
        ? lesson.title!.trim()
        : strings.tr('lessons.delete.fallback_title');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.tr('lessons.delete.title')),
        content: Text('${strings.tr('lessons.delete.confirm')} "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.tr('app.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(strings.tr('lessons.delete.action')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await DbHelperLessons.deleteLesson(lessonId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.tr('lessons.delete.success'))));
      _retryLoad();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('lessons.delete.failed')}: $e')),
      );
    }
  }

  Widget _withOfflineBanner(_ArchiveLessonsResult result, Widget child) {
    if (!result.isOffline) return child;
    return Column(
      children: [
        _OfflineArchiveBanner(
          onRefreshOnline: _retryLoad,
          errorText: result.onlineError,
        ),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('lessons.teacher.archive'))),
      body: FutureBuilder<_ArchiveLessonsResult>(
        future: _archiveFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: strings.tr('lessons.archive.load_failed'),
              message: snapshot.error?.toString(),
              actionLabel: strings.tr('lessons.archive.retry'),
              onAction: _retryLoad,
            );
          }

          final result = snapshot.data!;
          final lessons = result.lessons;
          if (lessons.isEmpty) {
            return AppEmptyState(
              icon: Icons.archive_outlined,
              title: strings.tr('lessons.archive.empty'),
            );
          }

          if (_selectedSubject == null) {
            final subjects = _buildSubjectsFromLessons(strings, lessons);
            return _withOfflineBanner(
              result,
              _LessonsSubjectsGrid(
                title: strings.tr('lessons.choose_subject'),
                subjects: subjects,
                onTap: (subjectId) =>
                    setState(() => _selectedSubject = subjectId),
              ),
            );
          }

          final selected = _selectedSubject!;
          final filtered = lessons.where((l) => l.subject == selected).toList();
          return _withOfflineBanner(
            result,
            _LessonsBySubjectList(
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
              onDeleteLesson: _confirmDeleteLesson,
            ),
          );
        },
      ),
    );
  }
}

class _ArchiveLessonsResult {
  final List<LessonModel> lessons;
  final bool isOffline;
  final String? onlineError;

  const _ArchiveLessonsResult({
    required this.lessons,
    required this.isOffline,
    this.onlineError,
  });
}

class _OfflineArchiveBanner extends StatelessWidget {
  final VoidCallback onRefreshOnline;
  final String? errorText;

  const _OfflineArchiveBanner({
    required this.onRefreshOnline,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorText == null || errorText!.isEmpty
                  ? strings.tr('lessons.archive.offline_banner')
                  : strings.tr('lessons.archive.offline_banner_error'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onRefreshOnline,
            child: Text(strings.tr('lessons.archive.retry_online')),
          ),
        ],
      ),
    );
  }
}

class _LessonsBySubjectList extends StatelessWidget {
  final String subjectId;
  final List<LessonModel> lessons;
  final VoidCallback onBackToSubjects;
  final void Function(LessonModel lesson) onOpenLesson;
  final void Function(LessonModel lesson)? onDeleteLesson;

  const _LessonsBySubjectList({
    required this.subjectId,
    required this.lessons,
    required this.onBackToSubjects,
    required this.onOpenLesson,
    this.onDeleteLesson,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBackToSubjects,
                icon: const Icon(Icons.grid_view_rounded),
                label: Text(strings.tr('lessons.all_subjects')),
              ),
              const Spacer(),
              Text(
                _subjectLabel(strings, subjectId),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: lessons.isEmpty
              ? AppEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: strings.tr('lessons.subject.empty'),
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
                        title: Text(lesson.title ?? strings.tr('lessons.lesson_fallback_title')),
                        subtitle: Text(
                          '${strings.tr('lessons.subject_label')}: ${_subjectLabel(strings, lesson.subject)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.text_snippet_outlined),
                            if (onDeleteLesson != null) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: strings.tr('lessons.delete.title'),
                                onPressed: () => onDeleteLesson!(lesson),
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ],
                          ],
                        ),
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
      final strings = AppStrings.of(context);
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: strings.tr('lessons.subjects.empty'),
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

List<_SubjectUiItem> _buildSubjectsFromLessons(
  AppStrings strings,
  List<LessonModel> lessons,
) {
  final ids = <String>{};
  for (final lesson in lessons) {
    if (lesson.subject.trim().isNotEmpty) {
      ids.add(lesson.subject.trim());
    }
  }

  final subjects = ids.map((id) => _subjectUi(strings, id)).toList();
  subjects.sort((a, b) => a.title.compareTo(b.title));
  return subjects;
}

List<_SubjectUiItem> _allStudentSubjects(
  AppStrings strings,
  List<LessonModel> lessons,
) {
  final all = <_SubjectUiItem>[
    for (final s in dictionarySubjects)
      _SubjectUiItem(
        id: s.id,
        title: strings.tr(s.titleKey),
        icon: s.icon,
        color: s.color,
      ),
  ];

  final existingIds = all.map((s) => s.id).toSet();
  for (final lesson in lessons) {
    final id = lesson.subject.trim();
    if (id.isEmpty || existingIds.contains(id)) continue;
    all.add(_subjectUi(strings, id));
    existingIds.add(id);
  }
  return all;
}

_SubjectUiItem _subjectUi(AppStrings strings, String id) {
  for (final ds in dictionarySubjects) {
    if (ds.id != id) continue;
    return _SubjectUiItem(
      id: id,
      title: strings.tr(ds.titleKey),
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
    title: _subjectLabel(strings, id),
    icon: Icons.menu_book_rounded,
    color: colors[index],
  );
}

String _subjectLabel(AppStrings strings, String subjectId) {
  return localizedSubject(strings, subjectId);
}

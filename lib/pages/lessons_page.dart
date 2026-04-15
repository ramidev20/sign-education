import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_create_page.dart';
import 'package:sign_education/pages/strategies_page.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/widgets/app_state.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class LessonsPage extends StatefulWidget {
  final UserModel user;
  const LessonsPage({super.key, required this.user});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  // Student pagination (all groups in one query)
  final ScrollController _scroll = ScrollController();
  final List<LessonModel> _lessons = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  List<String> _groupIds = [];
  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (widget.user.role == 'student') {
      _initStudent();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _initStudent() async {
    try {
      final groups = await DbHelperClasses.getClassesByStudent(widget.user.id);
      _groupIds = groups.map((g) => g.classGroupId).where((id) => id.isNotEmpty).toList();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل المجموعات: $e')),
      );
    }
  }

  Future<void> _refresh() async {
    _lessons.clear();
    _offset = 0;
    _hasMore = true;
    setState(() => _loading = true);
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _groupIds.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loadingMore = true);
    try {
      final page = await DbHelperLessons.getLessonsByClassGroupsPaged(
        classGroupIds: _groupIds,
        offset: _offset,
        limit: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _lessons.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الدروس: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _viewLessonPdf(LessonModel lesson) {
    if (lesson.fileUrl == null || lesson.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد ملف PDF لهذا الدرس')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonPdfPage(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.user.role == 'teacher';
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدروس'),
        centerTitle: true,
        actions: [
          if (isTeacher)
            IconButton(
              tooltip: 'إضافة درس',
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LessonCreatePage(user: widget.user)),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),
        ],
      ),
      body: isTeacher ? _buildTeacherView(context) : _buildStudentView(),
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
        onAction: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _lessons.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _lessons.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final lesson = _lessons[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(lesson.title ?? 'درس'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('المادة: ${subjectLabels[lesson.subject]}'),
              ),
              trailing: const Icon(Icons.picture_as_pdf_outlined),
              onTap: () => _viewLessonPdf(lesson),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherView(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = <_TeacherTile>[
      _TeacherTile(
        title: 'إضافة درس',
        icon: Icons.add_circle_outline,
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
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
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
        onTap: () {
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
        },
      ),
      _TeacherTile(
        title: 'تحديث',
        icon: Icons.refresh,
        onTap: () => setState(() {}),
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

class _TeacherLessonsArchive extends StatelessWidget {
  final UserModel user;
  const _TeacherLessonsArchive({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أرشيف الدروس')),
      body: FutureBuilder<List<LessonModel>>(
        future: DbHelperLessons.getLessonsByTeacher(user.id),
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
                  trailing: const Icon(Icons.picture_as_pdf_outlined),
                  onTap: () {
                    if (lesson.fileUrl == null || lesson.fileUrl!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لا يوجد ملف PDF لهذا الدرس')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LessonPdfPage(lesson: lesson)),
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

class LessonPdfPage extends StatelessWidget {
  final LessonModel lesson;
  const LessonPdfPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title ?? 'درس')),
      body: SfPdfViewer.network(lesson.fileUrl!),
    );
  }
}

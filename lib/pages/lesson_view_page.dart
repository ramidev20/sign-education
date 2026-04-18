import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/lesson_strategy_editor_page.dart';
import 'package:sign_education/pages/lesson_strategy_viewer.dart';
import 'package:sign_education/pages/lesson_edit_page.dart';
import 'package:sign_education/pages/strategy_json_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editor_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class LessonViewPage extends StatefulWidget {
  final LessonModel lesson;
  final UserModel user;

  const LessonViewPage({super.key, required this.lesson, required this.user});

  @override
  State<LessonViewPage> createState() => _LessonViewPageState();
}

class _LessonViewPageState extends State<LessonViewPage> {
  late LessonModel _lesson;
  late Future<List<LessonStrategyModel>> _strategiesFuture;

  bool get _isStudent => widget.user.role == 'student';

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _strategiesFuture = _fetchStrategies();
  }

  Future<List<LessonStrategyModel>> _fetchStrategies() async {
    if (_lesson.lessonId == null || _lesson.lessonId!.isEmpty) return [];
    return await DbHelperLessonStrategies.getStrategiesByLesson(
      _lesson.lessonId!,
    );
  }

  Future<void> _refreshStrategies() async {
    setState(() {
      _strategiesFuture = _fetchStrategies();
    });
  }

  Future<void> _addStrategy() async {
    if (_lesson.lessonId == null || _lesson.lessonId!.isEmpty) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStrategyEditorPage(lessonId: _lesson.lessonId!),
      ),
    );
    if (ok == true && mounted) await _refreshStrategies();
  }

  Future<void> _editLesson() async {
    final updated = await Navigator.push<LessonModel>(
      context,
      MaterialPageRoute(builder: (_) => LessonEditPage(lesson: _lesson)),
    );
    if (updated != null && mounted) {
      setState(() => _lesson = updated);
    }
  }

  Future<void> _editStrategy(LessonStrategyModel strategy) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStrategyEditorPage(
          lessonId: strategy.lessonId,
          existing: strategy,
        ),
      ),
    );
    if (ok == true && mounted) await _refreshStrategies();
  }

  Future<void> _editStrategyJson(LessonStrategyModel strategy) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StrategyJsonEditorPage(strategy: strategy),
      ),
    );
    if (ok == true && mounted) await _refreshStrategies();
  }

  Future<void> _editStrategyVisual(LessonStrategyModel strategy) async {
    final ok = await openVisualStrategyEditor(context, strategy: strategy);
    if (ok == true && mounted) await _refreshStrategies();
  }

  Future<void> _deleteStrategy(LessonStrategyModel strategy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الاستراتيجية؟'),
          content: const Text('سيتم حذفها ولن تظهر للطلاب.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    await DbHelperLessonStrategies.deleteStrategy(strategy.lessonStrategyId);
    if (mounted) await _refreshStrategies();
  }

  void _openLessonPdf() {
    if (_lesson.fileUrl == null || _lesson.fileUrl!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(_lesson.title ?? 'درس'),
            centerTitle: true,
          ),
          body: SfPdfViewer.network(_lesson.fileUrl!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = _lesson.fileUrl != null && _lesson.fileUrl!.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: _isStudent
          ? Scaffold(
              appBar: AppBar(
                title: Text(_lesson.title ?? 'درس'),
                centerTitle: true,
              ),
              body: FutureBuilder<List<LessonStrategyModel>>(
                future: _strategiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'تعذر تحميل الاستراتيجيات: ${snapshot.error}',
                        ),
                      ),
                    );
                  }

                  final strategies = snapshot.data ?? [];
                  final tileCount = strategies.length + (hasPdf ? 1 : 0);

                  if (tileCount == 0) {
                    return const Center(
                      child: Text('لا يوجد ملف ولا استراتيجيات لهذا الدرس'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refreshStrategies(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: tileCount,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemBuilder: (context, index) {
                        if (hasPdf && index == 0) {
                          return _StrategyTile(
                            title: 'الدرس (PDF)',
                            subtitle: 'المحتوى الأساسي',
                            icon: Icons.picture_as_pdf_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(_lesson.title ?? 'درس'),
                                      centerTitle: true,
                                    ),
                                    body: SfPdfViewer.network(_lesson.fileUrl!),
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        final strategyIndex = hasPdf ? index - 1 : index;
                        final s = strategies[strategyIndex];
                        final title = (s.title?.trim().isNotEmpty ?? false)
                            ? s.title!.trim()
                            : strategyLabelForType(s.strategyType);
                        return _StrategyTile(
                          title: title,
                          subtitle: strategyLabelForType(s.strategyType),
                          icon: strategyIconForType(s.strategyType),
                          onTap: () =>
                              openLessonStrategy(context, widget.user, s),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: Text(_lesson.title ?? 'درس'),
                centerTitle: true,
              ),
              body: FutureBuilder<List<LessonStrategyModel>>(
                future: _strategiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'تعذر تحميل الاستراتيجيات: ${snapshot.error}',
                        ),
                      ),
                    );
                  }

                  final strategies = snapshot.data ?? [];
                  final tileCount = strategies.length + (hasPdf ? 1 : 0);

                  return RefreshIndicator(
                    onRefresh: _refreshStrategies,
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lesson.title ?? 'درس',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'إدارة ملف الدرس والاستراتيجيات من مكان واحد.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: _addStrategy,
                                        icon: const Icon(
                                          Icons.auto_awesome_outlined,
                                        ),
                                        label: const Text('استراتيجية جديدة'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _editLesson,
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('تعديل الدرس'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (tileCount == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text('لا يوجد ملف ولا استراتيجيات بعد'),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _addStrategy,
                                    icon: const Icon(Icons.add),
                                    label: const Text('إضافة استراتيجية'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tileCount,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.9,
                                ),
                            itemBuilder: (context, index) {
                              if (hasPdf && index == 0) {
                                return _TeacherStrategyTile(
                                  title: 'الدرس (PDF)',
                                  subtitle: 'المحتوى الأساسي',
                                  icon: Icons.picture_as_pdf_outlined,
                                  onTap: _openLessonPdf,
                                  quickActions: [
                                    _QuickAction(
                                      icon: Icons.visibility_outlined,
                                      tooltip: 'عرض',
                                      onTap: _openLessonPdf,
                                    ),
                                    _QuickAction(
                                      icon: Icons.edit_note_outlined,
                                      tooltip: 'تعديل الدرس',
                                      onTap: _editLesson,
                                    ),
                                  ],
                                );
                              }

                              final strategyIndex = hasPdf ? index - 1 : index;
                              final s = strategies[strategyIndex];
                              final title =
                                  (s.title?.trim().isNotEmpty ?? false)
                                  ? s.title!.trim()
                                  : strategyLabelForType(s.strategyType);
                              return _TeacherStrategyTile(
                                title: title,
                                subtitle: strategyLabelForType(s.strategyType),
                                icon: strategyIconForType(s.strategyType),
                                onTap: () =>
                                    openLessonStrategy(context, widget.user, s),
                                quickActions: [
                                  _QuickAction(
                                    icon: Icons.visibility_outlined,
                                    tooltip: 'عرض',
                                    onTap: () => openLessonStrategy(
                                      context,
                                      widget.user,
                                      s,
                                    ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.gesture_outlined,
                                    tooltip: 'تعديل بصري',
                                    onTap: () => _editStrategyVisual(s),
                                  ),
                                  _QuickAction(
                                    icon: Icons.auto_fix_high_outlined,
                                    tooltip: 'إعادة توليد',
                                    onTap: () => _editStrategy(s),
                                  ),
                                  _QuickAction(
                                    icon: Icons.delete_outline,
                                    tooltip: 'حذف',
                                    onTap: () => _deleteStrategy(s),
                                  ),
                                ],
                                onMoreActions: (value) async {
                                  if (value == 'json') {
                                    await _editStrategyJson(s);
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _StrategyTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _StrategyTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
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
                  color: cs.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: cs.primary, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}

class _TeacherStrategyTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<_QuickAction> quickActions;
  final Future<void> Function(String value)? onMoreActions;

  const _TeacherStrategyTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.quickActions,
    this.onMoreActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: cs.primary, size: 23),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...quickActions.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Tooltip(
                          message: a.tooltip,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: a.onTap,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(
                                a.icon,
                                size: 19,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (onMoreActions != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: PopupMenuButton<String>(
                          tooltip: 'المزيد',
                          onSelected: (v) => onMoreActions!(v),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'json',
                              child: Text('تعديل يدوي (JSON)'),
                            ),
                          ],
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 19,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

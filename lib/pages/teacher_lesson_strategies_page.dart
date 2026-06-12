import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/db/db_helper_lessons.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/strategy_catalog.dart';
import 'package:sign_education/utils/strategy_functions.dart';
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

          return _StrategyCatalogStep(lessons: lessons);
        },
      ),
    );
  }
}

class _StrategyCatalogStep extends StatelessWidget {
  final List<LessonModel> lessons;

  const _StrategyCatalogStep({required this.lessons});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final items = StrategyCatalog.all
        .asMap()
        .entries
        .map(
          (entry) => _StrategyInfo(
            strategyType: entry.value.id,
            title: entry.value.label(strings),
            subtitle: _strategyDescription(strings, entry.value.id),
            icon: entry.value.icon,
            color: _strategyColor(entry.key),
          ),
        )
        .toList(growable: false);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              strings.tr('teacher_lesson_strategies.subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final item = items[index - 1];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: item.color.withValues(alpha: 0.18),
              child: Icon(item.icon, color: item.color),
            ),
            title: Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.subtitle),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => _StrategyCreateStep(
                    lessons: lessons,
                    strategyType: item.strategyType,
                  ),
                ),
              ).then((ok) {
                if (ok == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              });
            },
          ),
        );
      },
    );
  }
}

class _StrategyCreateStep extends StatefulWidget {
  final List<LessonModel> lessons;
  final String strategyType;

  const _StrategyCreateStep({
    required this.lessons,
    required this.strategyType,
  });

  @override
  State<_StrategyCreateStep> createState() => _StrategyCreateStepState();
}

class _StrategyCreateStepState extends State<_StrategyCreateStep> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _loading = false;
  String? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    if (widget.lessons.length == 1 && widget.lessons.first.lessonId != null) {
      _selectedLessonId = widget.lessons.first.lessonId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _generate(String type, String text) async {
    switch (type) {
      case 'type_0':
        return await generateMindMapFromText(text);
      case 'type_5':
        return await generateTimeLineFromText(text);
      case 'type_6':
        return await generateHierarchyFromText(text);
      case 'type_9':
        return await generateColoredCardsFromText(text);
      case 'type_10':
        return await generateComparisonTableFromText(text);
      case 'type_11':
        return await generateTriangleFromText(text);
      case 'type_12':
        return await generatesixHatFromText(text);
      case 'type_13':
        return await generateJournalisticQuestionsFromText(text);
      case 'type_14':
        return await generateEducationalStoryFromText(text);
      default:
        throw Exception('Unsupported strategy: $type');
    }
  }

  Future<void> _submit() async {
    final strings = AppStrings.read(context);

    if (!_formKey.currentState!.validate()) return;
    final lessonId = _selectedLessonId;
    if (lessonId == null) return;

    LessonModel? lesson;
    for (final item in widget.lessons) {
      if (item.lessonId == lessonId) {
        lesson = item;
        break;
      }
    }

    final lessonText = lesson?.description?.trim() ?? '';
    if (lessonText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.tr('teacher_lesson_strategies.validation.lesson_text')),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final json = await _generate(widget.strategyType, lessonText);
      final jsonWithResultType = Map<String, dynamic>.from(json)
        ..['_result_type'] = 'cardboard';
      final title = _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();

      await DbHelperLessonStrategies.createStrategy(
        lessonId: lessonId,
        strategyType: widget.strategyType,
        contentJson: jsonWithResultType,
        title: title,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.tr('teacher_lesson_strategies.success')),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('app.error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedLesson = _selectedLessonId == null
        ? null
        : widget.lessons.firstWhere(
            (lesson) => lesson.lessonId == _selectedLessonId,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('lesson_strategy_editor.add_title')),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SelectedStrategyInfo(strategyType: widget.strategyType),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLessonId,
                  decoration: InputDecoration(
                    labelText: strings.tr('teacher_lesson_strategies.lesson_label'),
                    border: const OutlineInputBorder(),
                  ),
                  items: widget.lessons
                      .where((lesson) => lesson.lessonId?.isNotEmpty == true)
                      .map(
                        (lesson) => DropdownMenuItem(
                          value: lesson.lessonId!,
                          child: Text(
                            lesson.title?.trim().isNotEmpty == true
                                ? lesson.title!.trim()
                                : strings.tr('lessons.lesson_fallback_title'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedLessonId = value);
                  },
                  validator: (value) => value == null
                      ? strings.tr(
                          'teacher_lesson_strategies.validation.lesson_pick',
                        )
                      : null,
                ),
                if (selectedLesson != null) ...[
                  const SizedBox(height: 14),
                  _SelectedLessonInfo(lesson: selectedLesson),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: strings.tr('lesson_strategy_editor.custom_title'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _loading
                        ? strings.tr('lesson_strategy_editor.generating')
                        : strings.tr('lesson_strategy_editor.create'),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.tr('lesson_strategy_editor.note'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),
        ],
      ),
    );
  }
}

class _StrategyInfo {
  final String strategyType;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StrategyInfo({
    required this.strategyType,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _SelectedStrategyInfo extends StatelessWidget {
  final String strategyType;

  const _SelectedStrategyInfo({required this.strategyType});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final strategy = StrategyCatalog.byId(strategyType);
    final label = strategy?.label(strings) ?? strings.tr('strategy.unsupported');
    final icon = strategy?.icon ?? Icons.auto_awesome_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedLessonInfo extends StatelessWidget {
  final LessonModel lesson;

  const _SelectedLessonInfo({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final subjectText = localizedSubject(strings, lesson.subject);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title?.trim().isNotEmpty == true
                      ? lesson.title!.trim()
                      : strings.tr('lessons.lesson_fallback_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${strings.tr('lessons.subject_label')}: $subjectText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _strategyDescription(AppStrings strings, String type) {
  switch (type) {
    case 'type_0':
      return strings.tr('strategy_desc.mind_map');
    case 'type_5':
      return strings.tr('strategy_desc.timeline');
    case 'type_6':
      return strings.tr('strategy_desc.hierarchy');
    case 'type_9':
      return strings.tr('strategy_desc.colored_cards');
    case 'type_10':
      return strings.tr('strategy_desc.comparison_table');
    case 'type_11':
      return strings.tr('strategy_desc.triangle');
    case 'type_12':
      return strings.tr('strategy_desc.six_hats');
    case 'type_13':
      return strings.tr('strategy_desc.journalistic_questions');
    case 'type_14':
      return strings.tr('strategy_desc.educational_story');
    default:
      return strings.tr('strategy.unsupported');
  }
}

Color _strategyColor(int index) {
  const palette = <Color>[
    Color(0xFF5B8DEF),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFF334155),
    Color(0xFF4F46E5),
    Color(0xFF059669),
  ];
  return palette[index % palette.length];
}

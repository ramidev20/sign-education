import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_live_quizzes.dart';
import 'package:sign_education/data/models/live_quiz_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/teacher_pages/live_quiz_create_page.dart';
import 'package:sign_education/pages/teacher_pages/teacher_live_quiz_room_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/widgets/app_state.dart';

class TeacherLiveQuizzesPage extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const TeacherLiveQuizzesPage({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<TeacherLiveQuizzesPage> createState() => _TeacherLiveQuizzesPageState();
}

class _TeacherLiveQuizzesPageState extends State<TeacherLiveQuizzesPage> {
  bool _loading = true;
  List<LiveQuizModel> _active = [];
  List<LiveQuizModel> _closed = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final list = await DbHelperLiveQuizzes.getQuizzesByTeacher(widget.user.id);
      if (!mounted) return;
      setState(() {
        _active = list.where((q) => q.status == 'active').toList();
        _closed = list.where((q) => q.status != 'active').toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LiveQuizCreatePage(user: widget.user)),
    );
    if (created == true) {
      await _fetch();
    }
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _buildList(List<LiveQuizModel> list) {
    final strings = AppStrings.of(context);
    if (_loading) return const AppLoading();
    if (list.isEmpty) {
      return AppEmptyState(
        icon: Icons.quiz_outlined,
        title: strings.text(
          'لا توجد اختبارات حالياً',
          'No quizzes right now',
          "Aucun quiz pour l'instant",
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final quiz = list[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(quiz.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    quiz.promptText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          quiz.status == 'active'
                              ? strings.text('مباشر', 'Live', 'En direct')
                              : strings.text('منتهي', 'Finished', 'Termine'),
                        ),
                      ),
                      Chip(label: Text(_fmt(quiz.createdAt))),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherLiveQuizRoomPage(quiz: quiz),
                  ),
                );
                if (!mounted) return;
                _fetch();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final initialIndex = widget.initialTabIndex.clamp(0, 1).toInt();

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Scaffold(
            body: Column(
              children: [
                Container(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: strings.text('مباشر', 'Live', 'En direct')),
                      Tab(
                        text: strings.text(
                          'منتهية',
                          'Finished',
                          'Termines',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildList(_active), _buildList(_closed)],
                  ),
                ),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: tabController,
              builder: (_, __) {
                if (tabController.index != 0) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add),
                  label: Text(
                    strings.text(
                      'اختبار مباشر',
                      'New live quiz',
                      'Nouveau quiz',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


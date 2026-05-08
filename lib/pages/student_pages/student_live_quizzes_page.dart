import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_live_quizzes.dart';
import 'package:sign_education/data/models/live_quiz_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/student_pages/student_live_quiz_room_page.dart';
import 'package:sign_education/widgets/app_state.dart';

class StudentLiveQuizzesPage extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const StudentLiveQuizzesPage({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<StudentLiveQuizzesPage> createState() => _StudentLiveQuizzesPageState();
}

class _StudentLiveQuizzesPageState extends State<StudentLiveQuizzesPage> {
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
      final active = await DbHelperLiveQuizzes.getQuizzesByStudent(
        widget.user.id,
        status: 'active',
      );
      final closed = await DbHelperLiveQuizzes.getQuizzesByStudent(
        widget.user.id,
        status: 'closed',
      );
      if (!mounted) return;
      setState(() {
        _active = active;
        _closed = closed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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

  Widget _buildList(List<LiveQuizModel> list, {required bool isLiveTab}) {
    if (_loading) return const AppLoading();
    if (list.isEmpty) {
      return AppEmptyState(
        icon: Icons.quiz_outlined,
        title: isLiveTab
            ? 'لا توجد اختبارات مباشرة الآن'
            : 'لا توجد اختبارات منتهية',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final q = list[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(q.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    q.promptText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(q.status == 'active' ? 'مباشر' : 'منتهي')),
                      Chip(label: Text(_fmt(q.createdAt))),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StudentLiveQuizRoomPage(user: widget.user, quiz: q),
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
    final initialIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        initialIndex: initialIndex,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              child: const TabBar(
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'مباشر الآن'),
                  Tab(text: 'المنتهية'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildList(_active, isLiveTab: true),
                  _buildList(_closed, isLiveTab: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


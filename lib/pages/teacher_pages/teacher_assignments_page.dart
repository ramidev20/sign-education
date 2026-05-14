import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/pages/teacher_pages/assigment_add.dart';
import 'package:sign_education/pages/teacher_pages/assignment_deliveries_page.dart';
import 'package:sign_education/utils/app_theme.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const TeacherAssignmentsPage({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  List<AssignmentModel> currentAssignments = [];
  List<AssignmentModel> archivedAssignments = [];
  Map<String, dynamic> statusLabels = {
    'pending': "مستمر",
    'completed': "مكتمل",
    'archived': "مصحح",
  };

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    final assignments = await DbHelperAssignments.getAssignmentsByTeacher(
      widget.user.id,
    );
    setState(() {
      currentAssignments = assignments
          .where((a) => a.status == 'pending')
          .toList();
      archivedAssignments = assignments
          .where((a) => a.status == 'archived')
          .toList();
    });
  }

  String _fmtDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final initialIndex = widget.initialTabIndex.clamp(0, 2).toInt();
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Scaffold(
            body: Column(
              children: [
                Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.05),
                  child: const TabBar(
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'إدارة الواجبات'),
                      Tab(text: 'التسليمات'),
                      Tab(text: 'الأرشيف'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildActiveAssignmentsTab(),
                      _buildDeliveriesTab(),
                      _buildArchiveTab(),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                return tabController.index == 0
                    ? FloatingActionButton(
                        backgroundColor: AppTheme.brand,
                        foregroundColor: Colors.white,
                        onPressed: () async {
                          final added = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AssignmentAddPage(user: widget.user),
                            ),
                          );
                          if (added == true) fetchAssignments();
                        },
                        child: const Icon(Icons.add),
                      )
                    : const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveAssignmentsTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: currentAssignments.map((a) {
      final title = (a.title ?? '').trim().isEmpty ? 'واجب' : a.title!.trim();
      final qCount =
          ((a.assignmentContentJson?['questions'] as List?) ?? const []).length;
      final due = _fmtDateTime(a.completeAt);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('المادة: ${subjectLabels[a.subject]}')),
                  Chip(label: Text('عدد الأسئلة: $qCount')),
                  Chip(label: Text('التسليم: $due')),
                  Chip(label: Text('الحالة: ${statusLabels[a.status]}')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.preview_outlined),
                      label: const Text('التسليمات'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentDeliveriesPage(
                              assignmentId: a.assignmentId!,
                              title: a.title ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildDeliveriesTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: currentAssignments.map((assignment) {
      final qCount =
          ((assignment.assignmentContentJson?['questions'] as List?) ??
                  const [])
              .length;
      return Card(
        child: ListTile(
          title: Text(assignment.title ?? ''),
          subtitle: Text(
            "عدد التسليمات: ${assignment.submissionsCount ?? 0} • عدد الأسئلة: $qCount",
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssignmentDeliveriesPage(
                  assignmentId: assignment.assignmentId!,
                  title: assignment.title ?? '',
                ),
              ),
            );
          },
        ),
      );
    }).toList(),
  );

  Widget _buildArchiveTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: archivedAssignments.map((a) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(a.title ?? ''),
          subtitle: const Text('مؤرشف'),
        ),
      );
    }).toList(),
  );
}

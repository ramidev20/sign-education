import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/pages/teacher_pages/assigment_add.dart';
import 'package:sign_education/pages/teacher_pages/assignment_deliveries_page.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/utils/pdf_viewer_page.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  final UserModel user;

  const TeacherAssignmentsPage({super.key, required this.user});

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              animation: tabController!,
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
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(a.title ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("المادة: ${subjectLabels[a.subject]}"),
              Text("التسليم: ${a.completeAt.toString().substring(0, 16)}"),
              Text("الحالة: ${statusLabels[a.status]}"),
            ],
          ),
          onTap: () {
            if (a.fileUrl != null && a.fileUrl!.endsWith(".pdf")) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PdfViewerPage(filePath: a.fileUrl!, title: a.title ?? ""),
                ),
              );
            }
          },
        ),
      );
    }).toList(),
  );

  Widget _buildDeliveriesTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: currentAssignments.map((assignment) {
      return Card(
        child: ListTile(
          title: Text(assignment.title ?? ''),
          subtitle: Text("عدد التسليمات: ${assignment.submissionsCount ?? 0}"),
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

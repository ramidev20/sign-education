import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/teacher_pages/assigment_add.dart';
import 'package:sign_education/pages/teacher_pages/assignment_deliveries_page.dart';
import 'package:sign_education/utils/app_strings.dart';
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

  String _subjectFilter = 'all';
  String _sortKey = 'due_desc';

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    final assignments = await DbHelperAssignments.getAssignmentsByTeacher(
      widget.user.id,
    );
    if (!mounted) return;
    setState(() {
      currentAssignments = assignments
          .where((a) => a.status != 'archived' && a.status != 'completed')
          .toList();
      archivedAssignments = assignments
          .where((a) => a.status == 'archived' || a.status == 'completed')
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

  String _subjectLabel(AppStrings strings, String subjectKey) {
    switch (subjectKey) {
      case 'math':
        return strings.text('رياضيات', 'Mathematics', 'Mathematiques');
      case 'physics':
        return strings.text('فيزياء', 'Physics', 'Physique');
      case 'chemistry':
        return strings.text('كيمياء', 'Chemistry', 'Chimie');
      case 'biology':
      case 'natural_sciences':
        return strings.text('علوم طبيعية', 'Natural sciences', 'Sciences naturelles');
      case 'history':
        return strings.text('تاريخ', 'History', 'Histoire');
      case 'geography':
        return strings.text('جغرافيا', 'Geography', 'Geographie');
      case 'history_geography':
        return strings.text('تاريخ وجغرافيا', 'History and geography', 'Histoire et geographie');
      case 'philosophy':
        return strings.text('فلسفة', 'Philosophy', 'Philosophie');
      case 'languages':
      case 'language':
        return strings.text('لغات', 'Languages', 'Langues');
      case 'arabic':
        return strings.text('اللغة العربية', 'Arabic language', 'Langue arabe');
      case 'english':
        return strings.text('اللغة الإنجليزية', 'English language', 'Langue anglaise');
      case 'french':
        return strings.text('اللغة الفرنسية', 'French language', 'Langue francaise');
      default:
        return subjectKey;
    }
  }

  String _statusLabel(AppStrings strings, String status) {
    switch (status) {
      case 'pending':
      case 'active':
        return strings.text('مستمر', 'Active', 'En cours');
      case 'completed':
        return strings.text('مكتمل', 'Completed', 'Termine');
      case 'archived':
        return strings.text('مؤرشف', 'Archived', 'Archive');
      default:
        return status;
    }
  }

  List<AssignmentModel> _applyFilters(List<AssignmentModel> input) {
    Iterable<AssignmentModel> out = input;
    if (_subjectFilter != 'all') {
      out = out.where((a) => a.subject == _subjectFilter);
    }

    final list = out.toList();
    switch (_sortKey) {
      case 'due_asc':
        list.sort((a, b) => a.completeAt.compareTo(b.completeAt));
        break;
      case 'created_asc':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'created_desc':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        list.sort((a, b) => b.completeAt.compareTo(a.completeAt));
    }

    return list;
  }

  Widget _filtersBar(AppStrings strings) {
    final allSubjects = <String>{
      ...currentAssignments.map((a) => a.subject),
      ...archivedAssignments.map((a) => a.subject),
    }.toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          final subject = DropdownButtonFormField<String>(
            value: _subjectFilter,
            decoration: InputDecoration(
              labelText: strings.text('المادة', 'Subject', 'Matiere'),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(strings.text('الكل', 'All', 'Tous')),
              ),
              ...allSubjects.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_subjectLabel(strings, s)),
                ),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _subjectFilter = v);
            },
          );

          final sort = DropdownButtonFormField<String>(
            value: _sortKey,
            decoration: InputDecoration(
              labelText: strings.text('الترتيب', 'Sort', 'Tri'),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              DropdownMenuItem(
                value: 'due_desc',
                child: Text(
                  strings.text(
                    'الأقرب موعدا',
                    'Nearest due date',
                    'Echeance la plus proche',
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'due_asc',
                child: Text(
                  strings.text(
                    'الأبعد موعدا',
                    'Latest due date',
                    'Echeance la plus lointaine',
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'created_desc',
                child: Text(
                  strings.text('الأحدث إضافة', 'Newest first', 'Plus recent'),
                ),
              ),
              DropdownMenuItem(
                value: 'created_asc',
                child: Text(
                  strings.text('الأقدم إضافة', 'Oldest first', 'Plus ancien'),
                ),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _sortKey = v);
            },
          );

          if (isNarrow) {
            return Column(
              children: [
                subject,
                const SizedBox(height: 10),
                sort,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: subject),
              const SizedBox(width: 12),
              Expanded(child: sort),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
                  ).colorScheme.primary.withValues(alpha: 0.05),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        text: strings.text(
                          'إدارة الواجبات',
                          'Assignments',
                          'Devoirs',
                        ),
                      ),
                      Tab(
                        text: strings.text(
                          'التسليمات',
                          'Deliveries',
                          'Remises',
                        ),
                      ),
                      Tab(
                        text: strings.text('الأرشيف', 'Archive', 'Archives'),
                      ),
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
                              builder: (_) => AssignmentAddPage(user: widget.user),
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

  Widget _buildActiveAssignmentsTab() {
    final strings = AppStrings.of(context);
    final list = _applyFilters(currentAssignments);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _filtersBar(strings),
        ...list.map((assignment) {
          final title = (assignment.title ?? '').trim().isEmpty
              ? strings.text('واجب', 'Assignment', 'Devoir')
              : assignment.title!.trim();
          final qCount =
              ((assignment.assignmentContentJson?['questions'] as List?) ?? const [])
                  .length;
          final due = _fmtDateTime(assignment.completeAt);

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
                      Chip(
                        label: Text(
                          '${strings.text('المادة', 'Subject', 'Matiere')}: ${_subjectLabel(strings, assignment.subject)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${strings.text('عدد الأسئلة', 'Questions', 'Questions')}: $qCount',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${strings.text('التسليم', 'Due', 'Echeance')}: $due',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${strings.text('الحالة', 'Status', 'Statut')}: ${_statusLabel(strings, assignment.status)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.preview_outlined),
                          label: Text(
                            strings.text('التسليمات', 'Deliveries', 'Remises'),
                          ),
                          onPressed: () {
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeliveriesTab() {
    final strings = AppStrings.of(context);
    final list = _applyFilters(currentAssignments);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _filtersBar(strings),
        ...list.map((assignment) {
          final qCount =
              ((assignment.assignmentContentJson?['questions'] as List?) ?? const [])
                  .length;

          return Card(
            child: ListTile(
              title: Text(assignment.title ?? ''),
              subtitle: Text(
                '${strings.text('عدد التسليمات', 'Submissions', 'Remises')}: ${assignment.submissionsCount ?? 0} • ${strings.text('عدد الأسئلة', 'Questions', 'Questions')}: $qCount',
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                child: const Icon(Icons.assignment_turned_in_outlined),
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
        }),
      ],
    );
  }

  Widget _buildArchiveTab() {
    final strings = AppStrings.of(context);
    final list = _applyFilters(archivedAssignments);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _filtersBar(strings),
        ...list.map((assignment) {
          return Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(assignment.title ?? ''),
              subtitle: Text(_statusLabel(strings, assignment.status)),
            ),
          );
        }),
      ],
    );
  }
}

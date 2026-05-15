import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_education/data/models/assignment_delivery_model.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/data/labels_data.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/widgets/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveredAssignment {
  final AssignmentModel assignment;
  final DeliveryModel delivery;

  DeliveredAssignment({required this.assignment, required this.delivery});
}

class StudentAssignmentsPage extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const StudentAssignmentsPage({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ScrollController _currentScroll = ScrollController();

  final List<Map<String, dynamic>> _shareRows = [];
  List<DeliveryModel> _deliveries = [];
  List<AssignmentModel> currentAssignments = [];
  List<DeliveredAssignment> deliveredAssignments = [];
  bool hasNewAssignment = false;
  bool _markedSeenThisSession = false;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 30;

  String _deliveredSubjectFilter = 'all';
  String _deliveredSortKey = 'date_desc';

  @override
  void initState() {
    super.initState();
    _currentScroll.addListener(_onScroll);
    fetchAssignments(reset: true);
  }

  @override
  void dispose() {
    _currentScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_currentScroll.hasClients) return;
    if (_currentScroll.position.pixels >=
        _currentScroll.position.maxScrollExtent - 200) {
      fetchAssignments(reset: false);
    }
  }

  Future<void> fetchAssignments({required bool reset}) async {
    try {
      if (reset) {
        setState(() {
          _loading = true;
          _loadingMore = false;
          _hasMore = true;
          _offset = 0;
          _shareRows.clear();
          _deliveries = [];
        });
      } else {
        if (_loadingMore || !_hasMore) return;
        setState(() => _loadingMore = true);
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSeenStr =
          prefs.getString('last_seen_assignments_${widget.user.id}') ??
          prefs.getString('last_seen_date_${widget.user.id}');
      final lastSeen = lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null;

      final sharedResult = await supabase
          .from('assignment_shares')
          .select('created_at, assignments!assignment_shares_assignment_fk(*)')
          .eq('user_id', widget.user.id)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _pageSize - 1);

      final sharedRows = (sharedResult as List).cast<Map<String, dynamic>>();
      _shareRows.addAll(sharedRows);
      _offset += sharedRows.length;
      _hasMore = sharedRows.length == _pageSize;

      final hasNew = lastSeen == null
          ? false
          : sharedRows.any((row) {
              final createdAt =
                  DateTime.tryParse(row['created_at']?.toString() ?? '');
              return createdAt != null && createdAt.isAfter(lastSeen);
            });

      if (_deliveries.isEmpty || reset) {
        final deliveredResult = await supabase
            .from('assignments_deliveries')
            .select()
            .eq('user_id', widget.user.id)
            .order('delivery_date', ascending: false)
            .limit(500);

        _deliveries = (deliveredResult as List)
            .map((d) => DeliveryModel.fromMap(d))
            .toList();
      }

      final allAssignments = _shareRows
          .map((row) => AssignmentModel.fromMap(row['assignments']))
          .toList();

      final deliveriesByAssignment = {
        for (final d in _deliveries) d.assignmentId: d,
      };
      final assignmentById = {for (final a in allAssignments) a.assignmentId: a};

      if (!mounted) return;
      setState(() {
        currentAssignments = allAssignments
            .where((a) {
              final notDelivered = !deliveriesByAssignment.containsKey(
                a.assignmentId,
              );
              final notArchived = a.status != 'archived' && a.status != 'completed';
              return notDelivered && notArchived;
            })
            .toList();

        deliveredAssignments = _deliveries
            .where((d) => assignmentById.containsKey(d.assignmentId))
            .map(
              (d) => DeliveredAssignment(
                assignment: assignmentById[d.assignmentId]!,
                delivery: d,
              ),
            )
            .toList();

        hasNewAssignment = hasNew;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e, st) {
      debugPrint('Error fetching assignments: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التحميل: $e')),
      );
    }
  }

  Future<void> _markAssignmentsSeenIfNeeded() async {
    if (_markedSeenThisSession) return;
    if (!hasNewAssignment) return;

    _markedSeenThisSession = true;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_seen_assignments_${widget.user.id}',
      DateTime.now().toIso8601String(),
    );

    if (!mounted) return;
    setState(() => hasNewAssignment = false);
  }

  String _fmtDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _openSolveAssignment(AssignmentModel assignment) async {
    final delivered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentSolvePage(
          user: widget.user,
          assignment: assignment,
        ),
      ),
    );
    if (delivered == true) {
      await fetchAssignments(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              child: TabBar(
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: badges.Badge(
                      showBadge: hasNewAssignment,
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red,
                        padding: EdgeInsets.all(6),
                      ),
                      position: badges.BadgePosition.topEnd(top: -10, end: -12),
                      badgeContent: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: hasNewAssignment ? 1.15 : 1.0),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeInOut,
                        builder: (context, v, child) => Transform.scale(
                          scale: v,
                          child: child,
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      child: const Text('الواجبات الحالية'),
                    ),
                  ),
                  const Tab(text: 'التسليمات'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCurrentAssignmentsTab(),
                  _buildDeliveredAssignmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAssignmentsTab() {
    if (_loading) return const AppLoading();
    if (currentAssignments.isEmpty) {
      return AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'لا توجد واجبات حالية',
        actionLabel: 'تحديث',
        onAction: () => fetchAssignments(reset: true),
      );
    }

    _markAssignmentsSeenIfNeeded();

    return RefreshIndicator(
      onRefresh: () => fetchAssignments(reset: true),
      child: ListView.builder(
        controller: _currentScroll,
        padding: const EdgeInsets.all(16),
        itemCount: currentAssignments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= currentAssignments.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final assignment = currentAssignments[index];
          final title = assignment.title ?? 'واجب';
          final description = assignment.description ?? '';
          final qCount = ((assignment.assignmentContentJson?['questions'] as List?) ?? const []).length;
          final due = _fmtDateTime(assignment.completeAt);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openSolveAssignment(assignment),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasNewAssignment && index == 0) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'لديك واجبات جديدة!',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('عدد الأسئلة: $qCount')),
                        Chip(label: Text('التسليم: $due')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_note_outlined, size: 18),
                        label: const Text('حل الواجب'),
                        onPressed: () => _openSolveAssignment(assignment),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveredAssignmentsTab() {
    if (_loading) return const AppLoading();
    if (deliveredAssignments.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_done_outlined,
        title: 'لا توجد تسليمات بعد',
        actionLabel: 'تحديث',
        onAction: () => fetchAssignments(reset: true),
      );
    }

    final allSubjects = <String>{}
      ..addAll(deliveredAssignments.map((d) => d.assignment.subject));
    final subjects = allSubjects.toList()..sort();

    List<DeliveredAssignment> filtered = deliveredAssignments;
    if (_deliveredSubjectFilter != 'all') {
      filtered = filtered
          .where((d) => d.assignment.subject == _deliveredSubjectFilter)
          .toList();
    }

    if (_deliveredSortKey == 'date_asc') {
      filtered.sort((a, b) => a.delivery.deliveryDate.compareTo(b.delivery.deliveryDate));
    } else {
      filtered.sort((a, b) => b.delivery.deliveryDate.compareTo(a.delivery.deliveryDate));
    }

    return RefreshIndicator(
      onRefresh: () => fetchAssignments(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _deliveredSubjectFilter,
                      decoration: const InputDecoration(
                        labelText: 'المادة',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('الكل')),
                        ...subjects.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(subjectLabels[s] ?? s),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _deliveredSubjectFilter = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _deliveredSortKey,
                      decoration: const InputDecoration(
                        labelText: 'الترتيب',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('الأحدث')),
                        DropdownMenuItem(value: 'date_asc', child: Text('الأقدم')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _deliveredSortKey = v);
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          final deliveredItem = filtered[index - 1];
          final assignment = deliveredItem.assignment;
          final delivery = deliveredItem.delivery;

          Color statusColor;
          String statusText;
          IconData statusIcon;

          switch (delivery.status) {
            case 'approved':
              statusColor = AppTheme.success;
              statusText = 'تمت الموافقة على التسليم';
              statusIcon = Icons.check_circle;
              break;
            case 'rejected':
              statusColor = Theme.of(context).colorScheme.error;
              statusText = 'تم رفض التسليم';
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = AppTheme.warning;
              statusText = 'في انتظار المراجعة';
              statusIcon = Icons.hourglass_empty;
          }

          final title = assignment.title ?? 'واجب';
          final answered = ((delivery.answersJson?['answers'] as List?) ?? const []).length;
          final subjectText = subjectLabels[assignment.subject] ?? assignment.subject;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('المادة: $subjectText')),
                      Chip(
                        avatar: Icon(statusIcon, size: 18, color: statusColor),
                        label: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: statusColor.withValues(alpha: 0.10),
                        side: BorderSide(color: statusColor.withValues(alpha: 0.22)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('إجابات مسلّمة: $answered'),
                  const SizedBox(height: 4),
                  Text(
                    "تم التسليم في: ${delivery.deliveryDate.toString().substring(0, 16)}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  if (delivery.status == 'rejected' &&
                      delivery.statusComment.isNotEmpty) ...[
                    const Divider(height: 18),
                    Text("ملاحظة المعلم: ${delivery.statusComment}"),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AssignmentSolvePage extends StatefulWidget {
  final UserModel user;
  final AssignmentModel assignment;

  const AssignmentSolvePage({
    super.key,
    required this.user,
    required this.assignment,
  });

  @override
  State<AssignmentSolvePage> createState() => _AssignmentSolvePageState();
}

class _AssignmentSolvePageState extends State<AssignmentSolvePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _selectedChoices = {};
  final Map<String, Set<String>> _multiSelected = {};
  final Map<String, bool?> _trueFalseSelected = {};
  bool _submitting = false;

  List<Map<String, dynamic>> get _questions {
    final raw = widget.assignment.assignmentContentJson?['questions'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void initState() {
    super.initState();
    for (final question in _questions) {
      final id = question['id']?.toString() ?? '';
      final type = question['type']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (type == 'short_text' || type == 'paragraph' || type == 'number') {
        _textControllers[id] = TextEditingController();
      }
      if (type == 'multi_select') {
        _multiSelected[id] = <String>{};
      }
      if (type == 'true_false') {
        _trueFalseSelected[id] = null;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final answers = <Map<String, dynamic>>[];
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final id = question['id']?.toString() ?? '';
      final type = question['type']?.toString() ?? '';
      if (id.isEmpty) continue;

      dynamic value;
      if (type == 'mcq') {
        value = (_selectedChoices[id] ?? '').trim();
      } else if (type == 'multi_select') {
        value = (_multiSelected[id] ?? <String>{}).toList();
      } else if (type == 'true_false') {
        value = _trueFalseSelected[id];
      } else if (type == 'number') {
        final raw = _textControllers[id]?.text.trim() ?? '';
        final allowDecimal = question['allow_decimal'] is bool
            ? (question['allow_decimal'] as bool)
            : true;
        final min = question['min'] is num ? (question['min'] as num) : null;
        final max = question['max'] is num ? (question['max'] as num) : null;

        if (raw.isEmpty) value = null;
        if (raw.isNotEmpty) {
          final parsed = allowDecimal ? double.tryParse(raw) : int.tryParse(raw);
          if (parsed == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تحقق من إجابة السؤال رقم ${i + 1}')),
            );
            return;
          }
          if (min != null && parsed < min) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('إجابة السؤال رقم ${i + 1} أقل من الحد الأدنى')),
            );
            return;
          }
          if (max != null && parsed > max) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('إجابة السؤال رقم ${i + 1} أكبر من الحد الأقصى')),
            );
            return;
          }
          value = parsed;
        }
      } else {
        value = (_textControllers[id]?.text.trim() ?? '').trim();
      }

      final isEmpty = value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty);
      if (isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('أكمل إجابة السؤال رقم ${i + 1} قبل التسليم')),
        );
        return;
      }
      answers.add({
        'question_id': id,
        'type': type,
        'value': value,
      });
    }

    setState(() => _submitting = true);
    try {
      await supabase.from('assignments_deliveries').insert({
        'assignment_id': widget.assignment.assignmentId,
        'user_id': widget.user.id,
        'username': widget.user.name,
        'file_url': '',
        'answers_json': {'answers': answers},
        'delivery_date': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسليم الإجابات بنجاح')),
      );

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) => Transform.scale(
                      scale: v,
                      child: child,
                    ),
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppTheme.success,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تم التسليم بنجاح',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'شكراً لك! سيتم مراجعة إجاباتك من طرف المعلم.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('العودة'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في التسليم: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.assignment.title ?? 'واجب';

    final answeredCount = _questions.where((q) {
      final id = q['id']?.toString() ?? '';
      final type = q['type']?.toString() ?? '';
      if (id.isEmpty) return false;
      if (type == 'mcq') return (_selectedChoices[id] ?? '').trim().isNotEmpty;
      if (type == 'multi_select') return (_multiSelected[id] ?? {}).isNotEmpty;
      if (type == 'true_false') return _trueFalseSelected[id] != null;
      final text = _textControllers[id]?.text.trim() ?? '';
      return text.isNotEmpty;
    }).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((widget.assignment.description ?? '').trim().isNotEmpty)
                      Text(widget.assignment.description!),
                    if ((widget.assignment.description ?? '').trim().isNotEmpty)
                      const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('عدد الأسئلة: ${_questions.length}')),
                        Chip(label: Text('المجاب: $answeredCount')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _questions.isEmpty
                          ? 0
                          : (answeredCount / _questions.length),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_questions.isEmpty)
              const AppEmptyState(
                icon: Icons.quiz_outlined,
                title: 'لا توجد أسئلة لهذا الواجب',
              )
            else
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final id = question['id']?.toString() ?? '';
                final type = question['type']?.toString() ?? 'short_text';
                final prompt = question['prompt']?.toString() ?? '';
                final options = (question['options'] as List? ?? const [])
                    .map((e) => e.toString())
                    .toList();
                final allowDecimal = question['allow_decimal'] is bool
                    ? (question['allow_decimal'] as bool)
                    : true;

                final isAnswered = () {
                  if (type == 'mcq') {
                    return (_selectedChoices[id] ?? '').trim().isNotEmpty;
                  }
                  if (type == 'multi_select') {
                    return (_multiSelected[id] ?? {}).isNotEmpty;
                  }
                  if (type == 'true_false') {
                    return _trueFalseSelected[id] != null;
                  }
                  return (_textControllers[id]?.text.trim() ?? '').isNotEmpty;
                }();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'سؤال ${index + 1}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isAnswered
                                  ? Icons.check_circle_outline
                                  : Icons.circle_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prompt,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        if (type == 'mcq')
                          ...options.map(
                            (option) => RadioListTile<String>(
                              value: option,
                              groupValue: _selectedChoices[id],
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) => setState(
                                () => _selectedChoices[id] = value ?? '',
                              ),
                              title: Text(option),
                            ),
                          )
                        else if (type == 'multi_select')
                          ...options.map(
                            (option) => CheckboxListTile(
                              value: (_multiSelected[id] ?? {}).contains(option),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (checked) => setState(() {
                                final set = _multiSelected[id] ?? <String>{};
                                if (checked == true) {
                                  set.add(option);
                                } else {
                                  set.remove(option);
                                }
                                _multiSelected[id] = set;
                              }),
                              title: Text(option),
                            ),
                          )
                        else if (type == 'true_false')
                          Column(
                            children: [
                              RadioListTile<bool>(
                                value: true,
                                groupValue: _trueFalseSelected[id],
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setState(
                                  () => _trueFalseSelected[id] = v,
                                ),
                                title: const Text('صح'),
                              ),
                              RadioListTile<bool>(
                                value: false,
                                groupValue: _trueFalseSelected[id],
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setState(
                                  () => _trueFalseSelected[id] = v,
                                ),
                                title: const Text('خطأ'),
                              ),
                            ],
                          )
                        else if (type == 'number')
                          TextField(
                            controller: _textControllers[id],
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: allowDecimal,
                              signed: false,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'أدخل رقمًا',
                            ),
                          )
                        else
                          TextField(
                            controller: _textControllers[id],
                            maxLines: type == 'paragraph' ? 5 : 1,
                            decoration: const InputDecoration(
                              hintText: 'اكتب إجابتك هنا',
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_submitting ? 'جارٍ التسليم...' : 'تسليم الإجابات'),
          ),
        ),
      ),
    );
  }
}

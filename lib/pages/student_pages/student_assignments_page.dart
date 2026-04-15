import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_education/data/models/assignment_delivery_model.dart';
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/widgets/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DeliveredAssignment {
  final AssignmentModel assignment;
  final DeliveryModel delivery;

  DeliveredAssignment({required this.assignment, required this.delivery});
}

class StudentAssignmentsPage extends StatefulWidget {
  final UserModel user;
  const StudentAssignmentsPage({super.key, required this.user});

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

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 30;

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
      final lastSeenStr = prefs.getString('last_seen_date_${widget.user.id}');
      final lastSeen = lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null;

      final sharedResult = await supabase
          .from('assignment_shares')
          .select('created_at, assignments(*)')
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
              final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
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

      final deliveriesByAssignment = {for (final d in _deliveries) d.assignmentId: d};
      final assignmentById = {for (final a in allAssignments) a.assignmentId: a};

      if (!mounted) return;
      setState(() {
        currentAssignments = allAssignments
            .where((a) => !deliveriesByAssignment.containsKey(a.assignmentId))
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

      await prefs.setString(
        'last_seen_date_${widget.user.id}',
        DateTime.now().toIso8601String(),
      );
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

  Future<void> uploadAssignment(AssignmentModel assignment) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["pdf"],
    );

    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final fileName = "deliveries/${widget.user.id}_${assignment.assignmentId}.pdf";

    try {
      await supabase.storage.from('assignments').upload(
            fileName,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      final fileUrl = supabase.storage.from('assignments').getPublicUrl(fileName);

      await supabase.from('assignments_deliveries').insert({
        'assignment_id': assignment.assignmentId,
        'user_id': widget.user.id,
        'username': widget.user.name,
        'file_url': fileUrl,
        'delivery_date': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسليم الواجب بنجاح بانتظار المراجعة')),
      );

      await fetchAssignments(reset: true);
    } catch (e, st) {
      debugPrint('Upload error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في رفع الملف: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                      badgeContent: const Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
          final fileUrl = assignment.fileUrl;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.assignment_turned_in_outlined),
              title: Text(title),
              subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: FilledButton.icon(
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('تسليم'),
                onPressed: () => uploadAssignment(assignment),
              ),
              onTap: fileUrl == null || fileUrl.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfPage(title: title, fileUrl: fileUrl),
                        ),
                      );
                    },
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

    return RefreshIndicator(
      onRefresh: () => fetchAssignments(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveredAssignments.length,
        itemBuilder: (context, index) {
          final deliveredItem = deliveredAssignments[index];
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

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        color: AppTheme.brand,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPage(title: title, fileUrl: delivery.fileUrl),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.comment,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "ملاحظة المعلم: ${delivery.statusComment}",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class PdfPage extends StatelessWidget {
  final String title;
  final String fileUrl;
  const PdfPage({super.key, required this.title, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SfPdfViewer.network(fileUrl),
    );
  }
}


import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/models/assignment_delivery_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart' as badges;
import 'package:sign_education/data/models/assignment_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Combines an assignment and its delivery info
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
  List<AssignmentModel> currentAssignments = [];
  List<DeliveredAssignment> deliveredAssignments = [];
  bool hasNewAssignment = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Get assignments shared directly with this student
      final sharedResult = await supabase
          .from('assignment_shares')
          .select('assignments(*)')
          .eq('user_id', widget.user.id);

      final allAssignments = (sharedResult as List)
          .map((row) => AssignmentModel.fromMap(row['assignments']))
          .toList();

      // ✅ Get all deliveries for this student
      final deliveredResult = await supabase
          .from('assignments_deliveries')
          .select()
          .eq('user_id', widget.user.id);

      final deliveries = (deliveredResult as List)
          .map((d) => DeliveryModel.fromMap(d))
          .toList();

      // ✅ Split between current and delivered
      setState(() {
        currentAssignments = allAssignments
            .where(
              (a) => !deliveries.any((d) => d.assignmentId == a.assignmentId),
            )
            .toList();

        deliveredAssignments = deliveries.map((delivery) {
          final relatedAssignment = allAssignments.firstWhere(
            (a) => a.assignmentId == delivery.assignmentId,
          );
          return DeliveredAssignment(
            assignment: relatedAssignment,
            delivery: delivery,
          );
        }).toList();
      });

      await prefs.setString(
        'last_seen_date_${widget.user.id}',
        DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      debugPrint('❌ Error fetching assignments: $e\n$st');
    }
  }

  Future<void> uploadAssignment(AssignmentModel assignment) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileName =
          "deliveries/${widget.user.id}_${assignment.assignmentId}.pdf";

      try {
        await supabase.storage
            .from('assignments')
            .upload(
              fileName,
              File(filePath),
              fileOptions: const FileOptions(upsert: true),
            );

        final fileUrl = supabase.storage
            .from('assignments')
            .getPublicUrl(fileName);

        await supabase.from('assignments_deliveries').insert({
          'assignment_id': assignment.assignmentId,
          'user_id': widget.user.id,
          'username': widget.user.name,
          'file_url': fileUrl,
          'delivery_date': DateTime.now().toIso8601String(),
          'status': 'pending',
        });

        //update delivery counter in assignments table increment by 1
        Future<void> uploadAssignment(AssignmentModel assignment) async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ["pdf"],
          );

          if (result != null && result.files.single.path != null) {
            final filePath = result.files.single.path!;
            final fileName =
                "deliveries/${widget.user.id}_${assignment.assignmentId}.pdf";

            try {
              await supabase.storage
                  .from('assignments')
                  .upload(
                    fileName,
                    File(filePath),
                    fileOptions: const FileOptions(upsert: true),
                  );

              final fileUrl = supabase.storage
                  .from('assignments')
                  .getPublicUrl(fileName);

              await supabase.from('assignments_deliveries').insert({
                'assignment_id': assignment.assignmentId,
                'user_id': widget.user.id,
                'username': widget.user.name,
                'file_url': fileUrl,
                'delivery_date': DateTime.now().toIso8601String(),
                'status': 'pending',
              });

              // ✅ Increment delivery_count in assignments table
              await supabase
                  .from('assignments')
                  .update({'delivery_count': assignment.submissionsCount! + 1})
                  .eq('id', assignment.assignmentId as Object);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم تسليم الواجب بنجاح بانتظار المراجعة'),
                ),
              );

              fetchAssignments();
            } catch (e) {
              debugPrint('❌ فشل في رفع الملف: $e');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('❌ فشل في رفع الملف: $e')));
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تسليم الواجب بنجاح بانتظار المراجعة'),
          ),
        );

        fetchAssignments();
      } catch (e) {
        debugPrint('❌ فشل في رفع الملف: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ فشل في رفع الملف: $e')));
      }
    }
  }

  Widget _buildCurrentAssignmentsTab() {
    if (currentAssignments.isEmpty) {
      return const Center(child: Text('لا توجد واجبات حالية'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentAssignments.length,
      itemBuilder: (context, index) {
        final assignment = currentAssignments[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.globalRadius),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          child: ListTile(
            title: Text(assignment.title!),
            subtitle: Text(assignment.description ?? ''),
            trailing: FilledButton.icon(
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('تسليم'),
              onPressed: () => uploadAssignment(assignment),
            ),
            onTap: () {
              if (assignment.fileUrl!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfPage(
                      title: assignment.title!,
                      fileUrl: assignment.fileUrl!,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("لا يوجد PDF")));
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDeliveredAssignmentsTab() {
    if (deliveredAssignments.isEmpty) {
      return const Center(child: Text('لا توجد تسليمات بعد'));
    }

    return ListView.builder(
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
            statusColor = Colors.green;
            statusText = 'تمت الموافقة على التسليم';
            statusIcon = Icons.check_circle;
            break;
          case 'rejected':
            statusColor = Colors.red;
            statusText = 'تم رفض التسليم';
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.orange;
            statusText = 'في انتظار المراجعة';
            statusIcon = Icons.hourglass_empty;
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.globalRadius),
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignment Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title ?? '',
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      color: AppTheme.brand,
                      onPressed: () {
                        if (delivery.fileUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPage(
                                title: assignment.title ?? '',
                                fileUrl: delivery.fileUrl,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("لا يوجد ملف PDF")),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Status Row
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

                // Date
                Text(
                  "🕒 تم التسليم في: ${delivery.deliveryDate.toString().substring(0, 16)}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),

                // Optional rejection comment
                if (delivery.status == 'rejected' &&
                    delivery.statusComment.isNotEmpty) ...[
                  const Divider(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.comment, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "ملاحظة المعلم: ${delivery.statusComment}",
                            style: const TextStyle(
                              color: Colors.red,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: AppTheme.brand,
                labelColor: AppTheme.brand,
                unselectedLabelColor: Colors.grey,
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

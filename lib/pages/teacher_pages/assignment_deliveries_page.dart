import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/models/assignment_delivery_model.dart';
import 'package:sign_education/data/db/db_helper_deliveries.dart';
import 'package:sign_education/utils/app_theme.dart';

class AssignmentDeliveriesPage extends StatefulWidget {
  final String assignmentId;
  final String title;

  const AssignmentDeliveriesPage({
    super.key,
    required this.assignmentId,
    required this.title,
  });

  @override
  State<AssignmentDeliveriesPage> createState() =>
      _AssignmentDeliveriesPageState();
}

class _AssignmentDeliveriesPageState extends State<AssignmentDeliveriesPage> {
  List<DeliveryModel> deliveries = [];
  Map<String, Map<String, dynamic>> _questionById = {};

  @override
  void initState() {
    super.initState();
    _loadAssignmentQuestions();
    fetchDeliveries();
  }

  Future<void> _loadAssignmentQuestions() async {
    try {
      final assignment =
          await DbHelperAssignments.getAssignmentById(widget.assignmentId);
      final raw = assignment?.assignmentContentJson?['questions'];
      if (raw is! List) return;

      final map = <String, Map<String, dynamic>>{};
      for (final q in raw.whereType<Map>()) {
        final qq = Map<String, dynamic>.from(q);
        final id = (qq['id'] ?? '').toString();
        if (id.isEmpty) continue;
        map[id] = qq;
      }

      if (!mounted) return;
      setState(() => _questionById = map);
    } catch (_) {
      // ignore (preview will fallback to generic labels)
    }
  }

  String _formatAnswerValue(dynamic value) {
    if (value is bool) return value ? 'صح' : 'خطأ';
    if (value is List) return value.map((e) => e.toString()).join('، ');
    return (value ?? '').toString();
  }

  Future<void> fetchDeliveries() async {
    final list = await DbHelperDeliveries.getDeliveriesByAssignment(
      widget.assignmentId,
    );
    setState(() => deliveries = list);
  }

  Future<void> _showRejectDialog(DeliveryModel delivery) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("رفض التسليم"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("يرجى كتابة سبب الرفض:"),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "مثلاً: الملف غير مكتمل أو الحل غير صحيح",
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text("تأكيد الرفض"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await DbHelperDeliveries.updateDeliveryStatus(
        deliveryId: delivery.deliveryId!,
        status: 'rejected',
        comment: result, // 🆕 Store rejection reason
      );
      fetchDeliveries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تسليمات ${widget.title}')),
      body: deliveries.isEmpty
          ? Center(
              child: Text(
                "لا توجد تسليمات بعد",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final d = deliveries[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      d.username,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          "تم التسليم: ${d.deliveryDate.toString().substring(0, 16)}",
                        ),
                        if (d.status == 'approved')
                          Text(
                            "✅ تم القبول",
                            style: TextStyle(color: AppTheme.success),
                          ),
                        if (d.status == 'rejected') ...[
                          Text(
                            "❌ تم الرفض",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          if (d.statusComment.isNotEmpty)
                            Text(
                              "السبب: ${d.statusComment}",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((d.answersJson?['answers'] as List?) != null)
                          IconButton(
                            icon: Icon(
                              Icons.preview_outlined,
                              color: AppTheme.brand,
                            ),
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('إجابات ${d.username}'),
                                  content: SizedBox(
                                    width: 420,
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        ...((d.answersJson?['answers'] as List?) ??
                                                const [])
                                            .whereType<Map>()
                                            .map(
                                              (a) {
                                                final aa =
                                                    Map<String, dynamic>.from(a);
                                                final qid =
                                                    (aa['question_id'] ?? '')
                                                        .toString();
                                                final q =
                                                    _questionById[qid] ?? <String, dynamic>{};
                                                final prompt =
                                                    (q['prompt'] ?? 'سؤال')
                                                        .toString();
                                                final type =
                                                    (aa['type'] ?? '').toString();
                                                final value = aa['value'];

                                                return ListTile(
                                                  title: Text(prompt),
                                                  subtitle: Text(
                                                    _formatAnswerValue(value),
                                                  ),
                                                  trailing: Text(
                                                    type,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إغلاق'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        PopupMenuButton<String>(
                          onSelected: (choice) async {
                            if (choice == 'accept') {
                              await DbHelperDeliveries.updateDeliveryStatus(
                                deliveryId: d.deliveryId!,
                                status: 'approved',
                              );
                              fetchDeliveries();
                            } else if (choice == 'reject') {
                              await _showRejectDialog(d);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'accept',
                              child: Text('قبول'),
                            ),
                            const PopupMenuItem(
                              value: 'reject',
                              child: Text('رفض'),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

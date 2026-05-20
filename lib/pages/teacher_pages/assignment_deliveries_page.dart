import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_assigments.dart';
import 'package:sign_education/data/db/db_helper_deliveries.dart';
import 'package:sign_education/data/models/assignment_delivery_model.dart';
import 'package:sign_education/utils/app_strings.dart';
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

  AppStrings get _strings =>
      AppStrings(Localizations.localeOf(context).languageCode);

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
      // Keep generic preview labels if loading fails.
    }
  }

  String _formatAnswerValue(AppStrings strings, dynamic value) {
    if (value is bool) {
      return value
          ? strings.text('صح', 'True', 'Vrai')
          : strings.text('خطأ', 'False', 'Faux');
    }
    if (value is List) return value.map((e) => e.toString()).join(', ');
    return (value ?? '').toString();
  }

  String _statusText(AppStrings strings, String status) {
    switch (status) {
      case 'approved':
        return strings.text('تم القبول', 'Approved', 'Approuve');
      case 'rejected':
        return strings.text('تم الرفض', 'Rejected', 'Refuse');
      default:
        return strings.text('بانتظار المراجعة', 'Pending review', 'En attente de revision');
    }
  }

  Future<void> fetchDeliveries() async {
    final list = await DbHelperDeliveries.getDeliveriesByAssignment(
      widget.assignmentId,
    );
    if (!mounted) return;
    setState(() => deliveries = list);
  }

  Future<void> _showRejectDialog(DeliveryModel delivery) async {
    final strings = _strings;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('رفض التسليم', 'Reject submission', 'Refuser la remise')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.text(
                'يرجى كتابة سبب الرفض:',
                'Please enter the rejection reason:',
                'Veuillez saisir la raison du refus :',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: strings.text(
                  'مثلا: الحل غير مكتمل',
                  'For example: the work is incomplete',
                  'Par exemple : le travail est incomplet',
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(
              strings.text('تأكيد الرفض', 'Confirm rejection', 'Confirmer le refus'),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await DbHelperDeliveries.updateDeliveryStatus(
        deliveryId: delivery.deliveryId!,
        status: 'rejected',
        comment: result,
      );
      fetchDeliveries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${strings.text('تسليمات', 'Deliveries', 'Remises')} ${widget.title}',
        ),
      ),
      body: deliveries.isEmpty
          ? Center(
              child: Text(
                strings.text(
                  'لا توجد تسليمات بعد',
                  'No deliveries yet',
                  'Aucune remise pour le moment',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      delivery.username,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${strings.text('تم التسليم', 'Submitted', 'Remis')}: ${delivery.deliveryDate.toString().substring(0, 16)}',
                        ),
                        Text(
                          _statusText(strings, delivery.status),
                          style: TextStyle(
                            color: delivery.status == 'approved'
                                ? AppTheme.success
                                : delivery.status == 'rejected'
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (delivery.status == 'rejected' &&
                            delivery.statusComment.isNotEmpty)
                          Text(
                            '${strings.text('السبب', 'Reason', 'Raison')}: ${delivery.statusComment}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((delivery.answersJson?['answers'] as List?) != null)
                          IconButton(
                            icon: Icon(
                              Icons.preview_outlined,
                              color: AppTheme.brand,
                            ),
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    '${strings.text('إجابات', 'Answers', 'Reponses')} ${delivery.username}',
                                  ),
                                  content: SizedBox(
                                    width: 420,
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        ...((delivery.answersJson?['answers'] as List?) ??
                                                const [])
                                            .whereType<Map>()
                                            .map((answer) {
                                              final typedAnswer =
                                                  Map<String, dynamic>.from(answer);
                                              final questionId =
                                                  (typedAnswer['question_id'] ?? '')
                                                      .toString();
                                              final question =
                                                  _questionById[questionId] ??
                                                      <String, dynamic>{};
                                              final prompt = (question['prompt'] ??
                                                      strings.text('سؤال', 'Question', 'Question'))
                                                  .toString();
                                              final type =
                                                  (typedAnswer['type'] ?? '')
                                                      .toString();
                                              final value = typedAnswer['value'];

                                              return ListTile(
                                                title: Text(prompt),
                                                subtitle: Text(
                                                  _formatAnswerValue(strings, value),
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
                                            }),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(strings.text('إغلاق', 'Close', 'Fermer')),
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
                                deliveryId: delivery.deliveryId!,
                                status: 'approved',
                              );
                              fetchDeliveries();
                            } else if (choice == 'reject') {
                              await _showRejectDialog(delivery);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'accept',
                              child: Text(
                                strings.text('قبول', 'Approve', 'Approuver'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'reject',
                              child: Text(
                                strings.text('رفض', 'Reject', 'Refuser'),
                              ),
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

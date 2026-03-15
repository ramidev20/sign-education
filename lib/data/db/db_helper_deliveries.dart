import 'package:sign_education/data/models/assignment_delivery_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbHelperDeliveries {
  static final _supabase = Supabase.instance.client;

  static Future<List<DeliveryModel>> getDeliveriesByAssignment(
    String assignmentId,
  ) async {
    final res = await _supabase
        .from('assignments_deliveries')
        .select()
        .eq('assignment_id', assignmentId)
        .order('delivery_date', ascending: false);
    return (res as List).map((data) => DeliveryModel.fromMap(data)).toList();
  }

  static Future<void> addDelivery(DeliveryModel delivery) async {
    await _supabase.from('assignments_deliveries').insert(delivery.toMap());
  }

  static Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? comment,
  }) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('assignments_deliveries')
        .update({
          'status': status,
          if (comment != null) 'status_comment': comment,
        })
        .eq('delivery_id', deliveryId);
  }
}

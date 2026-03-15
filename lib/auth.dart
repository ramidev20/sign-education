import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String _userKey = "app_user";
  static const String _lastSyncKey = "last_sync_time";

  /// Save logged-in user
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Retrieve logged-in user
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr == null) return null;
    return UserModel.fromJson(jsonDecode(jsonStr));
  }

  /// Clear user data
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_lastSyncKey);
  }

  /// Save last sync timestamp
  static Future<void> _saveLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  /// Get last sync timestamp
  static Future<DateTime?> _getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastSyncKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Called on app start or login to check for new data added while the app was closed
  static Future<void> checkForNewContent() async {
    final user = await getUser();
    if (user == null) return;

    final supabase = Supabase.instance.client;
    final lastSync = await _getLastSync();
    final now = DateTime.now();

    try {
      if (user.role == 'student') {
        // 🔹 Get new lessons (created after last sync)
        final lessons = await supabase
            .from('lessons')
            .select()
            .gte('created_at', lastSync?.toIso8601String() ?? '1970-01-01');

        final newLessons = lessons.length;

        // 🔹 Get new assignments shared with this student
        final assignments = await supabase
            .from('assignment_shares')
            .select()
            .eq('user_id', user.id)
            .gte('created_at', lastSync?.toIso8601String() ?? '1970-01-01');

        final newAssignments = assignments.length;

        if (newLessons > 0) {
          await NotificationService.showOrUpdateNotification(
            id: 10,
            title: '📘 دروس جديدة',
            body: 'تمت إضافة $newLessons درس جديد أثناء غيابك.',
            payload: 'lessons',
          );
        }

        if (newAssignments > 0) {
          await NotificationService.showOrUpdateNotification(
            id: 11,
            title: '📢 واجبات جديدة',
            body: 'تمت إضافة $newAssignments واجب جديد أثناء غيابك.',
            payload: 'assignments',
          );
        }
      } else {
        // 🔹 Get all deliveries since last sync
        final deliveries = await supabase
            .from('assignments_deliveries')
            .select('assignment_id, created_at')
            .gte('created_at', lastSync?.toIso8601String() ?? '1970-01-01');

        if (deliveries.isEmpty) {
          await _saveLastSync(now);
          return;
        }

        // 🔹 Extract unique assignment IDs
        final deliveryAssignmentIds = deliveries
            .map((d) => d['assignment_id'] as String)
            .toSet()
            .toList();

        // 🔹 Get assignments that belong to this teacher
        final teacherAssignments = await supabase
            .from('assignments')
            .select('assignment_id, title')
            .eq('teacher_id', user.id)
            .inFilter('assignment_id', deliveryAssignmentIds);

        if (teacherAssignments.isEmpty) {
          await _saveLastSync(now);
          return;
        }

        // 🔹 Build notification text
        final titles = teacherAssignments.map((a) => a['title']).toList();
        final count = titles.length;
        final titleText = count == 1 ? '📨 تسليم جديد' : '📨 تسليمات جديدة';
        final bodyText = count == 1
            ? 'تم تسليم واجب جديد: ${titles.first}'
            : 'تسليمات جديدة في: ${titles.take(3).join(", ")}${titles.length > 3 ? " وغيرها" : ""}';

        await NotificationService.showOrUpdateNotification(
          id: 12,
          title: titleText,
          body: bodyText,
          payload: 'delivered_assignments',
        );
      }
    } catch (e) {
      print('StorageService.checkForNewContent error: $e');
    }

    // Save last sync time
    await _saveLastSync(now);
  }
}

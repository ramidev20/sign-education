// lib/services/realtime_listener_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_education/utils/notification_service.dart';
import 'package:flutter/foundation.dart';

class RealtimeListenerService {
  static final RealtimeListenerService _instance =
      RealtimeListenerService._internal();

  factory RealtimeListenerService() => _instance;
  RealtimeListenerService._internal();

  final SupabaseClient supabase = Supabase.instance.client;
  RealtimeChannel? _lessonChannel;
  RealtimeChannel? _assignmentChannel;
  RealtimeChannel? _liveQuizChannel;
  RealtimeChannel? _deliveryChannel;

  bool _isListening = false;
  DateTime? _lastLessonTime;
  DateTime? _lastAssignmentTime;
  DateTime? _lastLiveQuizTime;
  DateTime? _lastDeliveryTime;

  /// Start realtime listeners
  Future<void> start(String userId, String role) async {
    if (_isListening) {
      debugPrint('RealtimeListenerService: already running');
      return;
    }

    _isListening = true;

    await Future.delayed(const Duration(milliseconds: 500));

    if (role == 'student') {
      _listenToNewLessons(userId);
      _listenToNewAssignments(userId);
      _listenToNewLiveQuizzes(userId);
    } else if (role == 'teacher') {
      _listenToNewDeliveries(userId);
    }
  }

  Future<void> stop() async {
    await _lessonChannel?.unsubscribe();
    await _assignmentChannel?.unsubscribe();
    await _liveQuizChannel?.unsubscribe();
    await _deliveryChannel?.unsubscribe();
    _lessonChannel = null;
    _assignmentChannel = null;
    _liveQuizChannel = null;
    _deliveryChannel = null;
    _isListening = false;
  }

  /// 🧑‍🎓 Students → Listen to new lessons
  void _listenToNewLessons(String userId) {
    _lessonChannel ??= supabase.channel('lesson_listener');

    _lessonChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'lessons',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            debugPrint('RealtimeListenerService: lesson payload -> $newRecord');

            final classGroupId = newRecord['class_group_id'];
            if (!await _studentInClassGroup(userId, classGroupId)) return;

            final now = DateTime.now();
            if (_lastLessonTime != null &&
                now.difference(_lastLessonTime!).inSeconds < 3) {
              return;
            }
            _lastLessonTime = now;

            final lessonTitle = newRecord['title'] ?? 'درس جديد';
            await NotificationService.showOrUpdateNotification(
              id: 2,
              title: '📘 درس جديد',
              body: 'تم نشر "$lessonTitle".',
              payload: 'lessons',
            );
          },
        )
        .subscribe();

    debugPrint('RealtimeListenerService: listening to lessons...');
  }

  /// 🧑‍🎓 Students → Listen to new assignments shared with them
  void _listenToNewAssignments(String userId) {
    _assignmentChannel ??= supabase.channel('assignment_listener_$userId');

    _assignmentChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'assignment_shares',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            debugPrint(
              'RealtimeListenerService: assignment payload -> $newRecord',
            );

            final now = DateTime.now();
            if (_lastAssignmentTime != null &&
                now.difference(_lastAssignmentTime!).inSeconds < 3) {
              return;
            }
            _lastAssignmentTime = now;

            // Optional: fetch assignment name for better message
            final assignment = await supabase
                .from('assignments')
                .select('title')
                .eq('assignment_id', newRecord['assignment_id'])
                .maybeSingle();

            final assignmentTitle = assignment?['title'] ?? 'واجب جديد';

            await NotificationService.showOrUpdateNotification(
              id: 1,
              title: '📢 واجب جديد',
              body: 'تمت إضافة "$assignmentTitle".',
              payload: 'assignments',
            );
          },
        )
        .subscribe();

    debugPrint(
      'RealtimeListenerService: listening to assignments for $userId...',
    );
  }

  /// 🧑‍🎓 Students → Listen to new live quizzes for their groups
  void _listenToNewLiveQuizzes(String userId) {
    _liveQuizChannel ??= supabase.channel('live_quiz_listener_$userId');

    _liveQuizChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_quizzes',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final classGroupId = (newRecord['class_group_id'] ?? '').toString();
            if (classGroupId.isEmpty) return;
            if (!await _studentInClassGroup(userId, classGroupId)) return;

            final now = DateTime.now();
            if (_lastLiveQuizTime != null &&
                now.difference(_lastLiveQuizTime!).inSeconds < 3) {
              return;
            }
            _lastLiveQuizTime = now;

            final quizTitle = (newRecord['title'] ?? 'اختبار مباشر').toString();
            await NotificationService.showOrUpdateNotification(
              id: 4,
              title: '🧠 اختبار مباشر جديد',
              body: 'تم بدء "$quizTitle" الآن.',
              payload: 'live_quizzes',
            );
          },
        )
        .subscribe();

    debugPrint(
      'RealtimeListenerService: listening to live quizzes for $userId...',
    );
  }

  /// 👨‍🏫 Teachers → Listen to new student deliveries
  void _listenToNewDeliveries(String teacherId) {
    _deliveryChannel ??= supabase.channel('delivery_listener_$teacherId');

    _deliveryChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'assignments_deliveries',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            debugPrint(
              'RealtimeListenerService: delivery payload -> $newRecord',
            );

            // Find the teacher of this assignment
            final assignment = await supabase
                .from('assignments')
                .select('teacher_id, title')
                .eq('assignment_id', newRecord['assignment_id'])
                .maybeSingle();

            if (assignment == null) {
              debugPrint('No assignment found for delivery');
              return;
            }

            if (assignment['teacher_id'] != teacherId) {
              debugPrint('Delivery not for this teacher');
              return;
            }

            final now = DateTime.now();
            if (_lastDeliveryTime != null &&
                now.difference(_lastDeliveryTime!).inSeconds < 3) {
              return;
            }
            _lastDeliveryTime = now;

            final assignmentTitle = assignment['title'] ?? 'واجب';
            final studentName = newRecord['username'] ?? 'طالب';

            await NotificationService.showOrUpdateNotification(
              id: 3,
              title: '📨 تسليم جديد',
              body: '$studentName قام بتسليم "$assignmentTitle".',
              payload: 'delivered_assignments',
            );
          },
        )
        .subscribe();

    debugPrint(
      'RealtimeListenerService: listening to deliveries for teacher $teacherId...',
    );
  }

  /// Helper → Check if student belongs to a class group
  Future<bool> _studentInClassGroup(String userId, String classGroupId) async {
    try {
      final res = await supabase
          .from('class_group_members')
          .select()
          .eq('user_id', userId)
          .eq('class_group_id', classGroupId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint(
        'RealtimeListenerService: error checking class membership: $e',
      );
      return false;
    }
  }
}

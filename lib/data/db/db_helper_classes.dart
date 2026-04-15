import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DbHelperClasses {
  static final supabase = Supabase.instance.client;

  static const List<String> _usersEmbeds = [
    'users!class_group_members_user_fk(*)',
    'users!class_group_members_user_id_fkey(*)',
  ];

  static const List<String> _usersNameEmbeds = [
    'users!class_group_members_user_fk(name)',
    'users!class_group_members_user_id_fkey(name)',
  ];

  static Future<List<dynamic>> _selectMembersWithUsers({
    required String classGroupId,
    String? role,
    required bool nameOnly,
  }) async {
    final embeds = nameOnly ? _usersNameEmbeds : _usersEmbeds;

    Future<List<dynamic>> run(String embed) async {
      var q = supabase.from('class_group_members').select(embed).eq(
            'class_group_id',
            classGroupId,
          );
      if (role != null) q = q.eq('role', role);
      return await q;
    }

    try {
      return await run(embeds[0]);
    } on PostgrestException catch (e) {
      // Ambiguous relationship or missing named relationship; try the alternative.
      debugPrint('DbHelperClasses: embed failed (${embeds[0]}): ${e.code} ${e.message}');
      return await run(embeds[1]);
    }
  }

  /// Create a new class/group
  static Future<void> createClassGroup({
    required String level,
    required String branch,
    required String subject,
    required String teacherId,
    required String avatarColor,
    required String name,
  }) async {
    final classGroupId = "${level}_${branch}_${subject}";

    await supabase.from('class_groups').insert({
      'class_group_id': classGroupId,
      'level': level,
      'branch': branch,
      'subject': subject,
      'teacher_id': teacherId,
      'avatar_color': avatarColor,
      'name': name,
    });

    // add teacher as member with role "teacher"
    await supabase.from('class_group_members').insert({
      'class_group_id': classGroupId,
      'user_id': teacherId,
      'role': 'teacher',
    });
  }

  /// Add student to class
  static Future<void> addStudentToClass({
    required String classGroupId,
    required String studentId,
  }) async {
    await supabase.from('class_group_members').insert({
      'class_group_id': classGroupId,
      'user_id': studentId,
      'role': 'student',
    });
  }

  /// Remove student from class
  static Future<void> removeStudentFromClass(
    String classGroupId,
    String studentId,
  ) async {
    await supabase
        .from('class_group_members')
        .delete()
        .eq('class_group_id', classGroupId)
        .eq('user_id', studentId);
  }

  /// Fetch all classes for a teacher
  static Future<List<ClassGroupModel>> getClassesByTeacher(
    String teacherId,
  ) async {
    final res = await supabase
        .from('class_groups')
        .select()
        .eq('teacher_id', teacherId);

    return (res as List).map((map) => ClassGroupModel.fromMap(map)).toList();
  }

  static Future<List<ClassGroupModel>> getClassesByStudent(
    String studentId,
  ) async {
    final response = await Supabase.instance.client
        .from('class_group_members')
        .select('class_group_id, class_groups(*)')
        .eq('user_id', studentId);

    final List<ClassGroupModel> groups = [];
    for (var row in response) {
      final g = row['class_groups'];
      if (g != null) {
        groups.add(ClassGroupModel.fromMap(Map<String, dynamic>.from(g)));
      }
    }
    return groups;
  }

  /// Fetch the latest text message (ignores images, attachments, etc.)
  static Future<String?> getLatestTextMessage(String classGroupId) async {
    final res = await supabase
        .from('messages')
        .select('text')
        .eq('class_group_id', classGroupId)
        .not('text', 'is', null) // exclude null
        .neq('text', '') // exclude empty
        .order('created_at', ascending: false)
        .limit(1);

    if (res.isNotEmpty) {
      return res.first['text'] as String;
    }
    return null;
  }

  /// Fetch members of a class
  static Future<List<UserModel>> getMembers(String classGroupId) async {
    final res = await _selectMembersWithUsers(
      classGroupId: classGroupId,
      nameOnly: false,
    );

    return res
        .map((row) {
          final userData = row['users'];
          if (userData != null) {
            return UserModel.fromMap(Map<String, dynamic>.from(userData));
          }
          return null;
        })
        .whereType<UserModel>()
        .toList();
  }

  static Future<List<UserModel>> getStudentsByGroup(String groupId) async {
    final res = await _selectMembersWithUsers(
      classGroupId: groupId,
      role: 'student',
      nameOnly: false,
    );

    return (res as List).map((r) => UserModel.fromJson(r['users'])).toList();
  }

  /// Delete entire class (only teacher can do this)
  static Future<void> deleteClassGroup(String classGroupId) async {
    await supabase
        .from('class_groups')
        .delete()
        .eq('class_group_id', classGroupId);
  }

  /// Search user by email
  static Future<UserModel?> findUserByEmail(String email) async {
    final res = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (res == null) return null;
    return UserModel.fromMap(res); // ✅ use fromMap instead of fromJson
  }

  /// Fetch all messages for a group
  static Future<List<Map<String, dynamic>>> getGroupMessages(
    String classGroupId,
  ) async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('class_group_id', classGroupId)
        .order('created_at');

    return (res as List).map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// Send a message to a group
  static Future<void> sendMessageToGroup({
    required String classGroupId,
    required String senderId,
    required String text,
  }) async {
    await supabase.from('messages').insert({
      'class_group_id': classGroupId,
      'sender_id': senderId,
      'text': text,
    });
  }

  /// Subscribe to new messages in a group (real-time updates)
  static Future<RealtimeChannel?> subscribeToGroupMessages({
    required String classGroupId,
    required Future<void> Function(Map<String, dynamic> payload) onMessage,
  }) async {
    try {
      final channel = supabase.channel('messages');

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'class_group_id',
          value: classGroupId,
        ),
        callback: (payload, [_]) async {
          // Extract the new row
          final newRow = (payload).newRecord;
          debugPrint('New message row: $newRow');
          await onMessage(newRow);
        },
      );

      await channel.subscribe();
      debugPrint('- Subscribed to chat: $classGroupId');
      return channel;
    } catch (e, st) {
      debugPrint('- Error subscribing: $e\n$st');
      return null;
    }
  }
}

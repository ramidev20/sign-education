import 'package:sign_education/data/models/live_quiz_entry_model.dart';
import 'package:sign_education/data/models/live_quiz_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbHelperLiveQuizzes {
  static final supabase = Supabase.instance.client;

  static Future<String> createQuiz(LiveQuizModel quiz) async {
    final res = await supabase
        .from('live_quizzes')
        .insert(quiz.toMap())
        .select('quiz_id')
        .single();
    return res['quiz_id'].toString();
  }

  static Future<void> closeQuiz(String quizId) async {
    await supabase
        .from('live_quizzes')
        .update({
          'status': 'closed',
          'ends_at': DateTime.now().toIso8601String(),
        })
        .eq('quiz_id', quizId);
  }

  static Future<LiveQuizModel?> getQuizById(String quizId) async {
    final res = await supabase
        .from('live_quizzes')
        .select()
        .eq('quiz_id', quizId)
        .maybeSingle();
    if (res == null) return null;
    return LiveQuizModel.fromMap(Map<String, dynamic>.from(res));
  }

  static Future<List<LiveQuizModel>> getQuizzesByTeacher(
    String teacherId,
  ) async {
    final res = await supabase
        .from('live_quizzes')
        .select()
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false)
        .limit(250);
    return (res as List)
        .map((e) => LiveQuizModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<LiveQuizModel>> getQuizzesByStudent(
    String studentId, {
    String? status,
  }) async {
    final groupsRes = await supabase
        .from('class_group_members')
        .select('class_group_id')
        .eq('user_id', studentId)
        .eq('role', 'student');

    final groupIds = (groupsRes as List)
        .map((e) => (e['class_group_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (groupIds.isEmpty) return const [];

    var query = supabase
        .from('live_quizzes')
        .select()
        .inFilter('class_group_id', groupIds);

    if (status != null) query = query.eq('status', status);

    final res = await query.order('created_at', ascending: false).limit(250);
    return (res as List)
        .map((e) => LiveQuizModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> addEntry(LiveQuizEntryModel entry) async {
    await supabase.from('live_quiz_entries').insert(entry.toMap());
  }

  static Future<List<LiveQuizEntryModel>> getEntriesByQuiz(String quizId) async {
    final res = await supabase
        .from('live_quiz_entries')
        .select()
        .eq('quiz_id', quizId)
        .order('created_at', ascending: true)
        .limit(2000);

    return (res as List)
        .map((e) => LiveQuizEntryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}

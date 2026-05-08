import 'package:sign_education/data/models/lesson_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

////////////////////////////////////////////////////////////////////////////////////////////
/// Handles Supabase queries related to lessons.
/// ///////////////////////////////////////////////////////////////////////////////
class DbHelperLessons {
  static final supabase = Supabase.instance.client;

  /// Insert a new lesson into the database.
  static Future<void> createLesson(LessonModel lesson) async {
    await supabase.from('lessons').insert(lesson.toMap());
  }

  /// Fetch a single lesson by ID.
  static Future<LessonModel?> getLessonById(String lessonId) async {
    final res = await supabase
        .from('lessons')
        .select()
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (res == null) return null;
    return LessonModel.fromMap(res);
  }

  /// Fetch all lessons for a specific class group.
  static Future<List<LessonModel>> getLessonsByClassGroup(
    String classGroupId,
  ) async {
    final res = await supabase
        .from('lessons')
        .select(
          'lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, created_at',
        )
        .eq('class_group_id', classGroupId)
        .order('created_at', ascending: false)
        .limit(200);

    return (res as List).map((map) => LessonModel.fromMap(map)).toList();
  }

  /// Fetch all lessons created by a specific teacher.
  static Future<List<LessonModel>> getLessonsByTeacher(String teacherId) async {
    final res = await supabase
        .from('lessons')
        .select(
          'lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, created_at',
        )
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false)
        .limit(200);

    return (res as List).map((map) => LessonModel.fromMap(map)).toList();
  }

  static Future<List<LessonModel>> getLessonsByClassGroupsPaged({
    required List<String> classGroupIds,
    required int offset,
    required int limit,
  }) async {
    if (classGroupIds.isEmpty) return [];

    final res = await supabase
        .from('lessons')
        .select(
          'lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, created_at',
        )
        .inFilter('class_group_id', classGroupIds)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (res as List).map((map) => LessonModel.fromMap(map)).toList();
  }

  /// Update an existing lesson by ID.
  static Future<void> updateLesson(
    String lessonId,
    Map<String, dynamic> data,
  ) async {
    await supabase.from('lessons').update(data).eq('lesson_id', lessonId);
  }

  /// Delete a lesson by ID.
  static Future<void> deleteLesson(String lessonId) async {
    await supabase.from('lessons').delete().eq('lesson_id', lessonId);
  }
}

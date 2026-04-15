import 'package:sign_education/data/models/lesson_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
          'lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, file_url, created_at',
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
          'lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, file_url, created_at',
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
          'lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, file_url, created_at',
        )
        .inFilter('class_group_id', classGroupIds)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (res as List).map((map) => LessonModel.fromMap(map)).toList();
  }

  /// Update an existing lesson by ID.
  /// If `newFileUrl` is provided, remove the old file from storage first.
  static Future<void> updateLesson(
    String lessonId,
    Map<String, dynamic> data, {
    String? oldFileUrl,
    String? newFileUrl,
  }) async {
    // If a new file is uploaded, delete the old one
    if (newFileUrl != null && oldFileUrl != null && oldFileUrl.isNotEmpty) {
      final oldPath = _extractStoragePath(oldFileUrl);
      if (oldPath != null) {
        await supabase.storage.from("lessons").remove([oldPath]);
      }
      data['file_url'] = newFileUrl;
    }

    await supabase.from('lessons').update(data).eq('lesson_id', lessonId);
  }

  /// Delete a lesson by ID (also deletes its storage file if exists).
  static Future<void> deleteLesson(String lessonId) async {
    final lesson = await getLessonById(lessonId);
    if (lesson != null && lesson.fileUrl != null) {
      final storagePath = _extractStoragePath(lesson.fileUrl!);
      debugPrint("Deleting storage file: $storagePath");
      if (storagePath != null) {
        try {
          final res = await supabase.storage.from("lessons").remove([
            storagePath,
          ]);
          debugPrint("Delete response: $res");
        } catch (e) {
          debugPrint("Storage delete error: $e");
        }
      }
    }

    await supabase.from('lessons').delete().eq('lesson_id', lessonId);
  }

  /// Helper to get storage path from a Supabase public URL
  static String? _extractStoragePath(String publicUrl) {
    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;

      final lessonsIndex = segments.indexOf("lessons");
      if (lessonsIndex != -1 && lessonsIndex + 1 < segments.length) {
        return segments.sublist(lessonsIndex + 1).join("/");
      }
      return null;
    } catch (e) {
      debugPrint("extract error: $e");
      return null;
    }
  }
}

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
        .select()
        .eq('class_group_id', classGroupId);

    return (res as List).map((map) => LessonModel.fromMap(map)).toList();
  }

  /// Fetch all lessons created by a specific teacher.
  static Future<List<LessonModel>> getLessonsByTeacher(String teacherId) async {
    final res = await supabase
        .from('lessons')
        .select()
        .eq('teacher_id', teacherId);

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
      print("Deleting storage file: $storagePath");
      if (storagePath != null) {
        try {
          final res = await supabase.storage.from("lessons").remove([
            storagePath,
          ]);
          print("Delete response: $res");
        } catch (e) {
          print("Storage delete error: $e");
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
      print("extract error: $e");
      return null;
    }
  }
}

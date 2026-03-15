import 'package:sign_education/data/models/assignment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

////////////////////////////////////////////////////////////////////////////////////////////
/// Handles Supabase queries related to assignments.
////////////////////////////////////////////////////////////////////////////////////////////
class DbHelperAssignments {
  static final supabase = Supabase.instance.client;

  /// Insert a new assignment into the database.
  static Future<String> createAssignment(AssignmentModel assignment) async {
    final response = await supabase
        .from('assignments')
        .insert(assignment.toMap())
        .select('assignment_id')
        .single();

    return response['assignment_id'] as String;
  }

  static Future<void> shareAssignment(
    String assignmentId,
    String studentId,
  ) async {
    await supabase.from('assignment_shares').insert({
      'assignment_id': assignmentId,
      'user_id': studentId,
    });
  }

  /// Fetch a single assignment by ID.
  static Future<AssignmentModel?> getAssignmentById(String assignmentId) async {
    final res = await supabase
        .from('assignments')
        .select()
        .eq('assignment_id', assignmentId)
        .maybeSingle();

    if (res == null) return null;
    return AssignmentModel.fromMap(res);
  }

  /// Fetch all assignments for a specific class group.
  static Future<List<AssignmentModel>> getAssignmentsByClassGroup(
    String classGroupId,
  ) async {
    final res = await supabase
        .from('assignments')
        .select()
        .eq('class_group_id', classGroupId);

    return (res as List).map((map) => AssignmentModel.fromMap(map)).toList();
  }

  /// Fetch all assignments created by a specific teacher.
  static Future<List<AssignmentModel>> getAssignmentsByTeacher(
    String teacherId,
  ) async {
    final res = await supabase
        .from('assignments')
        .select()
        .eq('teacher_id', teacherId);

    return (res as List).map((map) => AssignmentModel.fromMap(map)).toList();
  }

  /// Update an existing assignment by ID.
  /// If `newFileUrl` is provided, remove the old file from storage first.
  static Future<void> updateAssignment(
    String assignmentId,
    Map<String, dynamic> data, {
    String? oldFileUrl,
    String? newFileUrl,
  }) async {
    // If a new file is uploaded, delete the old one
    if (newFileUrl != null && oldFileUrl != null && oldFileUrl.isNotEmpty) {
      final oldPath = _extractStoragePath(oldFileUrl);
      if (oldPath != null) {
        await supabase.storage.from("assignments").remove([oldPath]);
      }
      data['file_url'] = newFileUrl;
    }

    await supabase
        .from('assignments')
        .update(data)
        .eq('assignment_id', assignmentId);
  }

  /// Delete an assignment by ID (also deletes its storage file if exists).
  static Future<void> deleteAssignment(String assignmentId) async {
    final assignment = await getAssignmentById(assignmentId);
    if (assignment != null && assignment.fileUrl != null) {
      final storagePath = _extractStoragePath(assignment.fileUrl!);
      print("Deleting storage file: $storagePath");
      if (storagePath != null) {
        try {
          final res = await supabase.storage.from("assignments").remove([
            storagePath,
          ]);
          print("Delete response: $res");
        } catch (e) {
          print("Storage delete error: $e");
        }
      }
    }

    await supabase
        .from('assignments')
        .delete()
        .eq('assignment_id', assignmentId);
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

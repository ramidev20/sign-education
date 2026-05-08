/// Lesson data model (no database logic here).
class AssignmentModel {
  final String? assignmentId; // Unique ID for the lesson (UUID from Supabase)
  final String subject; // Subject of the lesson (Math, Physics, etc.)
  final String teacherId; // FK → users.id (teacher who created/imported lesson)
  final String classGroupId; // FK → class/group id (students assigned)
  final String? title; // Optional title
  final String? description; // Optional description
  final String? fileUrl; // Legacy (kept for backward compatibility)
  final Map<String, dynamic>? assignmentContentJson; // Dynamic questions payload
  final String status; // status completed or not
  final DateTime createdAt;
  final DateTime completeAt;

  final int? submissionsCount;

  AssignmentModel({
    this.assignmentId,
    required this.subject,
    required this.teacherId,
    required this.classGroupId,
    this.title,
    this.description,
    this.fileUrl,
    this.assignmentContentJson,
    required this.status,
    required this.createdAt,
    required this.completeAt,
    this.submissionsCount,
  });

  /// Create LessonModel from Supabase row.
  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      assignmentId: map['assignment_id'] as String,
      subject: map['subject'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      classGroupId: map['class_group_id'] ?? '',
      title: map['title'],
      description: map['description'],
      fileUrl: map['file_url'],
      assignmentContentJson: map['assignment_content_json'] is Map
          ? Map<String, dynamic>.from(map['assignment_content_json'])
          : null,
      status: map['status'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      completeAt: DateTime.tryParse(map['complete_at'] ?? '') ?? DateTime.now(),
      submissionsCount: map['submissions_count'],
    );
  }

  /// Convert LessonModel to Map for Supabase.
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'teacher_id': teacherId,
      'class_group_id': classGroupId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'assignment_content_json': assignmentContentJson,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'complete_at': completeAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory AssignmentModel.fromJson(Map<String, dynamic> json) =>
      AssignmentModel.fromMap(json);
}

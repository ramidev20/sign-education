/// Lesson data model (no database logic here).
class LessonModel {
  final String? lessonId; // Unique ID for the lesson (UUID from Supabase)
  final String subject; // Subject of the lesson (Math, Physics, etc.)
  final String strategyType; // Teaching strategy (video, pdf, quiz, etc.)
  final String teacherId; // FK → users.id (teacher who created/imported lesson)
  final String classGroupId; // FK → class/group id (students assigned)
  final String? title; // Optional title
  final String? description; // Optional description
  final String? fileUrl; // Optional storage file (e.g., Supabase storage path)
  final DateTime createdAt;

  LessonModel({
    this.lessonId,
    required this.subject,
    required this.strategyType,
    required this.teacherId,
    required this.classGroupId,
    this.title,
    this.description,
    this.fileUrl,
    required this.createdAt,
  });

  /// Create LessonModel from Supabase row.
  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      lessonId: map['lesson_id'] as String,
      subject: map['subject'] ?? '',
      strategyType: map['strategy_type'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      classGroupId: map['class_group_id'] ?? '',
      title: map['title'],
      description: map['description'],
      fileUrl: map['file_url'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert LessonModel to Map for Supabase.
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'strategy_type': strategyType,
      'teacher_id': teacherId,
      'class_group_id': classGroupId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      LessonModel.fromMap(json);
}

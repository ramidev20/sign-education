import 'dart:convert';

class ClassGroupModel {
  final String classGroupId; // e.g., "2CS_AI_Math"
  final String name;
  final String level;
  final String branch;
  final String subject;
  final String teacherId;
  final String avatarColor; // 🎨 store as hex string (e.g. "#2196F3")
  final DateTime createdAt;

  ClassGroupModel({
    required this.classGroupId,
    required this.name,
    required this.level,
    required this.branch,
    required this.subject,
    required this.teacherId,
    required this.avatarColor,
    required this.createdAt,
  });

  /// Convert Supabase map to model
  factory ClassGroupModel.fromMap(Map<String, dynamic> map) {
    return ClassGroupModel(
      classGroupId: map['class_group_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Group',
      level: map['level']?.toString() ?? '',
      branch: map['branch']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      avatarColor: map['avatar_color']?.toString() ?? '#2196F3', // fallback
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Convert model to map (for Supabase insert/update)
  Map<String, dynamic> toMap() {
    return {
      'class_group_id': classGroupId,
      'name': name,
      'level': level,
      'branch': branch,
      'subject': subject,
      'teacher_id': teacherId,
      'avatar_color': avatarColor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// JSON helpers (optional, useful if storing locally)
  factory ClassGroupModel.fromJson(String source) =>
      ClassGroupModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? level;
  final String? branch;
  final int points;
  final String? classGroup;
  final List<String>? subjects;
  final String? avatarColor;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.level,
    this.branch,
    this.points = 0,
    this.classGroup,
    this.subjects,
    this.avatarColor,
    required this.createdAt,
  });

  /// ✅ Safe conversion from Supabase row
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      level: map['level']?.toString(),
      branch: map['branch']?.toString(),
      points: (map['points'] as int?) ?? 0,
      classGroup: map['class_group']?.toString(),
      subjects: map['subjects'] != null
          ? List<String>.from(map['subjects'] as List)
          : null,
      avatarColor: map['image_url']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'level': role == 'student' ? level : null,
      'branch': role == 'student' ? branch : null,
      'points': role == 'student' ? points : null,
      'class_group': role == 'student' ? classGroup : null,
      'subjects': role == 'teacher' ? subjects : null,
      'avatar_color': avatarColor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);
}

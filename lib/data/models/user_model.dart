class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? level;
  final String? branch;
  final String? classGroup;
  final List<String>? subjects;
  final String? avatarColor;
  final String? phone;
  final String? bio;
  final String? schoolName;
  final String? specialization;
  final int? yearsExperience;
  final String? guardianName;
  final String? guardianPhone;
  final String? studentNumber;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.level,
    this.branch,
    this.classGroup,
    this.subjects,
    this.avatarColor,
    this.phone,
    this.bio,
    this.schoolName,
    this.specialization,
    this.yearsExperience,
    this.guardianName,
    this.guardianPhone,
    this.studentNumber,
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
      classGroup: map['class_group']?.toString(),
      subjects: map['subjects'] != null
          ? List<String>.from(map['subjects'] as List)
          : null,
      avatarColor: map['avatar_color']?.toString(),
      phone: map['phone']?.toString(),
      bio: map['bio']?.toString(),
      schoolName: map['school_name']?.toString(),
      specialization: map['specialization']?.toString(),
      yearsExperience: map['years_experience'] as int?,
      guardianName: map['guardian_name']?.toString(),
      guardianPhone: map['guardian_phone']?.toString(),
      studentNumber: map['student_number']?.toString(),
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
      'class_group': role == 'student' ? classGroup : null,
      'subjects': role == 'teacher' ? subjects : null,
      'avatar_color': avatarColor,
      'phone': phone,
      'bio': bio,
      'school_name': schoolName,
      'specialization': role == 'teacher' ? specialization : null,
      'years_experience': role == 'teacher' ? yearsExperience : null,
      'guardian_name': role == 'student' ? guardianName : null,
      'guardian_phone': role == 'student' ? guardianPhone : null,
      'student_number': role == 'student' ? studentNumber : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? level,
    String? branch,
    String? classGroup,
    List<String>? subjects,
    String? avatarColor,
    String? phone,
    String? bio,
    String? schoolName,
    String? specialization,
    int? yearsExperience,
    String? guardianName,
    String? guardianPhone,
    String? studentNumber,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      level: level ?? this.level,
      branch: branch ?? this.branch,
      classGroup: classGroup ?? this.classGroup,
      subjects: subjects ?? this.subjects,
      avatarColor: avatarColor ?? this.avatarColor,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      schoolName: schoolName ?? this.schoolName,
      specialization: specialization ?? this.specialization,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      studentNumber: studentNumber ?? this.studentNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

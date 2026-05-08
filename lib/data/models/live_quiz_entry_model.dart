class LiveQuizEntryModel {
  final String? entryId;
  final String quizId;
  final String studentId;
  final String studentName;
  final String entryText;
  final String entryType;
  final DateTime createdAt;

  LiveQuizEntryModel({
    this.entryId,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.entryText,
    this.entryType = 'text',
    required this.createdAt,
  });

  factory LiveQuizEntryModel.fromMap(Map<String, dynamic> map) {
    return LiveQuizEntryModel(
      entryId: map['entry_id']?.toString(),
      quizId: map['quiz_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      studentName: map['student_name']?.toString() ?? 'طالب',
      entryText: map['entry_text']?.toString() ?? '',
      entryType: map['entry_type']?.toString() ?? 'text',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (entryId != null) 'entry_id': entryId,
      'quiz_id': quizId,
      'student_id': studentId,
      'student_name': studentName,
      'entry_text': entryText,
      'entry_type': entryType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}


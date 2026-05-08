class LiveQuizModel {
  final String? quizId;
  final String teacherId;
  final String classGroupId;
  final String title;
  final String promptText;
  final String? visualPromptUrl;
  final String strategyKey;
  final String status;
  final DateTime createdAt;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int? timeLimitMinutes;

  LiveQuizModel({
    this.quizId,
    required this.teacherId,
    required this.classGroupId,
    required this.title,
    required this.promptText,
    this.visualPromptUrl,
    this.strategyKey = 'brainstorming_visual',
    this.status = 'active',
    required this.createdAt,
    required this.startsAt,
    this.endsAt,
    this.timeLimitMinutes,
  });

  factory LiveQuizModel.fromMap(Map<String, dynamic> map) {
    return LiveQuizModel(
      quizId: map['quiz_id']?.toString(),
      teacherId: map['teacher_id']?.toString() ?? '',
      classGroupId: map['class_group_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      promptText: map['prompt_text']?.toString() ?? '',
      visualPromptUrl: map['visual_prompt_url']?.toString(),
      strategyKey: map['strategy_key']?.toString() ?? 'brainstorming_visual',
      status: map['status']?.toString() ?? 'active',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      startsAt:
          DateTime.tryParse(map['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(map['ends_at']?.toString() ?? ''),
      timeLimitMinutes: map['time_limit_minutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (quizId != null) 'quiz_id': quizId,
      'teacher_id': teacherId,
      'class_group_id': classGroupId,
      'title': title,
      'prompt_text': promptText,
      'visual_prompt_url': visualPromptUrl,
      'strategy_key': strategyKey,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'time_limit_minutes': timeLimitMinutes,
    };
  }
}


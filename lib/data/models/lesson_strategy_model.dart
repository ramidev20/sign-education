class LessonStrategyModel {
  final String lessonStrategyId;
  final String lessonId;
  final String strategyType;
  final Map<String, dynamic> contentJson;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonStrategyModel({
    required this.lessonStrategyId,
    required this.lessonId,
    required this.strategyType,
    required this.contentJson,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonStrategyModel.fromMap(Map<String, dynamic> map) {
    return LessonStrategyModel(
      lessonStrategyId: map['lesson_strategy_id']?.toString() ?? '',
      lessonId: map['lesson_id']?.toString() ?? '',
      strategyType: map['strategy_type']?.toString() ?? '',
      contentJson: Map<String, dynamic>.from(map['content_json'] ?? const {}),
      title: map['title']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lesson_id': lessonId,
      'strategy_type': strategyType,
      'content_json': contentJson,
      'title': title,
    };
  }

  String get resultType {
    return 'cardboard';
  }
}

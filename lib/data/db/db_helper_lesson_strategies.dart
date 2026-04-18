import 'package:flutter/foundation.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbHelperLessonStrategies {
  static final supabase = Supabase.instance.client;

  static Future<List<LessonStrategyModel>> getStrategiesByLesson(
    String lessonId,
  ) async {
    try {
      final res = await supabase
          .from('lesson_strategies')
          .select(
            'lesson_strategy_id, lesson_id, strategy_type, content_json, title, created_at, updated_at',
          )
          .eq('lesson_id', lessonId)
          .order('created_at', ascending: true)
          .limit(200);

      final rows = (res as List)
          .map((m) => LessonStrategyModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      debugPrint(
        'DbHelperLessonStrategies.getStrategiesByLesson($lessonId): ${rows.length} rows',
      );
      return rows;
    } catch (e, st) {
      debugPrint(
        'DbHelperLessonStrategies.getStrategiesByLesson($lessonId) failed: $e\n$st',
      );
      rethrow;
    }
  }

  static Future<LessonStrategyModel> createStrategy({
    required String lessonId,
    required String strategyType,
    required Map<String, dynamic> contentJson,
    String? title,
  }) async {
    final res = await supabase
        .from('lesson_strategies')
        .insert({
          'lesson_id': lessonId,
          'strategy_type': strategyType,
          'content_json': contentJson,
          'title': title,
        })
        .select(
          'lesson_strategy_id, lesson_id, strategy_type, content_json, title, created_at, updated_at',
        )
        .single();

    return LessonStrategyModel.fromMap(Map<String, dynamic>.from(res));
  }

  static Future<LessonStrategyModel> updateStrategy({
    required String lessonStrategyId,
    required Map<String, dynamic> contentJson,
    String? title,
  }) async {
    final res = await supabase
        .from('lesson_strategies')
        .update({
          'content_json': contentJson,
          if (title != null) 'title': title,
        })
        .eq('lesson_strategy_id', lessonStrategyId)
        .select(
          'lesson_strategy_id, lesson_id, strategy_type, content_json, title, created_at, updated_at',
        )
        .single();

    return LessonStrategyModel.fromMap(Map<String, dynamic>.from(res));
  }

  static Future<void> deleteStrategy(String lessonStrategyId) async {
    try {
      await supabase
          .from('lesson_strategies')
          .delete()
          .eq('lesson_strategy_id', lessonStrategyId);
    } catch (e, st) {
      debugPrint('deleteStrategy failed: $e\n$st');
      rethrow;
    }
  }
}

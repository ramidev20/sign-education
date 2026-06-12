import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class OfflineStrategyCache {
  static Future<Directory> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/offline_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> strategiesFile(String lessonId) async {
    final base = await _baseDir();
    final safe = lessonId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${base.path}/lesson_${safe}_strategies.json');
  }

  static Map<String, dynamic> _strategyToJson(LessonStrategyModel s) {
    return {
      'lesson_strategy_id': s.lessonStrategyId,
      'lesson_id': s.lessonId,
      'strategy_type': s.strategyType,
      'content_json': s.contentJson,
      'title': s.title,
      'created_at': s.createdAt.toIso8601String(),
      'updated_at': s.updatedAt.toIso8601String(),
    };
  }

  static LessonStrategyModel _strategyFromJson(Map<String, dynamic> map) {
    return LessonStrategyModel.fromMap(map);
  }

  static Future<void> writeStrategies({
    required String lessonId,
    required List<LessonStrategyModel> strategies,
  }) async {
    if (kIsWeb) return;
    try {
      final file = await strategiesFile(lessonId);
      final payload = jsonEncode(
        strategies.map(_strategyToJson).toList(growable: false),
      );
      await file.writeAsString(payload, flush: true);
    } catch (e, st) {
      debugPrint('OfflineStrategyCache.writeStrategies failed: $e\n$st');
    }
  }

  static Future<List<LessonStrategyModel>> readStrategies(String lessonId) async {
    if (kIsWeb) return const [];
    try {
      final file = await strategiesFile(lessonId);
      if (!await file.exists()) return const [];
      final raw = await file.readAsString();
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => _strategyFromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (e, st) {
      debugPrint('OfflineStrategyCache.readStrategies failed: $e\n$st');
      return const [];
    }
  }

  static Future<void> clear(String lessonId) async {
    if (kIsWeb) return;
    try {
      final file = await strategiesFile(lessonId);
      if (await file.exists()) await file.delete();
    } catch (e, st) {
      debugPrint('OfflineStrategyCache.clear failed: $e\n$st');
    }
  }
}

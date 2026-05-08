import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineLessonCache {
  static const _savedLessonsKey = 'offline_saved_lessons_v1';

  static Future<bool> isLessonSaved(String lessonId) async {
    if (lessonId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedLessonsKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      return decoded.whereType<Map>().any((e) => e['lesson_id'] == lessonId);
    } catch (e, st) {
      debugPrint('OfflineLessonCache.isLessonSaved failed: $e\n$st');
      return false;
    }
  }

  static Future<void> removeSavedLesson(String lessonId) async {
    if (lessonId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedLessonsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final filtered = decoded
          .whereType<Map>()
          .where((e) => e['lesson_id']?.toString() != lessonId)
          .toList(growable: false);
      await prefs.setString(_savedLessonsKey, jsonEncode(filtered));
    } catch (e, st) {
      debugPrint('OfflineLessonCache.removeSavedLesson failed: $e\n$st');
    }
  }

  static Future<void> saveLessonMetadata(LessonModel lesson) async {
    final lessonId = lesson.lessonId;
    if (lessonId == null || lessonId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedLessonsKey);
      final List<dynamic> decoded = raw == null || raw.isEmpty
          ? <dynamic>[]
          : (jsonDecode(raw) as List<dynamic>);

      final entries = decoded
          .whereType<Map>()
          .map((e) => e.map((key, value) => MapEntry('$key', value)))
          .toList();

      final map = <String, dynamic>{
        'lesson_id': lessonId,
        'subject': lesson.subject,
        'strategy_type': lesson.strategyType,
        'teacher_id': lesson.teacherId,
        'class_group_id': lesson.classGroupId,
        'title': lesson.title,
        'description': lesson.description,
        'created_at': lesson.createdAt.toIso8601String(),
      };

      final index = entries.indexWhere((e) => e['lesson_id'] == lessonId);
      if (index >= 0) {
        entries[index] = map;
      } else {
        entries.add(map);
      }

      await prefs.setString(_savedLessonsKey, jsonEncode(entries));
    } catch (e, st) {
      debugPrint('OfflineLessonCache.saveLessonMetadata failed: $e\n$st');
    }
  }

  static Future<List<LessonModel>> getSavedLessonsByTeacher(
    String teacherId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedLessonsKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final lessons = <LessonModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry('$key', value));
        if ((map['teacher_id'] ?? '') != teacherId) continue;
        final lessonId = map['lesson_id'];
        if (lessonId is! String || lessonId.trim().isEmpty) continue;
        lessons.add(LessonModel.fromMap(map));
      }

      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return lessons;
    } catch (e, st) {
      debugPrint('OfflineLessonCache.getSavedLessonsByTeacher failed: $e\n$st');
      return [];
    }
  }

  static Future<List<LessonModel>> getSavedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedLessonsKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final lessons = <LessonModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry('$key', value));
        final lessonId = map['lesson_id'];
        if (lessonId is! String || lessonId.trim().isEmpty) continue;
        lessons.add(LessonModel.fromMap(map));
      }

      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return lessons;
    } catch (e, st) {
      debugPrint('OfflineLessonCache.getSavedLessons failed: $e\n$st');
      return [];
    }
  }
}

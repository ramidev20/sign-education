import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sign_education/data/models/lesson_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineLessonCache {
  static const _pdfPathPrefix = 'offline_lesson_pdf_path_';
  static const _savedLessonsKey = 'offline_saved_lessons_v1';

  static Future<Directory> _pdfDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/offline_cache/lesson_pdfs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File?> getCachedLessonPdfFile(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('$_pdfPathPrefix$lessonId');
      if (path == null || path.isEmpty) return null;
      final file = File(path);
      if (await file.exists()) return file;
      return null;
    } catch (e, st) {
      debugPrint('OfflineLessonCache.getCachedLessonPdfFile failed: $e\n$st');
      return null;
    }
  }

  static Future<File?> cacheLessonPdf({
    required String lessonId,
    required String fileUrl,
  }) async {
    try {
      final uri = Uri.tryParse(fileUrl);
      if (uri == null) return null;

      final client = HttpClient();
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return null;
      }

      final dir = await _pdfDir();
      final safeLessonId = lessonId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/lesson_$safeLessonId.pdf');
      final bytes = await consolidateHttpClientResponseBytes(res);
      await file.writeAsBytes(bytes, flush: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_pdfPathPrefix$lessonId', file.path);
      return file;
    } catch (e, st) {
      debugPrint('OfflineLessonCache.cacheLessonPdf failed: $e\n$st');
      return null;
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
        'file_url': lesson.fileUrl,
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
}

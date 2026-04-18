import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';

class InteractiveHierarchyView extends StatelessWidget {
  final Map<String, dynamic> hierarchyJson;
  final UserModel user;

  const InteractiveHierarchyView({
    super.key,
    required this.hierarchyJson,
    required this.user,
  });

  List<_HierarchyLevel> _normalizeLevels() {
    final result = <_HierarchyLevel>[];
    final raw = hierarchyJson['hierarchyMap'];

    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final item = raw[i];
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final level = (map['level'] is num) ? (map['level'] as num).toInt() : i + 1;
        final title = (map['title'] ?? map['content'] ?? '').toString().trim();
        final description = (map['description'] ?? '').toString().trim();
        if (title.isEmpty && description.isEmpty) continue;
        result.add(
          _HierarchyLevel(
            level: max(1, level),
            title: title.isEmpty ? 'المستوى ${i + 1}' : title,
            description: description,
          ),
        );
      }
    }

    if (result.isEmpty) {
      final rootTitle = (hierarchyJson['title'] ?? hierarchyJson['content'] ?? '')
          .toString()
          .trim();
      if (rootTitle.isNotEmpty) {
        result.add(
          _HierarchyLevel(
            level: 1,
            title: rootTitle,
            description: '',
          ),
        );
      }
    }

    result.sort((a, b) => a.level.compareTo(b.level));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final levels = _normalizeLevels();
    final title = (hierarchyJson['title'] ?? hierarchyJson['content'] ?? 'التدرج الهرمي')
        .toString();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: levels.isEmpty
            ? Center(
                child: Text(
                  'لا توجد بيانات لعرض التدرج الهرمي.',
                  style: theme.textTheme.titleMedium,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = max(320.0, constraints.maxWidth - 16);
                  final height = max(560.0, levels.length * 136.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
                    child: Center(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: CustomPaint(
                          painter: _PyramidPainter(
                            levels: levels,
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PyramidPainter extends CustomPainter {
  final List<_HierarchyLevel> levels;
  final TextDirection textDirection;
  final TextTheme style;

  _PyramidPainter({
    required this.levels,
    required this.textDirection,
    required this.style,
  });

  static const _palette = [
    Color(0xFF5EC3F0),
    Color(0xFF94DA6C),
    Color(0xFFF2E293),
    Color(0xFFF4B07B),
    Color(0xFFF08D8D),
    Color(0xFFBDA2F3),
    Color(0xFF9ED2C6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bandCount = levels.length;
    if (bandCount == 0) return;

    final baseY = size.height - 20;
    final topY = 20.0;
    final totalHeight = max(1.0, baseY - topY);
    final bandHeight = totalHeight / bandCount;

    final topWidth = max(120.0, size.width * 0.30);
    final bottomWidth = size.width * 0.94;
    final centerX = size.width / 2;

    final topFirst = levels.reversed.toList();

    for (var i = 0; i < bandCount; i++) {
      final item = topFirst[i];
      final topBoundary = i / bandCount;
      final bottomBoundary = (i + 1) / bandCount;

      final topBandWidth = ui.lerpDouble(topWidth, bottomWidth, topBoundary)!;
      final bottomBandWidth = ui.lerpDouble(topWidth, bottomWidth, bottomBoundary)!;
      final yTop = topY + (i * bandHeight);
      final yBottom = yTop + bandHeight;

      final path = Path()
        ..moveTo(centerX - (topBandWidth / 2), yTop)
        ..lineTo(centerX + (topBandWidth / 2), yTop)
        ..lineTo(centerX + (bottomBandWidth / 2), yBottom)
        ..lineTo(centerX - (bottomBandWidth / 2), yBottom)
        ..close();

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = _palette[i % _palette.length];
      canvas.drawPath(path, fill);

      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0x55FFFFFF);
      canvas.drawPath(path, border);

      _drawBandText(
        canvas,
        Rect.fromLTRB(
          centerX - (bottomBandWidth / 2) + 10,
          yTop + 8,
          centerX + (bottomBandWidth / 2) - 10,
          yBottom - 8,
        ),
        item,
      );
    }
  }

  void _drawBandText(Canvas canvas, Rect rect, _HierarchyLevel item) {
    final hasDesc = item.description.trim().isNotEmpty;
    var titleSize = 22.0;
    var descSize = 13.5;

    TextPainter buildPainter({
      required String text,
      required double fontSize,
      required FontWeight weight,
      required Color color,
      required int maxLines,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: weight,
            color: color,
            height: 1.18,
          ),
        ),
        textDirection: textDirection,
        textAlign: TextAlign.center,
        maxLines: maxLines,
      )..layout(maxWidth: rect.width);
      return painter;
    }

    late TextPainter levelPainter;
    late TextPainter titlePainter;
    late TextPainter descPainter;

    for (var i = 0; i < 12; i++) {
      levelPainter = buildPainter(
        text: 'المستوى ${item.level}',
        fontSize: max(9, titleSize * 0.55),
        weight: FontWeight.w700,
        color: const Color(0xFF4C1D95),
        maxLines: 1,
      );
      titlePainter = buildPainter(
        text: item.title,
        fontSize: titleSize,
        weight: FontWeight.w800,
        color: const Color(0xFF111827),
        maxLines: hasDesc ? 2 : 3,
      );
      descPainter = buildPainter(
        text: item.description,
        fontSize: descSize,
        weight: FontWeight.w600,
        color: const Color(0xCC111827),
        maxLines: hasDesc ? 4 : 1,
      );

      final total = levelPainter.height +
          2 +
          titlePainter.height +
          (hasDesc ? (4 + descPainter.height) : 0);
      if (total <= rect.height - 6) break;
      titleSize = max(12, titleSize - 1.2);
      descSize = max(9, descSize - 0.9);
    }

    final totalHeight = levelPainter.height +
        2 +
        titlePainter.height +
        (hasDesc ? (4 + descPainter.height) : 0);
    var dy = rect.center.dy - (totalHeight / 2);

    levelPainter.paint(canvas, Offset(rect.center.dx - (levelPainter.width / 2), dy));
    dy += levelPainter.height + 2;
    titlePainter.paint(canvas, Offset(rect.center.dx - (titlePainter.width / 2), dy));
    dy += titlePainter.height + 4;
    if (hasDesc) {
      descPainter.paint(canvas, Offset(rect.center.dx - (descPainter.width / 2), dy));
    }
  }

  @override
  bool shouldRepaint(covariant _PyramidPainter oldDelegate) {
    return oldDelegate.levels != levels || oldDelegate.textDirection != textDirection;
  }
}

class _HierarchyLevel {
  final int level;
  final String title;
  final String description;

  _HierarchyLevel({
    required this.level,
    required this.title,
    required this.description,
  });
}

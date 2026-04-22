import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';

class InteractiveTriangleView extends StatefulWidget {
  final Map<String, dynamic> triangleJson;
  final UserModel user;

  const InteractiveTriangleView({
    super.key,
    required this.triangleJson,
    required this.user,
  });

  @override
  State<InteractiveTriangleView> createState() => _InteractiveTriangleViewState();
}

class _InteractiveTriangleViewState extends State<InteractiveTriangleView> {
  static const _sceneSize = Size(980, 760);
  final _transform = TransformationController();
  final _viewerKey = GlobalKey();
  bool _didInitTransform = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaultZoomOut());
  }

  void _initDefaultZoomOut() {
    if (!mounted || _didInitTransform) return;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport = viewerBox?.size;
    if (viewport == null || viewport.width <= 0 || viewport.height <= 0) return;

    final fittedScale = min(
      viewport.width / _sceneSize.width,
      viewport.height / _sceneSize.height,
    );
    final scale = min(1.0, max(0.78, fittedScale * 0.94));
    final tx = (viewport.width / 2) - ((_sceneSize.width / 2) * scale);
    final ty = (viewport.height / 2) - ((_sceneSize.height / 2) * scale);

    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
    _didInitTransform = true;
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.triangleJson['title'] ?? 'المثلث التعليمي').toString();
    final description = (widget.triangleJson['description'] ?? '').toString();
    final corners = _normalizeCorners(widget.triangleJson);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            Expanded(
              child: InteractiveViewer(
                key: _viewerKey,
                transformationController: _transform,
                minScale: 0.6,
                maxScale: 2.4,
                panEnabled: true,
                scaleEnabled: true,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(800),
                child: SizedBox(
                  width: _sceneSize.width,
                  height: _sceneSize.height,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 120,
                            vertical: 85,
                          ),
                          child: CustomPaint(
                            painter: _TriangleLinePainter(),
                          ),
                        ),
                      ),
                      _CornerCard(
                        alignment: const Alignment(0, -0.92),
                        data: corners[0],
                        width: 300,
                        color: corners[0].color,
                      ),
                      _CornerCard(
                        alignment: const Alignment(-0.90, 0.88),
                        data: corners[1],
                        width: 295,
                        color: corners[1].color,
                      ),
                      _CornerCard(
                        alignment: const Alignment(0.90, 0.88),
                        data: corners[2],
                        width: 295,
                        color: corners[2].color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Text(
                'يمكنك السحب والتكبير. تم ترك مسافة واضحة بين البطاقات وخطوط المثلث.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TriangleCorner> _normalizeCorners(Map<String, dynamic> data) {
    final raw = (data['triangleMap'] as List? ?? const []).toList();
    while (raw.length < 3) {
      raw.add({
        'corner': 'زاوية',
        'title': '',
        'description': '',
        'examples': <dynamic>[],
        'color': '#3b82f6',
      });
    }

    return raw.take(3).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final title = (map['title']?.toString().trim().isNotEmpty ?? false)
          ? map['title'].toString()
          : (map['corner']?.toString() ?? 'زاوية');
      final description = (map['description'] ?? '').toString();
      final examples = (map['examples'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final color = _parseHexColor(map['color']?.toString() ?? '#3b82f6');
      return _TriangleCorner(
        title: title,
        description: description,
        examples: examples,
        color: color,
      );
    }).toList();
  }

  Color _parseHexColor(String input) {
    var hex = input.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse('0x$hex'));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }
}

class _TriangleLinePainter extends CustomPainter {
  const _TriangleLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final top = Offset(size.width / 2, 70);
    final left = Offset(130, size.height - 95);
    final right = Offset(size.width - 130, size.height - 95);

    canvas.drawLine(top, left, paint);
    canvas.drawLine(top, right, paint);
    canvas.drawLine(left, right, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleLinePainter oldDelegate) => false;
}

class _CornerCard extends StatelessWidget {
  final Alignment alignment;
  final _TriangleCorner data;
  final double width;
  final Color color;

  const _CornerCard({
    required this.alignment,
    required this.data,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 9,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (data.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onColor.withOpacity(0.95),
                  height: 1.35,
                ),
              ),
            ],
            if (data.examples.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (var i = 0; i < min(4, data.examples.length); i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${data.examples[i]}',
                    style: TextStyle(
                      color: onColor.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TriangleCorner {
  final String title;
  final String description;
  final List<String> examples;
  final Color color;

  const _TriangleCorner({
    required this.title,
    required this.description,
    required this.examples,
    required this.color,
  });
}


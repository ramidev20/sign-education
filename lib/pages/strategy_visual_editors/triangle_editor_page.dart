import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class TriangleEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const TriangleEditorPage({super.key, required this.strategy});

  @override
  State<TriangleEditorPage> createState() => _TriangleEditorPageState();
}

class _TriangleEditorPageState extends State<TriangleEditorPage> {
  bool _saving = false;
  late String _title;
  late String _description;
  late List<Map<String, dynamic>> _triangleMap;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _title = (json['title']?.toString().trim().isNotEmpty ?? false)
        ? json['title'].toString()
        : 'المثلث التعليمي';
    _description = json['description']?.toString() ?? '';
    _triangleMap = (json['triangleMap'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    while (_triangleMap.length < 3) {
      _triangleMap.add({
        'corner': 'زاوية',
        'title': '',
        'description': '',
        'examples': <dynamic>[],
        'color': '#3b82f6',
      });
    }
    if (_triangleMap.length > 3) {
      _triangleMap = _triangleMap.take(3).toList();
    }
  }

  Future<void> _editCorner(int index) async {
    final c = _triangleMap[index];
    final corner = TextEditingController(text: c['corner']?.toString() ?? '');
    final title = TextEditingController(text: c['title']?.toString() ?? '');
    final desc =
        TextEditingController(text: c['description']?.toString() ?? '');
    final color =
        TextEditingController(text: c['color']?.toString() ?? '#3b82f6');
    final examples = TextEditingController(
      text: (c['examples'] as List? ?? const [])
          .map((e) => e.toString())
          .join('\n'),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل الزاوية ${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: corner,
                decoration: const InputDecoration(
                  labelText: 'اسم الزاوية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: color,
                decoration: const InputDecoration(
                  labelText: 'اللون (HEX)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: desc,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: examples,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'أمثلة (كل سطر مثال)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() {
      c['corner'] = corner.text.trim();
      c['title'] = title.text.trim();
      c['description'] = desc.text.trim();
      c['color'] = color.text.trim().isEmpty ? '#3b82f6' : color.text.trim();
      c['examples'] = examples.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'title': _title,
          'description': _description,
          'triangleMap': _triangleMap,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محرّر المثلث التعليمي'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'حفظ',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: TextEditingController(text: _title),
                onChanged: (v) => _title = v,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: _description),
                onChanged: (v) => _description = v,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.1,
                child: CustomPaint(
                  painter: _TrianglePainter(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.55),
                  ),
                  child: Stack(
                    children: [
                      _CornerTile(
                        alignment: Alignment.topCenter,
                        title: _triangleMap[0]['corner']?.toString() ?? 'زاوية',
                        onTap: () => _editCorner(0),
                      ),
                      _CornerTile(
                        alignment: Alignment.bottomLeft,
                        title: _triangleMap[1]['corner']?.toString() ?? 'زاوية',
                        onTap: () => _editCorner(1),
                      ),
                      _CornerTile(
                        alignment: Alignment.bottomRight,
                        title: _triangleMap[2]['corner']?.toString() ?? 'زاوية',
                        onTap: () => _editCorner(2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'اضغط على أي زاوية لتعديلها.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerTile extends StatelessWidget {
  final Alignment alignment;
  final String title;
  final VoidCallback onTap;

  const _CornerTile({
    required this.alignment,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final top = Offset(size.width / 2, 22);
    final left = Offset(22, size.height - 22);
    final right = Offset(size.width - 22, size.height - 22);

    canvas.drawLine(top, left, p);
    canvas.drawLine(top, right, p);
    canvas.drawLine(left, right, p);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}


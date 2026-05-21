import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/app_theme.dart';

class TriangleEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const TriangleEditorPage({super.key, required this.strategy});

  @override
  State<TriangleEditorPage> createState() => _TriangleEditorPageState();
}

class _TriangleEditorPageState extends State<TriangleEditorPage> {
  bool _saving = false;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late List<Map<String, dynamic>> _triangleMap;

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _titleController = TextEditingController(
      text: (json['title']?.toString().trim().isNotEmpty ?? false)
          ? json['title'].toString()
          : 'المثلث التعليمي',
    );
    _descriptionController = TextEditingController(
      text: json['description']?.toString() ?? '',
    );
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      var clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse('0x$clean'));
    } catch (_) {
      return AppTheme.brand;
    }
  }

  String _toHex(Color color) {
    final v = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${v.substring(2)}';
  }

  Future<void> _editCorner(int index) async {
    final strings = AppStrings.read(context);
    final c = _triangleMap[index];
    final corner = TextEditingController(text: c['corner']?.toString() ?? '');
    final title = TextEditingController(text: c['title']?.toString() ?? '');
    final desc =
        TextEditingController(text: c['description']?.toString() ?? '');

    var picked = _parseColor(c['color']?.toString() ?? '#3b82f6');

    final examples = (c['examples'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final media = MediaQuery.of(context);
        return SafeArea(
          child: SizedBox(
            height: media.size.height * (2 / 3),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + media.viewInsets.bottom,
              ),
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تعديل الزاوية ${index + 1}',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: corner,
                          decoration: InputDecoration(
                            labelText: strings.tr('strategy_visual.triangle.angle_name'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: title,
                          decoration: InputDecoration(
                            labelText: strings.tr('strategy_visual.title'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: desc,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: strings.tr('strategy_visual.description'),
                            alignLabelWithHint: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'لون البطاقة',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 10),
                                ColorPicker(
                                  color: picked,
                                  onColorChanged: (c) =>
                                      setLocal(() => picked = c),
                                  pickersEnabled:
                                      const <ColorPickerType, bool>{
                                    ColorPickerType.primary: true,
                                    ColorPickerType.accent: false,
                                    ColorPickerType.both: false,
                                    ColorPickerType.custom: false,
                                    ColorPickerType.wheel: false,
                                  },
                                  enableShadesSelection: true,
                                  showColorName: false,
                                  showColorCode: true,
                                  colorCodeHasColor: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'أمثلة',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: strings.tr('strategy_visual.triangle.add_example'),
                                      onPressed: () async {
                                        final controller =
                                            TextEditingController();
                                        final v = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              strings.tr(
                                                'strategy_visual.triangle.add_example_title',
                                              ),
                                            ),
                                            content: TextField(
                                              controller: controller,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  strings.tr('strategy_visual.cancel'),
                                                ),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  controller.text.trim(),
                                                ),
                                                child: Text(
                                                  strings.tr('strategy_visual.add'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (v == null || v.trim().isEmpty) {
                                          return;
                                        }
                                        setLocal(() => examples.add(v.trim()));
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (examples.isEmpty)
                                  Text(
                                    strings.tr('strategy_visual.triangle.no_examples_yet'),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final e in examples)
                                        InputChip(
                                          label: Text(e),
                                          onDeleted: () => setLocal(
                                            () => examples.remove(e),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('حفظ'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (ok != true) return;
    setState(() {
      c['corner'] = corner.text.trim();
      c['title'] = title.text.trim();
      c['description'] = desc.text.trim();
      c['color'] = _toHex(picked);
      c['examples'] = examples;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'triangleMap': _triangleMap,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.read(context).tr('strategy_visual.error')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);

    final c0 = _parseColor(_triangleMap[0]['color']?.toString() ?? '#3b82f6');
    final c1 = _parseColor(_triangleMap[1]['color']?.toString() ?? '#3b82f6');
    final c2 = _parseColor(_triangleMap[2]['color']?.toString() ?? '#3b82f6');

    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.tr('strategy_visual.triangle.title')),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: strings.tr('strategy_visual.save'),
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
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: strings.tr('strategy_visual.triangle.optional_description'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.1,
                child: CustomPaint(
                  painter: _TrianglePainter(
                    topLeft: Color.lerp(c0, c1, 0.5) ?? cs.primary,
                    topRight: Color.lerp(c0, c2, 0.5) ?? cs.primary,
                    bottom: Color.lerp(c1, c2, 0.5) ?? cs.primary,
                  ),
                  child: Stack(
                    children: [
                      _CornerTile(
                        alignment: Alignment.topCenter,
                        title: _triangleMap[0]['corner']?.toString() ?? 'زاوية',
                        color: c0,
                        onTap: () => _editCorner(0),
                      ),
                      _CornerTile(
                        alignment: Alignment.bottomLeft,
                        title: _triangleMap[1]['corner']?.toString() ?? 'زاوية',
                        color: c1,
                        onTap: () => _editCorner(1),
                      ),
                      _CornerTile(
                        alignment: Alignment.bottomRight,
                        title: _triangleMap[2]['corner']?.toString() ?? 'زاوية',
                        color: c2,
                        onTap: () => _editCorner(2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.tr('strategy_visual.triangle.help'),
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
  final Color color;
  final VoidCallback onTap;

  const _CornerTile({
    required this.alignment,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 190,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
  final Color topLeft;
  final Color topRight;
  final Color bottom;

  _TrianglePainter({
    required this.topLeft,
    required this.topRight,
    required this.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final top = Offset(size.width / 2, 22);
    final left = Offset(22, size.height - 22);
    final right = Offset(size.width - 22, size.height - 22);

    final p1 = Paint()
      ..color = topLeft.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final p2 = Paint()
      ..color = topRight.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final p3 = Paint()
      ..color = bottom.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawLine(top, left, p1);
    canvas.drawLine(top, right, p2);
    canvas.drawLine(left, right, p3);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.topLeft != topLeft ||
      oldDelegate.topRight != topRight ||
      oldDelegate.bottom != bottom;
}

import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';

class SixHatEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;
  const SixHatEditorPage({super.key, required this.strategy});

  @override
  State<SixHatEditorPage> createState() => _SixHatEditorPageState();
}

class _SixHatEditorPageState extends State<SixHatEditorPage> {
  bool _saving = false;
  late Map<String, TextEditingController> _controllers;

  static const _hats = <_HatDef>[
    _HatDef(keyName: 'white_hat', label: 'القبعة البيضاء', color: Colors.white),
    _HatDef(keyName: 'red_hat', label: 'القبعة الحمراء', color: Colors.red),
    _HatDef(keyName: 'black_hat', label: 'القبعة السوداء', color: Colors.black),
    _HatDef(
      keyName: 'yellow_hat',
      label: 'القبعة الصفراء',
      color: Colors.yellow,
    ),
    _HatDef(keyName: 'green_hat', label: 'القبعة الخضراء', color: Colors.green),
    _HatDef(keyName: 'blue_hat', label: 'القبعة الزرقاء', color: Colors.blue),
  ];

  @override
  void initState() {
    super.initState();
    final json = widget.strategy.contentJson;
    _controllers = {
      for (final hat in _hats)
        hat.keyName: TextEditingController(text: json[hat.keyName]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        for (final hat in _hats) hat.keyName: _controllers[hat.keyName]!.text.trim(),
      };
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: payload,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محرّر القبعات الست'),
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
        body: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _hats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final hat = _hats[index];
            final isDark = ThemeData.estimateBrightnessForColor(hat.color) ==
                Brightness.dark;
            final fg = isDark ? Colors.white : Colors.black;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: hat.color,
                          radius: 16,
                          child: Icon(Icons.lightbulb, color: fg, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hat.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controllers[hat.keyName],
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'اكتب محتوى ${hat.label}',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HatDef {
  final String keyName;
  final String label;
  final Color color;
  const _HatDef({
    required this.keyName,
    required this.label,
    required this.color,
  });
}


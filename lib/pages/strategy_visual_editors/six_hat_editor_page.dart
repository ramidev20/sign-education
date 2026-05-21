import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/utils/app_strings.dart';

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
    _HatDef(keyName: 'white_hat', labelKey: 'strategy_visual.six_hat.white', color: Colors.white),
    _HatDef(keyName: 'red_hat', labelKey: 'strategy_visual.six_hat.red', color: Colors.red),
    _HatDef(keyName: 'black_hat', labelKey: 'strategy_visual.six_hat.black', color: Colors.black),
    _HatDef(
      keyName: 'yellow_hat',
      labelKey: 'strategy_visual.six_hat.yellow',
      color: Colors.yellow,
    ),
    _HatDef(keyName: 'green_hat', labelKey: 'strategy_visual.six_hat.green', color: Colors.green),
    _HatDef(keyName: 'blue_hat', labelKey: 'strategy_visual.six_hat.blue', color: Colors.blue),
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
    final strings = AppStrings.read(context);
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
        SnackBar(content: Text('${strings.tr('strategy_visual.error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final strings = AppStrings.of(context);
    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.tr('strategy_visual.six_hat.title')),
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
        body: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _hats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final hat = _hats[index];
            final label = strings.tr(hat.labelKey);
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
                            label,
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
                        hintText: strings
                            .tr('strategy_visual.six_hat.hint')
                            .replaceAll('{hat}', label),
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
  final String labelKey;
  final Color color;
  const _HatDef({
    required this.keyName,
    required this.labelKey,
    required this.color,
  });
}

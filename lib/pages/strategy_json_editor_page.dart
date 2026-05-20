import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_lesson_strategies.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/pages/lesson_strategy_viewer.dart';
import 'package:sign_education/utils/app_strings.dart';

class StrategyJsonEditorPage extends StatefulWidget {
  final LessonStrategyModel strategy;

  const StrategyJsonEditorPage({super.key, required this.strategy});

  @override
  State<StrategyJsonEditorPage> createState() => _StrategyJsonEditorPageState();
}

class _StrategyJsonEditorPageState extends State<StrategyJsonEditorPage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.strategy.contentJson),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _hint(AppStrings strings) {
    final key = switch (widget.strategy.strategyType) {
      'type_0' => 'strategy_json.hint.type_0',
      'type_5' => 'strategy_json.hint.type_5',
      'type_6' => 'strategy_json.hint.type_6',
      'type_9' => 'strategy_json.hint.type_9',
      'type_10' => 'strategy_json.hint.type_10',
      'type_11' => 'strategy_json.hint.type_11',
      'type_13' => 'strategy_json.hint.type_13',
      'type_14' => 'strategy_json.hint.type_14',
      _ => 'strategy_json.hint.default',
    };
    return strings.tr(key);
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_controller.text);
      _controller.text = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      // ignore; user will see validation on save
    }
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('strategy_json.invalid_json')}: $e')),
      );
      return;
    }

    if (decoded is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tr('strategy_json.must_be_object'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await DbHelperLessonStrategies.updateStrategy(
        lessonStrategyId: widget.strategy.lessonStrategyId,
        contentJson: Map<String, dynamic>.from(decoded),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.tr('app.error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final title = (widget.strategy.title?.trim().isNotEmpty ?? false)
        ? widget.strategy.title!.trim()
        : strategyLabelForType(context, widget.strategy.strategyType);

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.tr('strategy_json.title')}: $title'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: strings.tr('strategy_json.format'),
            onPressed: _saving ? null : _formatJson,
            icon: const Icon(Icons.format_align_left_rounded),
          ),
          IconButton(
            tooltip: strings.tr('app.save'),
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _hint(strings),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Strategy JSON',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


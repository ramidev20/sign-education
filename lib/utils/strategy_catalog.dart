import 'package:flutter/material.dart';

class StrategyDefinition {
  final String id;
  final String label;
  final IconData icon;

  const StrategyDefinition({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class StrategyCatalog {
  static const mindMap = StrategyDefinition(
    id: 'type_0',
    label: 'الخرائط الذهنية',
    icon: Icons.account_tree_rounded,
  );
  static const timeline = StrategyDefinition(
    id: 'type_5',
    label: 'المخطط الزمني',
    icon: Icons.timeline_rounded,
  );
  static const hierarchy = StrategyDefinition(
    id: 'type_6',
    label: 'التدرج الهرمي',
    icon: Icons.device_hub_rounded,
  );
  static const coloredCards = StrategyDefinition(
    id: 'type_9',
    label: 'البطاقات الملونة',
    icon: Icons.crop_landscape_outlined,
  );
  static const comparisonTable = StrategyDefinition(
    id: 'type_10',
    label: 'جدول المقارنة',
    icon: Icons.table_chart_rounded,
  );
  static const triangle = StrategyDefinition(
    id: 'type_11',
    label: 'المثلث التعليمي',
    icon: Icons.change_history_rounded,
  );
  static const sixHats = StrategyDefinition(
    id: 'type_12',
    label: 'القبعات الست',
    icon: Icons.psychology_alt_rounded,
  );
  static const journalisticQuestions = StrategyDefinition(
    id: 'type_13',
    label: 'أسئلة صحفية',
    icon: Icons.quiz_outlined,
  );
  static const educationalStory = StrategyDefinition(
    id: 'type_14',
    label: 'قصة تعليمية',
    icon: Icons.auto_stories_rounded,
  );

  static const all = <StrategyDefinition>[
    mindMap,
    timeline,
    hierarchy,
    coloredCards,
    comparisonTable,
    triangle,
    sixHats,
    journalisticQuestions,
    educationalStory,
  ];

  static StrategyDefinition? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static String labelForType(String type) => byId(type)?.label ?? type;

  static IconData iconForType(String type) =>
      byId(type)?.icon ?? Icons.auto_awesome_rounded;
}


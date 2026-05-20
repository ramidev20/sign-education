import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_strings.dart';

class StrategyDefinition {
  final String id;
  final String labelKey;
  final IconData icon;

  const StrategyDefinition({
    required this.id,
    required this.labelKey,
    required this.icon,
  });

  String label(AppStrings strings) => strings.tr(labelKey);
}

class StrategyCatalog {
  static const mindMap = StrategyDefinition(
    id: 'type_0',
    labelKey: 'strategy.mind_map',
    icon: Icons.account_tree_rounded,
  );
  static const timeline = StrategyDefinition(
    id: 'type_5',
    labelKey: 'strategy.timeline',
    icon: Icons.timeline_rounded,
  );
  static const hierarchy = StrategyDefinition(
    id: 'type_6',
    labelKey: 'strategy.hierarchy',
    icon: Icons.device_hub_rounded,
  );
  static const coloredCards = StrategyDefinition(
    id: 'type_9',
    labelKey: 'strategy.colored_cards',
    icon: Icons.crop_landscape_outlined,
  );
  static const comparisonTable = StrategyDefinition(
    id: 'type_10',
    labelKey: 'strategy.comparison_table',
    icon: Icons.table_chart_rounded,
  );
  static const triangle = StrategyDefinition(
    id: 'type_11',
    labelKey: 'strategy.triangle',
    icon: Icons.change_history_rounded,
  );
  static const sixHats = StrategyDefinition(
    id: 'type_12',
    labelKey: 'strategy.six_hats',
    icon: Icons.psychology_alt_rounded,
  );
  static const journalisticQuestions = StrategyDefinition(
    id: 'type_13',
    labelKey: 'strategy.journalistic_questions',
    icon: Icons.quiz_outlined,
  );
  static const educationalStory = StrategyDefinition(
    id: 'type_14',
    labelKey: 'strategy.educational_story',
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

  static String labelForType(String type, AppStrings strings) =>
      byId(type)?.label(strings) ?? type;

  static IconData iconForType(String type) =>
      byId(type)?.icon ?? Icons.auto_awesome_rounded;
}


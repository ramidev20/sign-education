import 'package:flutter/material.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/strategy_pages/interactive_colored_cards_view.dart';
import 'package:sign_education/strategy_pages/interactive_comparison_view.dart';
import 'package:sign_education/strategy_pages/interactive_hierarchy_view.dart';
import 'package:sign_education/strategy_pages/interactive_mindmap_view.dart';
import 'package:sign_education/strategy_pages/interactive_timeline_view.dart';
import 'package:sign_education/strategy_pages/interactive_triangle_view.dart';

String strategyLabelForType(String type) {
  switch (type) {
    case 'type_0':
      return 'الخرائط الذهنية';
    case 'type_5':
      return 'المخطط الزمني';
    case 'type_6':
      return 'التدرج الهرمي';
    case 'type_9':
      return 'البطاقات الملونة';
    case 'type_10':
      return 'جدول المقارنة';
    case 'type_11':
      return 'المثلث التعليمي';
    default:
      return type;
  }
}

IconData strategyIconForType(String type) {
  switch (type) {
    case 'type_0':
      return Icons.account_tree_rounded;
    case 'type_5':
      return Icons.timeline_rounded;
    case 'type_6':
      return Icons.device_hub_rounded;
    case 'type_9':
      return Icons.crop_landscape_outlined;
    case 'type_10':
      return Icons.table_chart_rounded;
    case 'type_11':
      return Icons.change_history_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

void openLessonStrategy(
  BuildContext context,
  UserModel user,
  LessonStrategyModel strategy,
) {
  final json = strategy.contentJson;

  switch (strategy.strategyType) {
    case 'type_0':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractiveMindMapView(
            username: user.name,
            mindMapJson: json,
          ),
        ),
      );
      return;
    case 'type_5':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TimeLineMapView(user: user, mindMapJson: json),
        ),
      );
      return;
    case 'type_6':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractiveHierarchyView(user: user, hierarchyJson: json),
        ),
      );
      return;
    case 'type_9':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractiveColoredCardsView(user: user, cardsJson: json),
        ),
      );
      return;
    case 'type_10':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractiveComparisonView(
            username: user.name,
            comparisonJson: json,
          ),
        ),
      );
      return;
    case 'type_11':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractiveTriangleView(user: user, triangleJson: json),
        ),
      );
      return;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('هذه الاستراتيجية غير مدعومة: ${strategy.strategyType}')),
      );
  }
}

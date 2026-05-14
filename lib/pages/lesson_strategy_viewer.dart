import 'package:flutter/material.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/strategy_pages/interactive_colored_cards_view.dart';
import 'package:sign_education/strategy_pages/interactive_comparison_view.dart';
import 'package:sign_education/strategy_pages/interactive_hierarchy_view.dart';
import 'package:sign_education/strategy_pages/interactive_journalistic_questions_view.dart';
import 'package:sign_education/strategy_pages/interactive_mindmap_view.dart';
import 'package:sign_education/strategy_pages/interactive_six_hat_view.dart';
import 'package:sign_education/strategy_pages/interactive_story_view.dart';
import 'package:sign_education/strategy_pages/interactive_timeline_view.dart';
import 'package:sign_education/strategy_pages/interactive_triangle_view.dart';
import 'package:sign_education/utils/strategy_catalog.dart';

String strategyLabelForType(String type) => StrategyCatalog.labelForType(type);

IconData strategyIconForType(String type) => StrategyCatalog.iconForType(type);

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
          builder: (_) =>
              InteractiveMindMapView(username: user.name, mindMapJson: json),
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
          builder: (_) =>
              InteractiveHierarchyView(user: user, hierarchyJson: json),
        ),
      );
      return;
    case 'type_9':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InteractiveColoredCardsView(user: user, cardsJson: json),
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
          builder: (_) =>
              InteractiveTriangleView(user: user, triangleJson: json),
        ),
      );
      return;
    case 'type_12':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SixHatPage(user: user, jsonInput: json),
        ),
      );
      return;
    case 'type_13':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InteractiveJournalisticQuestionsView(user: user, json: json),
        ),
      );
      return;
    case 'type_14':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InteractiveEducationalStoryView(user: user, json: json),
        ),
      );
      return;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هذه الاستراتيجية غير مدعومة: ${strategy.strategyType}',
          ),
        ),
      );
  }
}

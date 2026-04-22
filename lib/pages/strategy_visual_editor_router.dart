import 'package:flutter/material.dart';
import 'package:sign_education/data/models/lesson_strategy_model.dart';
import 'package:sign_education/pages/strategy_visual_editors/colored_cards_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/comparison_table_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/hierarchy_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/journalistic_questions_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/mindmap_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/six_hat_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/story_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/timeline_editor_page.dart';
import 'package:sign_education/pages/strategy_visual_editors/triangle_editor_page.dart';

Future<bool?> openVisualStrategyEditor(
  BuildContext context, {
  required LessonStrategyModel strategy,
}) {
  final Widget page;
  switch (strategy.strategyType) {
    case 'type_0':
      page = MindMapEditorPage(strategy: strategy);
      break;
    case 'type_5':
      page = TimelineEditorPage(strategy: strategy);
      break;
    case 'type_6':
      page = HierarchyEditorPage(strategy: strategy);
      break;
    case 'type_9':
      page = ColoredCardsEditorPage(strategy: strategy);
      break;
    case 'type_10':
      page = ComparisonTableEditorPage(strategy: strategy);
      break;
    case 'type_11':
      page = TriangleEditorPage(strategy: strategy);
      break;
    case 'type_12':
      page = SixHatEditorPage(strategy: strategy);
      break;
    case 'type_13':
      page = JournalisticQuestionsEditorPage(strategy: strategy);
      break;
    case 'type_14':
      page = EducationalStoryEditorPage(strategy: strategy);
      break;
    default:
      return showDialog<bool>(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('غير مدعوم'),
          content: Text('لا يوجد محرّر بصري لهذا النوع حالياً.'),
        ),
      );
  }

  return Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}


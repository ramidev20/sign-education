import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:sign_education/data/prompts.dart';

/// API CONFIGURATION
/// ================================
const apiKey = "";
const url = "https://openrouter.ai/api/v1/chat/completions";
const model = "poolside/laguna-xs.2:free";
const model1 = "openai/gpt-3.5-turbo-16k";

/// Common request timeout
const requestTimeout = Duration(seconds: 360);

///  HELPER FUNCTION
/// ================================
Future<Map<String, dynamic>> _sendPrompt({
  required String systemPrompt,
  required String userPrompt,
}) async {
  try {
    if (apiKey.isEmpty) {
      throw Exception(
        'Missing OPENROUTER_API_KEY. Run the app with --dart-define=OPENROUTER_API_KEY=your_key',
      );
    }

    final languageHint = _isArabicText(userPrompt)
        ? '\n\nOUTPUT LANGUAGE: Arabic (use Arabic terms, labels, and sentences).'
        : '\n\nOUTPUT LANGUAGE: Match the input language.';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $apiKey",
          },
          body: jsonEncode({
            "model": model,
            "messages": [
              {"role": "system", "content": systemPrompt},
              {
                "role": "user",
                "content":
                    "$userPrompt$languageHint\n\n⚠️ Important: Output ONLY valid JSON. No markdown, no text before or after the JSON.",
              },
            ],
          }),
        )
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}: ${response.body}");
    }

    final data = jsonDecode(response.body);
    var content = (data["choices"]?[0]?["message"]?["content"] ?? "")
        .toString()
        .replaceAll(RegExp(r"```json|```"), "")
        .trim();

    // Try parsing JSON safely
    try {
      return jsonDecode(content);
    } catch (e) {
      debugPrint(
        "⚠️ JSON parsing failed, content preview: ${content.substring(0, content.length > 300 ? 300 : content.length)}",
      );
      throw Exception("Invalid JSON format in model output: $e");
    }
  } catch (e) {
    debugPrint("❌ Error: $e");
    throw Exception("Error generating data: $e");
  }
}

bool _isArabicText(String text) {
  // Arabic unicode block (basic + supplement coverage for common text)
  return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
}

Future<Map<String, dynamic>> generateMindMapFromText(String text) async {
  debugPrint("🧠 Generating Mind Map...");
  return await _sendPrompt(
    systemPrompt: mindmap_prompt,
    userPrompt: "Convert this subject into a mind map JSON structure: $text",
  );
}

Future<Map<String, dynamic>> generatesixHatFromText(String text) async {
  debugPrint("🎩 Generating Six Hat Thinking...");
  return await _sendPrompt(
    systemPrompt: six_hat_prompt,
    userPrompt: "Convert this subject into six hat thinking JSON: $text",
  );
}

Future<Map<String, dynamic>> generateTimeLineFromText(String text) async {
  debugPrint("🕓 Generating Timeline...");
  return await _sendPrompt(
    systemPrompt: timeline_prompt,
    userPrompt: "Convert this subject into a timeline JSON structure: $text",
  );
}

Future<Map<String, dynamic>> generateHierarchyFromText(String text) async {
  debugPrint("📚 Generating Hierarchical Progression...");
  return await _sendPrompt(
    systemPrompt: hierarchical_prompt,
    userPrompt:
        "Organize the following topic or text into a hierarchical progression from simple/general to complex/specific: $text",
  );
}

Future<Map<String, dynamic>> generateComparisonTableFromText(
  String text,
) async {
  debugPrint("📊 Generating Comparison Table...");
  return await _sendPrompt(
    systemPrompt: comparison_prompt,
    userPrompt:
        "Convert this text into a structured comparison table JSON: $text",
  );
}

Future<Map<String, dynamic>> generateColoredCardsFromText(String text) async {
  debugPrint("🎨 Generating Colored Concept Cards...");
  return await _sendPrompt(
    systemPrompt: colored_cards_prompt,
    userPrompt:
        "Convert this lesson content into colored concept cards JSON format, and make all type values Arabic only: $text",
  );
}

Future<Map<String, dynamic>> generateJournalisticQuestionsFromText(
  String text,
) async {
  debugPrint("🗞️ Generating Journalistic Questions...");
  return await _sendPrompt(
    systemPrompt: journalistic_questions_prompt,
    userPrompt:
        "Convert this lesson content into JSON of journalistic questions (Who, What, When, Where, Why, How) and their answers: $text",
  );
}

Future<Map<String, dynamic>> generateEducationalStoryFromText(
  String text,
) async {
  debugPrint("📖 Generating Educational Story...");
  return await _sendPrompt(
    systemPrompt: educational_story_prompt,
    userPrompt:
        "Convert this lesson into a short educational story in JSON format: $text",
  );
}

Future<Map<String, dynamic>> generateTriangleFromText(String text) async {
  debugPrint("🔺 Generating Educational Triangle...");
  // uses the existing _sendPrompt helper
  return await _sendPrompt(
    systemPrompt: triangle_prompt,
    userPrompt:
        "Convert this lesson into an educational triangle JSON, and include edgeRelations labels for the three triangle edges (top_left, top_right, left_right): $text",
  );
}

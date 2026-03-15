import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:sign_education/data/prompts.dart';

Future<Map<String, dynamic>> generateMindMapFromText(String text) async {
  const apiKey =
      "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";
  const url = "https://openrouter.ai/api/v1/chat/completions";

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "deepseek/deepseek-r1",
        "messages": [
          {"role": "system", "content": mindmap_prompt},
          {
            "role": "user",
            "content": "Convert this subject into mind map JSON: $text",
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      String content = jsonDecode(
        response.body,
      )["choices"][0]["message"]["content"];
      content = content.replaceAll("```json", "").replaceAll("```", "").trim();
      final Map<String, dynamic> mindMapJson = jsonDecode(content);
      return mindMapJson;
    }
    throw Exception("Failed to generate mind map: ${response.statusCode}");
  } catch (e) {
    debugPrint("Error: $e");
    throw Exception("Error generating mind map: $e");
  }
}

Future<Map<String, dynamic>> generatesixHatFromText(String text) async {
  const apiKey =
      "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";
  const url = "https://openrouter.ai/api/v1/chat/completions";

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "deepseek/deepseek-r1",
        "messages": [
          {"role": "system", "content": six_hat_prompt},
          {
            "role": "user",
            "content": "Convert this subject into six hat thinking: $text",
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      String content = jsonDecode(
        response.body,
      )["choices"][0]["message"]["content"];
      content = content.replaceAll("```json", "").replaceAll("```", "").trim();
      final Map<String, dynamic> mindMapJson = jsonDecode(content);
      return mindMapJson;
    }
    throw Exception("Failed to generate mind map: ${response.statusCode}");
  } catch (e) {
    debugPrint("Error: $e");
    throw Exception("Error generating mind map: $e");
  }
}

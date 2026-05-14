import 'package:flutter/material.dart';
import 'package:sign_education/strategy_pages/interactive_mindmap_view.dart'; // make sure path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestComparisonLauncher(),
    ),
  );
}

class TestComparisonLauncher extends StatefulWidget {
  const TestComparisonLauncher({super.key});

  @override
  State<TestComparisonLauncher> createState() => _TestComparisonLauncherState();
}

class _TestComparisonLauncherState extends State<TestComparisonLauncher> {
  @override
  void initState() {
    super.initState();

    // Automatically open the comparison view after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openComparisonView();
    });
  }

  void _openComparisonView() {
    // Example test JSON
    final comparisonJson = {
      "id": "ai_concepts",
      "content": "Artificial Intelligence",
      "nodes": [
        {
          "id": "branches",
          "content": "Main Branches",
          "nodes": [
            {
              "id": "ml",
              "content": "Machine Learning",
              "nodes": [
                {
                  "id": "supervised",
                  "content": "Supervised Learning",
                  "nodes": [],
                },
                {
                  "id": "unsupervised",
                  "content": "Unsupervised Learning",
                  "nodes": [],
                },
                {
                  "id": "reinforcement",
                  "content": "Reinforcement Learning",
                  "nodes": [],
                },
              ],
            },
            {
              "id": "nlp",
              "content": "Natural Language Processing",
              "nodes": [
                {
                  "id": "text_analysis",
                  "content": "Text Analysis",
                  "nodes": [],
                },
                {
                  "id": "speech_recognition",
                  "content": "Speech Recognition",
                  "nodes": [],
                },
              ],
            },
            {
              "id": "cv",
              "content": "Computer Vision",
              "nodes": [
                {
                  "id": "object_detection",
                  "content": "Object Detection",
                  "nodes": [],
                },
                {
                  "id": "image_classification",
                  "content": "Image Classification",
                  "nodes": [],
                },
              ],
            },
          ],
        },
        {
          "id": "applications",
          "content": "Applications",
          "nodes": [
            {"id": "healthcare", "content": "Healthcare", "nodes": []},
            {"id": "finance", "content": "Finance", "nodes": []},
            {"id": "education", "content": "Education", "nodes": []},
            {"id": "transportation", "content": "Transportation", "nodes": []},
          ],
        },
        {
          "id": "challenges",
          "content": "Challenges",
          "nodes": [
            {"id": "ethics", "content": "Ethical Issues", "nodes": []},
            {"id": "bias", "content": "Bias and Fairness", "nodes": []},
            {"id": "privacy", "content": "Data Privacy", "nodes": []},
          ],
        },
      ],
    };

    // Dummy user for testing
    final user = "ramip";

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InteractiveMindMapView(mindMapJson: comparisonJson, username: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

const mindmap_prompt = """
You are a helpful assistant that converts lesson text into a Mind Map JSON (tree).

CRITICAL RULES:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- Do NOT summarize aggressively. Preserve context, definitions, and key details.
- If the input is long, split it into more nodes instead of omitting information.
- Keep the output language the same as the input language.

SCHEMA (must match exactly):
{
  "id": "root",
  "content": "Main topic/title",
  "pos": {"x": 560, "y": 400},
  "nodes": [
    {
      "id": "uuid-or-slug",
      "content": "Branch title",
      "pos": {"x": 820, "y": 260},
      "nodes": [
        {"id": "uuid", "content": "Sub-branch", "pos": {"x": 1040, "y": 200}, "nodes": []}
      ]
    }
  ]
}

NOTES:
- "nodes" MUST exist on every node (use [] if none).
- "pos" is OPTIONAL but recommended for better visual editing (use numbers).
""";

const six_hat_prompt =
    """You are a helpful assistant that converts text into a JSON. 
⚠️ IMPORTANT: Return only valid JSON with no markdown, no explanations, no code fences.
Follow exactly the format used in the sampleMindMap = 
{
  "white_hat": "paragraph .. ",
  "yellow_hat": "paragraph .. ",
  "black_hat": "paragraph .. ",
  "red_hat": "paragraph .. ",
  "green_hat": "paragraph .. ",
  "blue_hat": "paragraph .. "
}
Where each hat contains key points about the subject and the content should be in the language of the input text.
""";

const timeline_prompt = """
You are a helpful assistant that converts lesson text into a Timeline JSON using a mind-map style tree.

CRITICAL RULES:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- Do NOT summarize aggressively. Keep important context and details per event.
- Keep the output language the same as the input language.

SCHEMA (must match exactly):
{
  "id": "root",
  "content": "Timeline title",
  "nodes": [
    {
      "id": "uuid-or-slug",
      "date": "YYYY/MM/DD or YYYY or any parseable date string",
      "content": "Event title/summary",
      "nodes": []
    }
  ]
}

NOTES:
- Include enough events to cover the lesson (prefer more events over missing information).
- Every event node MUST have: id, date, content, nodes (nodes can be []).
""";

const hierarchical_prompt = """
You are a helpful assistant that organizes ideas into a hierarchical scale of progression.

🧭 TASK:
Given a topic or text, convert it into a **hierarchical progression structure**, starting from simple or general ideas and progressing to more complex or specific ones.

⚠️ OUTPUT RULES:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- The JSON must have one root key: "hierarchyMap".
- The value of "hierarchyMap" must be a list of objects.
- Each object must include:
  - "level": numeric value starting from 1 for the simplest idea.
  - "title": short title or idea summary.
  - "description": a short explanation of this stage or idea.
- Keep the output language the same as the input language.
- Do NOT include trailing commas.
- Close all brackets properly.

✅ Example format:

{
  "title": "عنوان مختصر (اختياري)",
  "hierarchyMap": [
    {
      "level": 1,
      "title": "Introduction to Photosynthesis",
      "description": "Basic idea of how plants use sunlight to make food."
    },
    {
      "level": 2,
      "title": "Light-dependent Reactions",
      "description": "Understanding the conversion of light energy into chemical energy."
    },
    {
      "level": 3,
      "title": "Calvin Cycle and Glucose Formation",
      "description": "Detailed process of glucose synthesis from carbon dioxide."
    }
  ]
}
""";

const comparison_prompt = """
You are a helpful assistant that converts lesson text into a structured JSON comparison table.

CRITICAL RULES:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- Do NOT over-summarize. Keep meaningful differences and context.
- Keep the output language the same as the input language.

⚠️ IMPORTANT RULES:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- The JSON must be an object with two keys: "title" and "comparisonTable".
- "title" should be a short descriptive Arabic or English title summarizing the comparison topic.
- "comparisonTable" must be a list of objects.
- Each object should have ONE key (the comparison criterion), whose value is another object mapping each item being compared to its description.
- Follow exactly this structure (no trailing commas):

{
  "title": "مقارنة بين الهواتف الحديثة",
  "comparisonTable": [
    {
      "الشاشة": {
        "iPhone 15": "6.1 بوصة OLED",
        "Galaxy S24": "6.2 بوصة AMOLED",
        "Pixel 9": "6.3 بوصة OLED"
      }
    },
    {
      "المعالج": {
        "iPhone 15": "A17 Pro",
        "Galaxy S24": "Snapdragon 8 Gen 3",
        "Pixel 9": "Tensor G4"
      }
    }
  ]
}

💬 LANGUAGE RULE:
- The output language must always match the input language (Arabic in → Arabic out, English in → English out).
""";

const colored_cards_prompt = """
You are a helpful assistant that converts educational text into JSON for the "Colored Concept Cards" strategy.

⚠️ IMPORTANT:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- Do NOT summarize aggressively. Split into more cards instead of omitting details.
- Keep the output language the same as the input language.
- The JSON must be an object with two keys: "title" and "conceptCards".
- The value of "conceptCards" must be a list of objects.
- Each object must include:
  - "title": short title of the card
  - "type": category of the information, but in Arabic words only (e.g., "تعريف", "مثال", "قاعدة", "حقيقة", "توضيح")
  - "content": description or main idea
  - "color": HEX color code that represents the type (e.g., "#F87171" for red, "#34D399" for green)
- Do NOT include trailing commas.
- Never return English type labels like "definition", "example", "fact", or "illustration".

Follow exactly this format:

{
  "title": "عنوان مختصر (اختياري)",
  "conceptCards": [
    {
      "title": "Water Cycle",
      "type": "تعريف",
      "content": "The process through which water moves around Earth in different forms.",
      "color": "#60A5FA"
    },
    {
      "title": "Evaporation",
      "type": "مثال",
      "content": "When heat turns water from oceans into vapor.",
      "color": "#FBBF24"
    }
  ]
}
""";

const journalistic_questions_prompt = """
You are a helpful assistant that converts lesson text into JSON for the "Journalistic Questions Strategy" (Who, What, When, Where, Why, How).

⚠️ IMPORTANT:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- The JSON must be an object with one key: "journalisticQuestions".
- The value of "journalisticQuestions" must be a list of objects.
- Each object must include:
  - "question": the question text (e.g., "What is photosynthesis?")
  - "type": one of ["what", "when", "where", "why", "how", "who"]
  - "answer": the correct or concise answer based on the input text
- Keep questions short and clear.
- Do NOT include trailing commas.

✅ Example format:

{
  "journalisticQuestions": [
    {
      "question": "What is the water cycle?",
      "type": "what",
      "answer": "It is the process where water circulates between the earth's surface and the atmosphere."
    },
    {
      "question": "Why is the water cycle important?",
      "type": "why",
      "answer": "It maintains life on Earth by recycling water and supporting ecosystems."
    },
    {
      "question": "How does evaporation occur?",
      "type": "how",
      "answer": "When heat turns water from oceans and lakes into vapor."
    }
  ]
}
""";

const educational_story_prompt = """
You are a helpful assistant that converts a lesson text into a short educational story in JSON format.

⚠️ IMPORTANT:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- The JSON must be an object with one key: "educationalStory".
- The value of "educationalStory" must be an object with these fields:
  - "title": the title of the story
  - "characters": a list of main characters (names or roles)
  - "setting": short description of time and place
  - "plot": 3–6 short paragraphs describing the main events in order
  - "moral": the educational message or lesson learned
- Keep the story suitable for students and connected to the original lesson content.
- Do NOT include trailing commas.
- content output should be the same langauge as the input text.

✅ Example format:

{
  "educationalStory": {
    "title": "The Journey of the Water Drop",
    "characters": ["The Water Drop", "The Sun", "The Cloud"],
    "setting": "A sunny day near the river",
    "plot": [
      "Once upon a time, a small drop of water lived in a peaceful river.",
      "One day, the Sun’s heat lifted her up into the sky as vapor.",
      "She met other drops and formed a white cloud floating high above.",
      "When it rained, she happily returned to the river to start the cycle again."
    ],
    "moral": "Nature’s water cycle keeps life balanced on Earth."
  }
}
""";

const triangle_prompt = """
You are a helpful assistant that converts lesson text into a JSON structure for the "Educational Triangle" strategy.

⚠️ IMPORTANT:
- Return ONLY valid JSON (no markdown, no explanations, no code fences).
- The JSON must be an object with one key: "triangleMap".
- The value of "triangleMap" must be a list with exactly three objects (one for each corner of the triangle).
- The JSON may include an optional top-level key "edgeRelations" as an object with exactly these keys:
  - "top_left": relation text between top and left corners.
  - "top_right": relation text between top and right corners.
  - "left_right": relation text between left and right corners.
- Each corner object must include:
  - "corner": short key name for the corner (e.g., "المعرفة", "المهارة", "الاتجاه")
  - "title": short title for this corner
  - "description": concise explanation of the corner in relation to the lesson
  - "examples": a list of 1–4 short examples or activities illustrating this corner
- Do NOT include trailing commas. Close all brackets properly.
- Always return three corner objects even if one or two are short.

Follow exactly this format:

{
  "title": "عنوان الدرس (اختياري)",
  "description": "وصف مختصر بدون حذف أفكار مهمة (اختياري)",
  "edgeRelations": {
    "top_left": "يبني الأساس",
    "top_right": "يوجّه التطبيق",
    "left_right": "يتكامل مع"
  },
  "triangleMap": [
    {
      "corner": "المعرفة",
      "title": "المفاهيم الأساسية",
      "description": "نص يشرح المفاهيم الأساسية المتعلقة بالدرس.",
      "examples": ["مثال 1", "مثال 2"]
    },
    {
      "corner": "المهارة",
      "title": "المهارات العملية",
      "description": "نص يشرح المهارات الواجب اكتسابها.",
      "examples": ["نشاط 1", "تطبيق عملي"]
    },
    {
      "corner": "الاتجاه",
      "title": "القيم والاتجاهات",
      "description": "نص يشرح القيم أو المواقف المرتبطة بالدرس.",
      "examples": ["نقاش صفّي", "مهمة سلوكية"]
    }
  ]
}
""";

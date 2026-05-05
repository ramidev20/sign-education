/// Dictionary words.
///
/// Fields:
/// - `en`: English label
/// - `ar`: Arabic label
/// - `clip`: asset video path
/// - `subject`: one of the ids in `dictionarySubjects`
/// - `difficulty`: `easy` | `medium` | `hard`
const List<Map<String, dynamic>> dictData = [
  // arabic
  {
    "en": "study",
    "ar": "دراسة",
    "clip": "assets/videos/study.mp4",
    "subject": "arabic",
    "difficulty": "easy",
  },
  {
    "en": "lesson",
    "ar": "درس",
    "clip": "assets/videos/lesson.mp4",
    "subject": "arabic",
    "difficulty": "easy",
  },
  {
    "en": "question",
    "ar": "سؤال",
    "clip": "assets/videos/question.mp4",
    "subject": "arabic",
    "difficulty": "medium",
  },
  {
    "en": "grammar",
    "ar": "نحو",
    "clip": "assets/videos/grammar.mp4",
    "subject": "arabic",
    "difficulty": "medium",
  },
  {
    "en": "syntax",
    "ar": "إعراب",
    "clip": "assets/videos/syntax.mp4",
    "subject": "arabic",
    "difficulty": "hard",
  },

  // english
  {
    "en": "hi",
    "ar": "مرحبا",
    "clip": "assets/videos/hi.mp4",
    "subject": "english",
    "difficulty": "easy",
  },
  {
    "en": "chat",
    "ar": "دردشة",
    "clip": "assets/videos/chat.mp4",
    "subject": "english",
    "difficulty": "medium",
  },
  {
    "en": "verb",
    "ar": "فعل",
    "clip": "assets/videos/verb.mp4",
    "subject": "english",
    "difficulty": "easy",
  },
  {
    "en": "sentence",
    "ar": "جملة",
    "clip": "assets/videos/sentence.mp4",
    "subject": "english",
    "difficulty": "medium",
  },
  {
    "en": "dictionary",
    "ar": "قاموس",
    "clip": "assets/videos/dictionary.mp4",
    "subject": "english",
    "difficulty": "hard",
  },

  // french
  {
    "en": "bonjour",
    "ar": "مرحبا",
    "clip": "assets/videos/bonjour.mp4",
    "subject": "french",
    "difficulty": "easy",
  },
  {
    "en": "ecole",
    "ar": "مدرسة",
    "clip": "assets/videos/ecole.mp4",
    "subject": "french",
    "difficulty": "easy",
  },
  {
    "en": "lecture",
    "ar": "قراءة",
    "clip": "assets/videos/lecture.mp4",
    "subject": "french",
    "difficulty": "medium",
  },
  {
    "en": "ecriture",
    "ar": "كتابة",
    "clip": "assets/videos/ecriture.mp4",
    "subject": "french",
    "difficulty": "medium",
  },
  {
    "en": "grammaire",
    "ar": "قواعد",
    "clip": "assets/videos/grammaire.mp4",
    "subject": "french",
    "difficulty": "hard",
  },

  // philosophy
  {
    "en": "mind",
    "ar": "عقل",
    "clip": "assets/videos/mind.mp4",
    "subject": "philosophy",
    "difficulty": "easy",
  },
  {
    "en": "philosophy",
    "ar": "فلسفة",
    "clip": "assets/videos/philosophy.mp4",
    "subject": "philosophy",
    "difficulty": "easy",
  },
  {
    "en": "discussion",
    "ar": "مناقشة",
    "clip": "assets/videos/discussion.mp4",
    "subject": "philosophy",
    "difficulty": "medium",
  },
  {
    "en": "argument",
    "ar": "حجة",
    "clip": "assets/videos/argument.mp4",
    "subject": "philosophy",
    "difficulty": "medium",
  },
  {
    "en": "ethics",
    "ar": "أخلاق",
    "clip": "assets/videos/ethics.mp4",
    "subject": "philosophy",
    "difficulty": "hard",
  },

  // history
  {
    "en": "history",
    "ar": "تاريخ",
    "clip": "assets/videos/history.mp4",
    "subject": "history",
    "difficulty": "easy",
  },
  {
    "en": "civilization",
    "ar": "حضارة",
    "clip": "assets/videos/civilization.mp4",
    "subject": "history",
    "difficulty": "medium",
  },
  {
    "en": "war",
    "ar": "حرب",
    "clip": "assets/videos/war.mp4",
    "subject": "history",
    "difficulty": "medium",
  },
  {
    "en": "revolution",
    "ar": "ثورة",
    "clip": "assets/videos/revolution.mp4",
    "subject": "history",
    "difficulty": "hard",
  },
  {
    "en": "empire",
    "ar": "إمبراطورية",
    "clip": "assets/videos/empire.mp4",
    "subject": "history",
    "difficulty": "hard",
  },

  // geography
  {
    "en": "geography",
    "ar": "جغرافيا",
    "clip": "assets/videos/geography.mp4",
    "subject": "geography",
    "difficulty": "easy",
  },
  {
    "en": "map",
    "ar": "خريطة",
    "clip": "assets/videos/map.mp4",
    "subject": "geography",
    "difficulty": "easy",
  },
  {
    "en": "climate",
    "ar": "مناخ",
    "clip": "assets/videos/climate.mp4",
    "subject": "geography",
    "difficulty": "medium",
  },
  {
    "en": "continent",
    "ar": "قارة",
    "clip": "assets/videos/continent.mp4",
    "subject": "geography",
    "difficulty": "medium",
  },
  {
    "en": "population",
    "ar": "سكان",
    "clip": "assets/videos/population.mp4",
    "subject": "geography",
    "difficulty": "hard",
  },

  // islamic
  {
    "en": "islamic",
    "ar": "تربية إسلامية",
    "clip": "assets/videos/islamic.mp4",
    "subject": "islamic",
    "difficulty": "easy",
  },
  {
    "en": "prayer",
    "ar": "صلاة",
    "clip": "assets/videos/prayer.mp4",
    "subject": "islamic",
    "difficulty": "easy",
  },
  {
    "en": "zakat",
    "ar": "زكاة",
    "clip": "assets/videos/zakat.mp4",
    "subject": "islamic",
    "difficulty": "medium",
  },
  {
    "en": "fasting",
    "ar": "صيام",
    "clip": "assets/videos/fasting.mp4",
    "subject": "islamic",
    "difficulty": "medium",
  },
  {
    "en": "pilgrimage",
    "ar": "حج",
    "clip": "assets/videos/pilgrimage.mp4",
    "subject": "islamic",
    "difficulty": "hard",
  },

  // math
  {
    "en": "math",
    "ar": "رياضيات",
    "clip": "assets/videos/math.mp4",
    "subject": "math",
    "difficulty": "medium",
  },
  {
    "en": "number",
    "ar": "عدد",
    "clip": "assets/videos/number.mp4",
    "subject": "math",
    "difficulty": "easy",
  },
  {
    "en": "equation",
    "ar": "معادلة",
    "clip": "assets/videos/equation.mp4",
    "subject": "math",
    "difficulty": "medium",
  },
  {
    "en": "fraction",
    "ar": "كسر",
    "clip": "assets/videos/fraction.mp4",
    "subject": "math",
    "difficulty": "medium",
  },
  {
    "en": "geometry",
    "ar": "هندسة",
    "clip": "assets/videos/geometry.mp4",
    "subject": "math",
    "difficulty": "hard",
  },

  // computer science
  {
    "en": "computer",
    "ar": "حاسوب",
    "clip": "assets/videos/computer.mp4",
    "subject": "computer_science",
    "difficulty": "easy",
  },
  {
    "en": "program",
    "ar": "برنامج",
    "clip": "assets/videos/program.mp4",
    "subject": "computer_science",
    "difficulty": "easy",
  },
  {
    "en": "algorithm",
    "ar": "خوارزمية",
    "clip": "assets/videos/algorithm.mp4",
    "subject": "computer_science",
    "difficulty": "medium",
  },
  {
    "en": "network",
    "ar": "شبكة",
    "clip": "assets/videos/network.mp4",
    "subject": "computer_science",
    "difficulty": "medium",
  },
  {
    "en": "database",
    "ar": "قاعدة بيانات",
    "clip": "assets/videos/database.mp4",
    "subject": "computer_science",
    "difficulty": "hard",
  },

  // natural sciences
  {
    "en": "eat",
    "ar": "أكل",
    "clip": "assets/videos/eat.mp4",
    "subject": "natural_sciences",
    "difficulty": "easy",
  },
  {
    "en": "cell",
    "ar": "خلية",
    "clip": "assets/videos/cell.mp4",
    "subject": "natural_sciences",
    "difficulty": "easy",
  },
  {
    "en": "plant",
    "ar": "نبات",
    "clip": "assets/videos/plant.mp4",
    "subject": "natural_sciences",
    "difficulty": "medium",
  },
  {
    "en": "ecosystem",
    "ar": "نظام بيئي",
    "clip": "assets/videos/ecosystem.mp4",
    "subject": "natural_sciences",
    "difficulty": "medium",
  },
  {
    "en": "photosynthesis",
    "ar": "تركيب ضوئي",
    "clip": "assets/videos/photosynthesis.mp4",
    "subject": "natural_sciences",
    "difficulty": "hard",
  },

  // physics
  {
    "en": "physics",
    "ar": "فيزياء",
    "clip": "assets/videos/physics.mp4",
    "subject": "physics",
    "difficulty": "hard",
  },
  {
    "en": "force",
    "ar": "قوة",
    "clip": "assets/videos/force.mp4",
    "subject": "physics",
    "difficulty": "easy",
  },
  {
    "en": "energy",
    "ar": "طاقة",
    "clip": "assets/videos/energy.mp4",
    "subject": "physics",
    "difficulty": "medium",
  },
  {
    "en": "velocity",
    "ar": "سرعة",
    "clip": "assets/videos/velocity.mp4",
    "subject": "physics",
    "difficulty": "medium",
  },
  {
    "en": "electricity",
    "ar": "كهرباء",
    "clip": "assets/videos/electricity.mp4",
    "subject": "physics",
    "difficulty": "hard",
  },
];

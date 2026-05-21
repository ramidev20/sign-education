import 'package:sign_education/utils/app_strings.dart';

String normalizeSubjectId(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;

  final lower = value.toLowerCase();

  switch (lower) {
    case 'math':
    case 'mathematics':
    case 'mathematiques':
    case 'mathématiques':
      return 'math';
    case 'physics':
    case 'physique':
      return 'physics';
    case 'chemistry':
    case 'chimie':
      return 'chemistry';
    case 'natural_sciences':
    case 'natural sciences':
    case 'sciences naturelles':
      return 'natural_sciences';
    case 'biology':
    case 'biologie':
      return 'biology';
    case 'history':
    case 'histoire':
      return 'history';
    case 'geography':
    case 'geographie':
    case 'géographie':
      return 'geography';
    case 'history_geography':
    case 'history and geography':
    case 'histoire et geographie':
    case 'histoire et géographie':
      return 'history_geography';
    case 'philosophy':
    case 'philosophie':
      return 'philosophy';
    case 'arabic':
    case 'arabic language':
    case 'langue arabe':
      return 'arabic';
    case 'french':
    case 'français':
    case 'francais':
      return 'french';
    case 'english':
    case 'anglais':
      return 'english';
    case 'islamic':
    case 'islamic education':
      return 'islamic';
    case 'computer_science':
    case 'computer science':
    case 'informatique':
      return 'computer_science';
  }

  switch (value) {
    case 'رياضيات':
      return 'math';
    case 'فيزياء':
      return 'physics';
    case 'كيمياء':
      return 'chemistry';
    case 'علوم طبيعية':
      return 'natural_sciences';
    case 'أحياء':
    case 'احياء':
      return 'biology';
    case 'تاريخ':
      return 'history';
    case 'جغرافيا':
      return 'geography';
    case 'تاريخ وجغرافيا':
      return 'history_geography';
    case 'فلسفة':
    case 'الفلسفة':
      return 'philosophy';
    case 'اللغة العربية':
      return 'arabic';
    case 'اللغة الفرنسية':
      return 'french';
    case 'اللغة الإنجليزية':
    case 'اللغة الانجليزية':
      return 'english';
    case 'التربية الإسلامية':
    case 'التربية الاسلامية':
      return 'islamic';
    case 'إعلام آلي':
    case 'اعلام آلي':
    case 'إعلام الي':
    case 'اعلام الي':
      return 'computer_science';
  }

  return value;
}

String localizedSubject(AppStrings strings, String raw) {
  final id = normalizeSubjectId(raw);
  final key = 'subject.$id';
  final translated = strings.tr(key);
  return translated == key ? raw : translated;
}


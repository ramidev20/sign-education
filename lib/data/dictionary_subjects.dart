import 'package:flutter/material.dart';

class DictionarySubject {
  final String id;
  final String titleAr;
  final IconData icon;
  final Color color;

  const DictionarySubject({
    required this.id,
    required this.titleAr,
    required this.icon,
    required this.color,
  });
}

const List<DictionarySubject> dictionarySubjects = [
  DictionarySubject(
    id: 'philosophy',
    titleAr: 'الفلسفة',
    icon: Icons.psychology_alt_rounded,
    color: Color(0xFF8E44AD),
  ),
  DictionarySubject(
    id: 'arabic',
    titleAr: 'اللغة العربية',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF16A085),
  ),
  DictionarySubject(
    id: 'history',
    titleAr: 'تاريخ',
    icon: Icons.history_edu_rounded,
    color: Color(0xFFB9770E),
  ),
  DictionarySubject(
    id: 'geography',
    titleAr: 'جغرافيا',
    icon: Icons.public_rounded,
    color: Color(0xFF2980B9),
  ),
  DictionarySubject(
    id: 'islamic',
    titleAr: 'التربية الإسلامية',
    icon: Icons.mosque_rounded,
    color: Color(0xFF2E7D32),
  ),
  DictionarySubject(
    id: 'math',
    titleAr: 'رياضيات',
    icon: Icons.calculate_rounded,
    color: Color(0xFF2C3E50),
  ),
  DictionarySubject(
    id: 'computer_science',
    titleAr: 'إعلام آلي',
    icon: Icons.computer_rounded,
    color: Color(0xFF34495E),
  ),
  DictionarySubject(
    id: 'natural_sciences',
    titleAr: 'علوم طبيعية',
    icon: Icons.science_rounded,
    color: Color(0xFF27AE60),
  ),
  DictionarySubject(
    id: 'physics',
    titleAr: 'فيزياء',
    icon: Icons.bolt_rounded,
    color: Color(0xFFE67E22),
  ),
  DictionarySubject(
    id: 'french',
    titleAr: 'فرنسية',
    icon: Icons.language_rounded,
    color: Color(0xFF1ABC9C),
  ),
  DictionarySubject(
    id: 'english',
    titleAr: 'إنجليزية',
    icon: Icons.translate_rounded,
    color: Color(0xFF3F51B5),
  ),
];


import 'package:flutter/material.dart';

class DictionarySubject {
  final String id;
  final String titleKey;
  final IconData icon;
  final Color color;

  const DictionarySubject({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.color,
  });
}

const List<DictionarySubject> dictionarySubjects = [
  DictionarySubject(
    id: 'philosophy',
    titleKey: 'subject.philosophy',
    icon: Icons.psychology_alt_rounded,
    color: Color(0xFF8E44AD),
  ),
  DictionarySubject(
    id: 'arabic',
    titleKey: 'subject.arabic',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF16A085),
  ),
  DictionarySubject(
    id: 'history',
    titleKey: 'subject.history',
    icon: Icons.history_edu_rounded,
    color: Color(0xFFB9770E),
  ),
  DictionarySubject(
    id: 'geography',
    titleKey: 'subject.geography',
    icon: Icons.public_rounded,
    color: Color(0xFF2980B9),
  ),
  DictionarySubject(
    id: 'islamic',
    titleKey: 'subject.islamic',
    icon: Icons.mosque_rounded,
    color: Color(0xFF2E7D32),
  ),
  DictionarySubject(
    id: 'math',
    titleKey: 'subject.math',
    icon: Icons.calculate_rounded,
    color: Color(0xFF2C3E50),
  ),
  DictionarySubject(
    id: 'computer_science',
    titleKey: 'subject.computer_science',
    icon: Icons.computer_rounded,
    color: Color(0xFF34495E),
  ),
  DictionarySubject(
    id: 'natural_sciences',
    titleKey: 'subject.natural_sciences',
    icon: Icons.science_rounded,
    color: Color(0xFF27AE60),
  ),
  DictionarySubject(
    id: 'physics',
    titleKey: 'subject.physics',
    icon: Icons.bolt_rounded,
    color: Color(0xFFE67E22),
  ),
  DictionarySubject(
    id: 'french',
    titleKey: 'subject.french',
    icon: Icons.language_rounded,
    color: Color(0xFF1ABC9C),
  ),
  DictionarySubject(
    id: 'english',
    titleKey: 'subject.english',
    icon: Icons.translate_rounded,
    color: Color(0xFF3F51B5),
  ),
];


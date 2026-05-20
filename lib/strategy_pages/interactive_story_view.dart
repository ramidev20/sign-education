import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_strings.dart';

class InteractiveEducationalStoryView extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> json;

  const InteractiveEducationalStoryView({
    super.key,
    required this.user,
    required this.json,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final strings = AppStrings.of(context);

    final storyRaw = json['educationalStory'];
    final story =
        storyRaw is Map ? Map<String, dynamic>.from(storyRaw) : const <String, dynamic>{};
    final title = story['title']?.toString().trim().isNotEmpty == true
        ? story['title'].toString()
        : strings.text('قصة تعليمية', 'Educational story', 'Histoire educative');
    final setting = story['setting']?.toString() ?? '';
    final moral = story['moral']?.toString() ?? '';
    final characters = (story['characters'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final plot = (story['plot'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (setting.trim().isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(strings.text('المكان/الزمان', 'Setting', 'Cadre')),
                  subtitle: Text(setting),
                ),
              ),
            if (characters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.text('الشخصيات', 'Characters', 'Personnages'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in characters)
                            Chip(
                              label: Text(c),
                              backgroundColor: cs.primary.withOpacity(0.10),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (plot.isEmpty)
              Center(
                child: Text(
                  strings.text(
                    'لا يوجد محتوى لعرضه',
                    'No content to display',
                    'Aucun contenu a afficher',
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.text('أحداث القصة', 'Story events', 'Evenements de l histoire'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < plot.length; i++) ...[
                        Text(
                          '${i + 1}. ${plot[i]}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (i != plot.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            if (moral.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: Text(strings.text('العبرة', 'Moral', 'Morale')),
                  subtitle: Text(
                    moral,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

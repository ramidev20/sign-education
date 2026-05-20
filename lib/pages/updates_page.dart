import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_strings.dart';

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final updates = <Map<String, String>>[
      {
        'title': strings.updatesStrategyEditorsTitle,
        'date': strings.updatesStrategyEditorsDate,
        'desc': strings.updatesStrategyEditorsDesc,
      },
      {
        'title': strings.updatesLessonsTitle,
        'date': strings.updatesLessonsDate,
        'desc': strings.updatesLessonsDesc,
      },
      {
        'title': strings.updatesThemeTitle,
        'date': strings.updatesThemeDate,
        'desc': strings.updatesThemeDesc,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.latestUpdates),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: updates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = updates[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['date']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['desc']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

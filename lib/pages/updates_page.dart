import 'package:flutter/material.dart';

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updates = <Map<String, String>>[
      {
        'title': 'تحسين محررات الاستراتيجيات',
        'date': '18 أبريل 2026',
        'desc': 'تحسينات على العرض البصري، الترتيب الذكي، ودعم أفضل للمخططات.',
      },
      {
        'title': 'تحسين تجربة الدروس',
        'date': '16 أبريل 2026',
        'desc': 'تحديثات على واجهة المعلم والطالب لتسهيل الوصول للدروس والاستراتيجيات.',
      },
      {
        'title': 'تطوير الأداء والثيم',
        'date': '10 أبريل 2026',
        'desc': 'تحسين التوافق مع الوضع الداكن وتنعيم الانتقالات داخل التطبيق.',
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آخر التحديثات'),
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
      ),
    );
  }
}

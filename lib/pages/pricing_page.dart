import 'package:flutter/material.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = <Map<String, dynamic>>[
      {
        'name': 'الخطة المجانية',
        'price': '0 دج / شهر',
        'features': ['الوصول للدروس الأساسية', 'الواجبات الصفية', 'التواصل داخل المجموعات'],
        'highlight': false,
      },
      {
        'name': 'الخطة التعليمية',
        'price': '1490 دج / شهر',
        'features': ['كل مزايا المجانية', 'استراتيجيات متقدمة', 'تقارير متابعة للمعلم'],
        'highlight': true,
      },
      {
        'name': 'خطة المؤسسات',
        'price': 'حسب الاتفاق',
        'features': ['لوحة إدارة مدرسية', 'دعم مخصص', 'مساحات إعلانية وتعريفية'],
        'highlight': false,
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأسعار والباقات'),
          centerTitle: true,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final plan = plans[index];
            final highlight = plan['highlight'] as bool;
            return Container(
              decoration: BoxDecoration(
                color: highlight
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: highlight
                      ? theme.colorScheme.primary.withValues(alpha: 0.55)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan['name'] as String,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (highlight)
                          Chip(
                            label: const Text('الأكثر شيوعاً'),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan['price'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...(plan['features'] as List<String>).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(feature)),
                          ],
                        ),
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

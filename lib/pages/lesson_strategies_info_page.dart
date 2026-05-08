import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/strategy_catalog.dart';

class LessonStrategiesInfoPage extends StatelessWidget {
  final UserModel user;
  const LessonStrategiesInfoPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <_StrategyInfo>[
      _StrategyInfo(
        title: StrategyCatalog.mindMap.label,
        subtitle: 'تنظيم أفكار الدرس في شجرة مفاهيم مترابطة.',
        icon: StrategyCatalog.mindMap.icon,
        color: const Color(0xFF5B8DEF),
      ),
      _StrategyInfo(
        title: StrategyCatalog.timeline.label,
        subtitle: 'عرض الأحداث أو الأفكار حسب التسلسل الزمني بشكل بصري واضح.',
        icon: StrategyCatalog.timeline.icon,
        color: const Color(0xFF16A34A),
      ),
      _StrategyInfo(
        title: StrategyCatalog.hierarchy.label,
        subtitle: 'ترتيب المفاهيم من البسيط إلى المتقدم لتوضيح مستويات التعلم.',
        icon: Icons.layers_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _StrategyInfo(
        title: StrategyCatalog.coloredCards.label,
        subtitle: 'تقسيم المحتوى إلى بطاقات قصيرة مصنّفة لتسهيل التذكر.',
        icon: StrategyCatalog.coloredCards.icon,
        color: const Color(0xFFEC4899),
      ),
      _StrategyInfo(
        title: StrategyCatalog.comparisonTable.label,
        subtitle: 'مقارنة العناصر أو المفاهيم المتشابهة والاختلافات بينها.',
        icon: StrategyCatalog.comparisonTable.icon,
        color: const Color(0xFF0EA5E9),
      ),
      _StrategyInfo(
        title: StrategyCatalog.triangle.label,
        subtitle: 'شرح الفكرة التعليمية عبر ثلاثة محاور مترابطة داخل مثلث.',
        icon: StrategyCatalog.triangle.icon,
        color: const Color(0xFF8B5CF6),
      ),
      _StrategyInfo(
        title: StrategyCatalog.sixHats.label,
        subtitle: 'تفكير من زوايا مختلفة عبر القبعات الست.',
        icon: StrategyCatalog.sixHats.icon,
        color: const Color(0xFF334155),
      ),
      _StrategyInfo(
        title: StrategyCatalog.journalisticQuestions.label,
        subtitle: 'أسئلة (من؟ ماذا؟ متى؟ أين؟ لماذا؟ كيف؟) مع إجابات.',
        icon: StrategyCatalog.journalisticQuestions.icon,
        color: const Color(0xFF4F46E5),
      ),
      _StrategyInfo(
        title: StrategyCatalog.educationalStory.label,
        subtitle: 'تحويل الدرس إلى قصة تعليمية قصيرة مناسبة للطلاب.',
        icon: StrategyCatalog.educationalStory.icon,
        color: const Color(0xFF059669),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دليل الاستراتيجيات'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: item.color.withOpacity(0.18),
                        child: Icon(item.icon, color: item.color),
                      ),
                      title: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(item.subtitle),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StrategyInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

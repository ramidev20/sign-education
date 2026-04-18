import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/teacher_lesson_strategies_page.dart';

class LessonStrategiesInfoPage extends StatelessWidget {
  final UserModel user;
  const LessonStrategiesInfoPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_StrategyInfo>[
      _StrategyInfo(
        title: 'الخريطة الذهنية',
        subtitle: 'تنظيم أفكار الدرس في شجرة مفاهيم مترابطة تساعد على الفهم السريع.',
        icon: Icons.account_tree_rounded,
        color: const Color(0xFF5B8DEF),
      ),
      _StrategyInfo(
        title: 'المخطط الزمني',
        subtitle: 'عرض الأحداث أو الأفكار حسب التسلسل الزمني بشكل بصري واضح.',
        icon: Icons.timeline_rounded,
        color: const Color(0xFF16A34A),
      ),
      _StrategyInfo(
        title: 'التدرج الهرمي',
        subtitle: 'ترتيب المفاهيم من الأساسي إلى المتقدم لشرح مستويات التعلم.',
        icon: Icons.layers_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _StrategyInfo(
        title: 'البطاقات الملونة',
        subtitle: 'تقسيم المحتوى إلى بطاقات قصيرة مصنّفة بالألوان لسهولة التذكر.',
        icon: Icons.style_rounded,
        color: const Color(0xFFEC4899),
      ),
      _StrategyInfo(
        title: 'جدول المقارنة',
        subtitle: 'مقارنة العناصر أو المفاهيم المتشابهة والاختلافات بينها.',
        icon: Icons.table_chart_rounded,
        color: const Color(0xFF0EA5E9),
      ),
      _StrategyInfo(
        title: 'المثلث التعليمي',
        subtitle: 'شرح الفكرة التعليمية عبر ثلاثة محاور مترابطة داخل مثلث.',
        icon: Icons.change_history_rounded,
        color: const Color(0xFF8B5CF6),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'اختر الاستراتيجية المناسبة ثم افتح إدارة الاستراتيجيات لإضافتها لكل درس وتعديلها.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: item.color.withValues(alpha: 0.18),
                        child: Icon(item.icon, color: item.color),
                      ),
                      title: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherLessonStrategiesPage(user: user),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('فتح إدارة استراتيجيات الدروس'),
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

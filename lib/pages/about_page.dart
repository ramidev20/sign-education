import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('من نحن - منصة الإشارة التعليمية')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              cs.primary.withValues(alpha: 0.08),
              cs.tertiary.withValues(alpha: 0.05),
              cs.surface,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _HeroCard(),
            SizedBox(height: 14),
            _AboutBlock(
              title: 'الرؤية',
              icon: Icons.visibility_outlined,
              content:
                  'نحو تجربة تعليمية عربية شاملة تجعل لغة الإشارة جزءاً طبيعياً من الصف الدراسي.',
            ),
            _AboutBlock(
              title: 'الرسالة',
              icon: Icons.flag_outlined,
              content:
                  'نساعد المعلم والطالب على التعلم بالممارسة عبر الدروس، الاستراتيجيات، الواجبات، والتفاعل المستمر.',
            ),
            _AboutBlock(
              title: 'ما الذي يميزنا؟',
              icon: Icons.auto_awesome_outlined,
              content:
                  'استراتيجيات قابلة للتحرير، واجبات ديناميكية، ودعم للتعلم دون اتصال ضمن تطبيق واحد.',
            ),
            _AboutBlock(
              title: 'لمن صُممت المنصة؟',
              icon: Icons.groups_outlined,
              content:
                  'للمعلمين، الطلاب، والمؤسسات التعليمية التي تحتاج أدوات عملية وحديثة لتعليم لغة الإشارة.',
            ),
            _AboutBlock(
              title: 'فريق العمل',
              icon: Icons.handshake_outlined,
              content:
                  'فريق يجمع بين التربية والتقنية والتصميم، ويتعاون مع مختصين في التربية الخاصة ومجتمع الصم.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.16),
            cs.secondary.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sign_language_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'EduBridge',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'تعليم لغة الإشارة بأسلوب تفاعلي حديث، مع أدوات ذكية تساعد المعلم والطالب على التقدم بشكل واضح.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('دروس تفاعلية')),
              Chip(label: Text('استراتيجيات ذكية')),
              Chip(label: Text('واجبات ديناميكية')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _AboutBlock({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📌 من نحن – منصة الإشارة التعليمية'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            Section(
              emoji: '💡',
              title: 'تعريف مختصر',
              content:
                  'منصة الإشارة هي منصة تعليمية رقمية تهدف إلى تعليم لغة الإشارة العربية بطريقة تفاعلية تجمع بين الدروس، الواجبات، والمناقشات بين الطلاب والمعلمين. تسعى المنصة إلى تمكين الجميع من التواصل بسهولة مع فئة الصم وضعاف السمع، وتعزيز دمجهم في المجتمع.',
            ),
            Section(
              emoji: '🌍',
              title: 'رؤيتنا',
              content:
                  'أن نصبح المنصة التعليمية الأولى في العالم العربي لتعلم لغة الإشارة، من خلال تجربة تعلم مبتكرة، سهلة، وشاملة تتيح للمتعلمين التفاعل وتبادل المعرفة في بيئة محفزة وداعمة.',
            ),
            Section(
              emoji: '🎯',
              title: 'رسالتنا',
              content:
                  'تسهيل تعلم لغة الإشارة عبر أدوات رقمية تفاعلية تجمع بين التعليم الذاتي والمجتمعي، وتشجع على الممارسة اليومية والتعاون بين الطلاب والمعلمين، بهدف نشر ثقافة التواصل الشامل.',
            ),
            Section(
              emoji: '⚙️',
              title: 'قيمنا',
              content:
                  'الشمول: نؤمن بحق الجميع في التعلم والتواصل. \n'
                  'التفاعل: نتعلم بالمشاركة والممارسة. \n'
                  'الابتكار: نستخدم التكنولوجيا لتسهيل الفهم والتطبيق. \n'
                  'الاحترام: نعزز ثقافة التواصل الإيجابي بين الجميع. \n'
                  'الاستمرارية: نطور المحتوى باستمرار ليتناسب مع احتياجات المتعلمين. \n',
            ),
            Section(
              emoji: '🛤️',
              title: 'قصتنا',
              content:
                  'انبثقت فكرة منصة الإشارة من الحاجة إلى وسيلة رقمية سهلة لتعلم لغة الإشارة بشكل مبسط وتفاعلي. لاحظنا قلة الموارد العربية المتخصصة في هذا المجال، فقررنا إنشاء منصة تعليمية تجمع بين الدروس المرئية، الواجبات العملية، والمناقشات بين الطلاب لتبادل الخبرات وتحفيز التعلم الجماعي.',
            ),
            Section(
              emoji: '👥',
              title: 'من يقف وراء المنصة؟',
              content:
                  'نحن فريق متنوع من المعلمين، مطوري البرمجيات، وخبراء في تعليم لغة الإشارة. نعمل مع مختصين في التربية الخاصة ومجتمع الصم لضمان دقة المحتوى وجودة التجربة التعليمية.',
            ),
            Section(
              emoji: '📞',
              title: 'تواصل معنا',
              content:
                  'هل ترغب في الانضمام إلى مجتمعنا أو لديك اقتراح لتطوير المنصة؟ \n 📩 يسعدنا تواصلك معنا عبر البريد أو منصاتنا الاجتماعية!',
            ),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String emoji;
  final String title;
  final String content;

  const Section({
    super.key,
    required this.emoji,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

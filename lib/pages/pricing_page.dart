import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_strings.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  String? _expandedPlanId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final features = <_PlanFeature>[
      _PlanFeature(
        id: 'strategy_generation',
        title: strings.text(
          'توليد الاستراتيجيات',
          'Strategy generation',
          'Generation de strategies',
        ),
        subtitle: strings.text(
          'إنشاء استراتيجيات التعلم تلقائيا',
          'Create learning strategies automatically',
          'Creer des strategies automatiquement',
        ),
      ),
      _PlanFeature(
        id: 'strategy_editing',
        title: strings.text(
          'تعديل الاستراتيجيات',
          'Strategy editing',
          'Edition des strategies',
        ),
        subtitle: strings.text(
          'محررات مرئية و JSON',
          'Visual and JSON editors',
          'Editeurs visuels et JSON',
        ),
      ),
      _PlanFeature(
        id: 'assignments',
        title: strings.assignments,
        subtitle: strings.text(
          'إنشاء واجبات ومشاركتها',
          'Create and share assignments',
          'Creer et partager des devoirs',
        ),
      ),
      _PlanFeature(
        id: 'chat_reminders',
        title: strings.text(
          'تذكيرات من الدردشة',
          'Chat reminders',
          'Rappels via chat',
        ),
        subtitle: strings.text(
          'إرسال تذكير بالواجب من داخل الدردشة',
          'Send assignment reminders from chat',
          'Envoyer des rappels depuis le chat',
        ),
      ),
      _PlanFeature(
        id: 'live_quiz',
        title: strings.liveQuiz,
        subtitle: strings.text(
          'اختبارات مباشرة للصف',
          'Live quizzes for class',
          'Quiz en direct pour la classe',
        ),
      ),
      _PlanFeature(
        id: 'insights',
        title: strings.text('متابعة', 'Insights', 'Analyses'),
        subtitle: strings.text(
          'ملخصات بسيطة لتفاعل الطلاب',
          'Basic student engagement insights',
          "Apercus sur l'engagement des eleves",
        ),
      ),
    ];

    final plans = <_Plan>[
      _Plan(
        id: 'free',
        title: strings.tr('plan.free'),
        badge: strings.text('مجاناً', 'Free', 'Gratuit'),
        price: strings.text('0 دج / شهر', '0 DA / month', '0 DA / mois'),
        isRecommended: false,
        enabled: {
          'strategy_generation': true,
          'strategy_editing': false,
          'assignments': true,
          'chat_reminders': false,
          'live_quiz': true,
          'insights': false,
        },
      ),
      _Plan(
        id: 'default',
        title: strings.tr('plan.default'),
        badge: strings.text('افتراضي', 'Default', 'Standard'),
        price: strings.text('790 دج / شهر', '790 DA / month', '790 DA / mois'),
        isRecommended: true,
        enabled: {
          'strategy_generation': true,
          'strategy_editing': true,
          'assignments': true,
          'chat_reminders': true,
          'live_quiz': true,
          'insights': true,
        },
      ),
      _Plan(
        id: 'pro',
        title: strings.tr('plan.pro'),
        badge: 'Pro',
        price: strings.text('1490 دج / شهر', '1490 DA / month', '1490 DA / mois'),
        isRecommended: false,
        enabled: {
          'strategy_generation': true,
          'strategy_editing': true,
          'assignments': true,
          'chat_reminders': true,
          'live_quiz': true,
          'insights': true,
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('pricing.title')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            strings.tr('pricing.teacher_plans'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.tr('pricing.tap_to_view'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ...plans.map((plan) {
            final expanded = _expandedPlanId == plan.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                features: features,
                expanded: expanded,
                onToggle: () {
                  setState(() {
                    _expandedPlanId = expanded ? null : plan.id;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                strings.tr('pricing.note'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String id;
  final String title;
  final String badge;
  final String price;
  final bool isRecommended;
  final Map<String, bool> enabled;

  const _Plan({
    required this.id,
    required this.title,
    required this.badge,
    required this.price,
    required this.isRecommended,
    required this.enabled,
  });
}

class _PlanFeature {
  final String id;
  final String title;
  final String? subtitle;

  const _PlanFeature({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final List<_PlanFeature> features;
  final bool expanded;
  final VoidCallback onToggle;

  const _PlanCard({
    required this.plan,
    required this.features,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final borderColor = plan.isRecommended ? cs.primary : cs.outlineVariant;
    final bgColor = plan.isRecommended
        ? cs.primaryContainer.withValues(alpha: 0.35)
        : cs.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
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
                        plan.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Badge(
                      label: plan.badge,
                      tone: plan.isRecommended
                          ? _BadgeTone.primary
                          : _BadgeTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  plan.price,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      expanded
                          ? strings.tr('pricing.hide_details')
                          : strings.tr('pricing.show_details'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...features.map((feature) {
                          final enabled = plan.enabled[feature.id] ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _FeatureRow(
                              title: feature.title,
                              subtitle: feature.subtitle,
                              enabled: enabled,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  sizeCurve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool enabled;

  const _FeatureRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconColor = enabled ? cs.primary : cs.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          enabled ? Icons.check_circle_outline_rounded : Icons.block_outlined,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _BadgeTone { neutral, primary }

class _Badge extends StatelessWidget {
  final String label;
  final _BadgeTone tone;

  const _Badge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = tone == _BadgeTone.primary
        ? cs.primary
        : cs.surfaceContainerHighest;
    final fg = tone == _BadgeTone.primary ? cs.onPrimary : cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

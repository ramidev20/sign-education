import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_strings.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.aboutPageTitle)),
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
          children: [
            _HeroCard(strings: strings),
            const SizedBox(height: 14),
            _AboutBlock(
              title: strings.aboutVision,
              icon: Icons.visibility_outlined,
              content: strings.aboutVisionText,
            ),
            _AboutBlock(
              title: strings.aboutMission,
              icon: Icons.flag_outlined,
              content: strings.aboutMissionText,
            ),
            _AboutBlock(
              title: strings.aboutWhatMakesUsDifferent,
              icon: Icons.auto_awesome_outlined,
              content: strings.aboutDifferentiatorText,
            ),
            _AboutBlock(
              title: strings.aboutWhoIsItFor,
              icon: Icons.groups_outlined,
              content: strings.aboutAudienceText,
            ),
            _AboutBlock(
              title: strings.aboutTeam,
              icon: Icons.handshake_outlined,
              content: strings.aboutTeamText,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AppStrings strings;

  const _HeroCard({required this.strings});

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
          Text(strings.aboutHeroText),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(strings.interactiveLessonsChip)),
              Chip(label: Text(strings.smartStrategiesChip)),
              Chip(label: Text(strings.dynamicAssignmentsChip)),
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

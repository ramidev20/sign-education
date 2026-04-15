import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_theme.dart';

class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  bool isSwitchOn = true;
  bool isChecked = true;
  int radioValue = 0;
  String? dropdownValue = 'Beginner';

  final TextEditingController nameController =
      TextEditingController(text: 'Bruno Delorence');
  final TextEditingController emailController =
      TextEditingController(text: 'bruno@example.com');

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme & UI Kit Preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _FigmaCoverHeader(),
          const SizedBox(height: 16),

          _Section(
            title: 'Buttons',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Primary'),
                ),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Filled'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('With Icon'),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: const Text('Disabled'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Fields & Dropdown',
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'With error',
                    errorText: 'This field is required',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: dropdownValue,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                    DropdownMenuItem(
                      value: 'Intermediate',
                      child: Text('Intermediate'),
                    ),
                    DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                  ],
                  onChanged: (value) => setState(() => dropdownValue = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Checkbox / Radio / Switch',
            child: Column(
              children: [
                CheckboxListTile(
                  value: isChecked,
                  onChanged: (v) => setState(() => isChecked = v ?? false),
                  title: const Text('Remember me'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                RadioListTile<int>(
                  value: 0,
                  groupValue: radioValue,
                  onChanged: (v) => setState(() => radioValue = v ?? 0),
                  title: const Text('Student'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<int>(
                  value: 1,
                  groupValue: radioValue,
                  onChanged: (v) => setState(() => radioValue = v ?? 1),
                  title: const Text('Teacher'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: isSwitchOn,
                  onChanged: (v) => setState(() => isSwitchOn = v),
                  title: const Text('Notifications'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Cards & Chips',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: AppTheme.smallRadius,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.auto_stories_rounded,
                              color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Japanese Study',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Continue where you left off',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      label: const Text('Lessons'),
                      onDeleted: () {},
                    ),
                    Chip(
                      label: const Text('Assignments'),
                      backgroundColor: cs.primaryContainer,
                      side: BorderSide(color: cs.outlineVariant),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    InputChip(
                      label: const Text('Selected'),
                      selected: true,
                      onSelected: (_) {},
                      selectedColor: cs.primary.withOpacity(0.12),
                      checkmarkColor: cs.primary,
                      side: BorderSide(color: cs.outlineVariant),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Chip(
                      label: const Text('Success'),
                      backgroundColor: AppTheme.successContainer,
                      side: BorderSide(color: AppTheme.success.withOpacity(0.25)),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.success,
                      ),
                      avatar: Icon(Icons.check_circle,
                          color: AppTheme.success, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Dialogs & Sheets',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () => _showDialog(context),
                  child: const Text('Show dialog'),
                ),
                OutlinedButton(
                  onPressed: () => _showBottomSheet(context),
                  child: const Text('Show bottom sheet'),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SnackBar preview')),
                    );
                  },
                  child: const Text('Show snackbar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm action'),
        content: const Text(
          'This dialog uses the app DialogTheme and ColorScheme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bottom sheet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Uses BottomSheetThemeData from AppTheme.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FigmaCoverHeader extends StatelessWidget {
  const _FigmaCoverHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppTheme.globalRadius,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Text(
                  'FREE Version',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accent, width: 3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Educational App\nUI Kit for Online Courses',
              style: theme.textTheme.headlineMedium?.copyWith(
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Theme tokens are derived from the kit dominant colors '
            '(primary violet, soft background, and success green).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

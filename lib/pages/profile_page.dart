import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isTeacher = user.role == "teacher";
    final roleLabel = user.role == "teacher"
        ? "معلم"
        : user.role == "student"
        ? "طالب"
        : "مستخدم";

    return Scaffold(
      appBar: AppBar(
        title: const Text("الملف الشخصي"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'userAvatar',
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: _colorFromHex(
                        user.avatarColor ?? "#607D8B",
                      ),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            _RoleChip(label: roleLabel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MiniStat(
                              icon: Icons.stars_rounded,
                              label: "النقاط",
                              value: user.points.toString(),
                            ),
                            const SizedBox(width: 12),
                            _MiniStat(
                              icon: Icons.calendar_month_rounded,
                              label: "منذ",
                              value:
                                  "${user.createdAt.year}/${user.createdAt.month.toString().padLeft(2, '0')}/${user.createdAt.day.toString().padLeft(2, '0')}",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isTeacher) _TeacherSection(user: user) else _StudentSection(user: user),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("تعديل المعلومات"),
            onPressed: () async {},
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;

  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: AppTheme.smallRadius,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherSection extends StatelessWidget {
  final UserModel user;

  const _TeacherSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final subjects = (user.subjects != null && user.subjects!.isNotEmpty)
        ? user.subjects!.join("، ")
        : "-";

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.work_rounded, color: cs.primary),
            title: Text(
              "معلومات المعلم",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 1),
          _InfoTile(
            icon: Icons.menu_book_rounded,
            title: "المواد التي يدرسها",
            value: subjects,
          ),
        ],
      ),
    );
  }
}

class _StudentSection extends StatelessWidget {
  final UserModel user;

  const _StudentSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.school_rounded, color: cs.primary),
            title: Text(
              "معلومات الطالب",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 1),
          _InfoTile(
            icon: Icons.stacked_bar_chart_rounded,
            title: "المستوى الدراسي",
            value: user.level ?? "-",
          ),
          _InfoTile(
            icon: Icons.account_tree_rounded,
            title: "الشعبة",
            value: user.branch ?? "-",
          ),
          _InfoTile(
            icon: Icons.groups_2_rounded,
            title: "المجموعة",
            value: user.classGroup ?? "-",
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: SizedBox(
        width: 170,
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/group_members_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/imageAvatar.dart';

class ChatSettingsPage extends StatefulWidget {
  final ClassGroupModel group;
  final UserModel currentUser;
  final bool isGroupChat;

  const ChatSettingsPage({
    super.key,
    required this.group,
    required this.currentUser,
    this.isGroupChat = true,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  List<UserModel> _members = [];
  UserModel? _teacher;
  bool _loading = true;

  bool get isTeacher => widget.currentUser.role == 'teacher';

  AppStrings get _strings =>
      AppStrings(Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    final members = await DbHelperClasses.getMembers(widget.group.classGroupId);
    final teacher = members.firstWhere(
      (m) => m.id == widget.group.teacherId,
      orElse: () => widget.currentUser,
    );

    if (!mounted) return;
    setState(() {
      _members = members;
      _teacher = teacher;
      _loading = false;
    });
  }

  Future<void> _openMembersPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupMembersPage(
          group: widget.group,
          currentUser: widget.currentUser,
        ),
      ),
    );
    if (mounted) _loadMembers();
  }

  Future<void> _clearChat() async {
    final strings = _strings;
    final confirm = await _confirm(
      title: strings.text('مسح الرسائل', 'Clear messages', 'Effacer les messages'),
      message: strings.text(
        'هل تريد حذف كل رسائل هذه المجموعة؟',
        'Delete all messages in this group?',
        'Supprimer tous les messages de ce groupe ?',
      ),
      confirmLabel: strings.text('مسح', 'Clear', 'Effacer'),
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperUsers.supabase
        .from('messages')
        .delete()
        .eq('class_group_id', widget.group.classGroupId);

    if (!mounted) return;
    _showSnack(
      strings.text(
        'تم مسح رسائل المجموعة',
        'Group messages cleared',
        'Messages du groupe effaces',
      ),
    );
  }

  Future<void> _deleteGroup() async {
    final strings = _strings;
    final confirm = await _confirm(
      title: strings.text('حذف المجموعة', 'Delete group', 'Supprimer le groupe'),
      message: strings.text(
        'سيتم حذف المجموعة نهائيا. لا يمكن التراجع عن هذا الإجراء.',
        'This group will be deleted permanently. This action cannot be undone.',
        'Ce groupe sera supprime definitivement. Cette action est irreversible.',
      ),
      confirmLabel: strings.text('حذف', 'Delete', 'Supprimer'),
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperClasses.deleteClassGroup(widget.group.classGroupId);
    if (mounted) Navigator.pop(context);
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final strings = _strings;
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _roleLabel(AppStrings strings, UserModel user) {
    if (user.id == widget.group.teacherId) {
      return strings.text('معلم', 'Teacher', 'Enseignant');
    }
    return strings.text('طالب', 'Student', 'Eleve');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final teacherId = _teacher?.id ?? widget.group.teacherId;
    final memberCount = _members.length;
    final studentsCount = _members.where((m) => m.id != teacherId).length;

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('تفاصيل المجموعة', 'Group details', 'Details du groupe'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DefaultAvatar(
                            avatarColor: widget.group.avatarColor,
                            name: widget.group.name ?? widget.group.classGroupId,
                            radius: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.group.name ?? widget.group.classGroupId,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${strings.text('المستوى', 'Level', 'Niveau')}: ${widget.group.level} • '
                            '${strings.text('المادة', 'Subject', 'Matiere')}: ${widget.group.subject}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _HeaderPill(
                                label:
                                    '$memberCount ${strings.text('عضو', 'member(s)', 'membre(s)')}',
                              ),
                              _HeaderPill(
                                label:
                                    '$studentsCount ${strings.text('طالب', 'student(s)', 'eleve(s)')}',
                              ),
                              if (isTeacher)
                                _HeaderPill(
                                  label: strings.text(
                                    'صلاحيات المعلم',
                                    'Teacher privileges',
                                    'Privileges enseignant',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    icon: Icons.people_outline,
                    title: strings.text('الأعضاء', 'Members', 'Membres'),
                  ),
                  _ActionTile(
                    icon: Icons.group_outlined,
                    title: strings.text('عرض الأعضاء', 'View members', 'Voir les membres'),
                    subtitle: strings.text(
                      'إضافة أو إزالة الطلاب',
                      'Add or remove students',
                      'Ajouter ou retirer des eleves',
                    ),
                    onTap: _openMembersPage,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    icon: Icons.info_outline,
                    title: strings.text('معلومات', 'Info', 'Infos'),
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    title: strings.text('رمز المجموعة', 'Group code', 'Code du groupe'),
                    value: widget.group.classGroupId,
                  ),
                  _InfoTile(
                    icon: Icons.person_outline,
                    title: strings.text('المعلم', 'Teacher', 'Enseignant'),
                    value: _teacher?.name ?? '-',
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    icon: Icons.security_outlined,
                    title: strings.text('إدارة', 'Manage', 'Gerer'),
                  ),
                  _ActionTile(
                    icon: Icons.delete_sweep_outlined,
                    iconColor: cs.error,
                    title: strings.text('مسح الرسائل', 'Clear messages', 'Effacer les messages'),
                    subtitle: strings.text(
                      'حذف جميع رسائل المجموعة',
                      'Delete all group messages',
                      'Supprimer tous les messages du groupe',
                    ),
                    onTap: _clearChat,
                  ),
                  if (isTeacher)
                    _ActionTile(
                      icon: Icons.delete_forever_outlined,
                      iconColor: cs.error,
                      title: strings.text('حذف المجموعة', 'Delete group', 'Supprimer le groupe'),
                      subtitle: strings.text(
                        'إزالة المجموعة نهائيا',
                        'Permanently remove the group',
                        'Supprimer le groupe definitivement',
                      ),
                      onTap: _deleteGroup,
                    ),
                  const SizedBox(height: 12),
                  if (_members.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.text('لمحة سريعة', 'Quick look', 'Apercu'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._members.take(6).map((m) {
                              return _MemberTile(
                                user: m,
                                avatarColor: m.avatarColor ?? widget.group.avatarColor,
                                roleLabel: _roleLabel(strings, m),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.user,
    required this.avatarColor,
    required this.roleLabel,
  });

  final UserModel user;
  final String avatarColor;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: DefaultAvatar(
          avatarColor: avatarColor,
          name: user.name,
          radius: 20,
        ),
        title: Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '$roleLabel • ${user.email}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _ActionTile(
      icon: icon,
      title: title,
      subtitle: value.trim().isEmpty ? '-' : value,
      onTap: () {},
      showChevron: false,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = iconColor ?? cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: showChevron ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: onTap,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/group_members_page.dart';
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
    final confirm = await _confirm(
      title: 'مسح الرسائل',
      message: 'هل تريد حذف كل رسائل هذه المجموعة؟',
      confirmLabel: 'مسح',
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperUsers.supabase
        .from('messages')
        .delete()
        .eq('class_group_id', widget.group.classGroupId);

    if (!mounted) return;
    _showSnack('تم مسح رسائل المجموعة');
  }

  Future<void> _deleteGroup() async {
    final confirm = await _confirm(
      title: 'حذف المجموعة',
      message: 'سيتم حذف المجموعة نهائيا. لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
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
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
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
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final studentsCount = _members
        .where((m) => m.id != (_teacher?.id ?? widget.group.teacherId))
        .length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المجموعة')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadMembers,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _GroupHeader(
                      group: widget.group,
                      memberCount: _members.length,
                      isTeacher: isTeacher,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'المعلم',
                    ),
                    if (_teacher != null)
                      _MemberTile(
                        user: _teacher!,
                        roleLabel: 'مالك المجموعة',
                        avatarColor: _teacher?.avatarColor ?? widget.group.avatarColor,
                      ),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.groups_2_outlined,
                      title: 'الأعضاء',
                    ),
                    _ActionTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'إدارة الأعضاء',
                      subtitle:
                          'عدد الطلاب: $studentsCount - عرض وإضافة أو إزالة الأعضاء',
                      onTap: _openMembersPage,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.info_outline_rounded,
                      title: 'معلومات المجموعة',
                    ),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      title: 'المستوى',
                      value: widget.group.level,
                    ),
                    _InfoTile(
                      icon: Icons.account_tree_outlined,
                      title: 'الشعبة',
                      value: widget.group.branch,
                    ),
                    _InfoTile(
                      icon: Icons.menu_book_outlined,
                      title: 'المادة',
                      value: widget.group.subject,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.tune_rounded,
                      title: 'إجراءات المجموعة',
                    ),
                    _ActionTile(
                      icon: Icons.photo_library_outlined,
                      title: 'الوسائط المشتركة',
                      subtitle: 'الصور والملفات المشتركة في المحادثة',
                      onTap: () {},
                    ),
                    _ActionTile(
                      icon: Icons.link_rounded,
                      title: 'الروابط المشتركة',
                      subtitle: 'الروابط التي أرسلها أعضاء المجموعة',
                      onTap: () {},
                    ),
                    if (isTeacher) ...[
                      const SizedBox(height: 8),
                      _ActionTile(
                        icon: Icons.cleaning_services_outlined,
                        title: 'مسح الرسائل',
                        subtitle: 'حذف سجل المحادثة لهذه المجموعة',
                        iconColor: cs.error,
                        onTap: _clearChat,
                      ),
                      _ActionTile(
                        icon: Icons.delete_forever_outlined,
                        title: 'حذف المجموعة',
                        subtitle: 'إزالة هذه المجموعة نهائيا',
                        iconColor: cs.error,
                        onTap: _deleteGroup,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.memberCount,
    required this.isTeacher,
  });

  final ClassGroupModel group;
  final int memberCount;
  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [cs.primary, cs.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          DefaultAvatar(
            avatarColor: group.avatarColor,
            name: group.name,
            radius: 42,
          ),
          const SizedBox(height: 12),
          Text(
            group.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${group.level} • ${group.branch} • ${group.subject}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onPrimary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _HeaderPill(label: '$memberCount عضو'),
              if (isTeacher) const _HeaderPill(label: 'صلاحيات المعلم'),
            ],
          ),
        ],
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
        color: cs.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onPrimary.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onPrimary,
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
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text('$roleLabel • ${user.email}'),
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
        trailing: showChevron ? const Icon(Icons.chevron_left_rounded) : null,
        onTap: onTap,
      ),
    );
  }
}

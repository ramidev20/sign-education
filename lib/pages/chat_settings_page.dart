import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
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
  final TextEditingController _emailController = TextEditingController();

  List<UserModel> _members = [];
  UserModel? _teacher;
  UserModel? _searchResult;
  bool _loading = true;
  bool _searching = false;

  bool get isTeacher => widget.currentUser.role == "teacher";

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _searchUserByEmail(String email) async {
    final query = email.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchResult = null;
    });

    final data = await DbHelperClasses.findUserByEmail(query);
    if (!mounted) return;

    setState(() {
      _searchResult = data;
      _searching = false;
    });

    if (data == null) {
      _showSnack('No user found for $query');
    }
  }

  Future<void> _addMember(UserModel user) async {
    final confirm = await _confirm(
      title: 'Add member',
      message: 'Add ${user.name} (${user.email}) to this group?',
      confirmLabel: 'Add',
    );

    if (confirm != true) return;

    if (_members.any((m) => m.id == user.id)) {
      _showSnack('${user.email} is already a member');
      return;
    }

    await DbHelperClasses.addStudentToClass(
      classGroupId: widget.group.classGroupId,
      studentId: user.id,
    );

    if (!mounted) return;
    setState(() {
      _members.add(user);
      _searchResult = null;
      _emailController.clear();
    });

    _showSnack('${user.name} was added');
  }

  Future<void> _removeMember(UserModel user) async {
    final confirm = await _confirm(
      title: 'Remove member',
      message: 'Remove ${user.name} from this group?',
      confirmLabel: 'Remove',
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperClasses.removeStudentFromClass(
      widget.group.classGroupId,
      user.id,
    );

    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m.id == user.id));
  }

  Future<void> _clearChat() async {
    final confirm = await _confirm(
      title: 'Clear chat',
      message: 'Delete all messages in this group chat?',
      confirmLabel: 'Clear',
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperUsers.supabase
        .from('messages')
        .delete()
        .eq('class_group_id', widget.group.classGroupId);

    if (!mounted) return;
    _showSnack('All chat messages were cleared');
  }

  Future<void> _deleteGroup() async {
    final confirm = await _confirm(
      title: 'Delete group',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final students = _members.where((m) => m.id != _teacher?.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Group details')),
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
                  _SectionTitle(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Teacher',
                  ),
                  if (_teacher != null)
                    _MemberTile(
                      user: _teacher!,
                      roleLabel: 'Owner',
                      avatarColor: widget.group.avatarColor,
                    ),
                  if (isTeacher) ...[
                    const SizedBox(height: 18),
                    _SectionTitle(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Add member',
                    ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Student email',
                        hintText: 'student@email.com',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Search',
                                icon: const Icon(Icons.search_rounded),
                                onPressed: () =>
                                    _searchUserByEmail(_emailController.text),
                              ),
                      ),
                      onSubmitted: _searchUserByEmail,
                    ),
                    if (_searchResult != null) ...[
                      const SizedBox(height: 10),
                      _MemberTile(
                        user: _searchResult!,
                        roleLabel: 'Search result',
                        avatarColor: widget.group.avatarColor,
                        trailing: FilledButton.icon(
                          onPressed: () => _addMember(_searchResult!),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  _SectionTitle(
                    icon: Icons.groups_2_outlined,
                    title: 'Members',
                    trailing: Text(
                      '${students.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (students.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        'No students have joined yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...students.map(
                      (member) => _MemberTile(
                        user: member,
                        avatarColor: widget.group.avatarColor,
                        roleLabel: 'Student',
                        trailing:
                            isTeacher && member.id != widget.currentUser.id
                            ? IconButton(
                                tooltip: 'Remove',
                                onPressed: () => _removeMember(member),
                                icon: Icon(
                                  Icons.person_remove_alt_1_outlined,
                                  color: cs.error,
                                ),
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    icon: Icons.tune_rounded,
                    title: 'Group actions',
                  ),
                  _ActionTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Shared media',
                    subtitle: 'Photos and files shared in this chat',
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.link_rounded,
                    title: 'Shared links',
                    subtitle: 'Links posted by group members',
                    onTap: () {},
                  ),
                  if (isTeacher) ...[
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Clear messages',
                      subtitle: 'Remove all chat history for this group',
                      iconColor: cs.error,
                      onTap: _clearChat,
                    ),
                    _ActionTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete group',
                      subtitle: 'Remove this group permanently',
                      iconColor: cs.error,
                      onTap: _deleteGroup,
                    ),
                  ],
                ],
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              _HeaderPill(label: '$memberCount members'),
              if (isTeacher) const _HeaderPill(label: 'Teacher controls'),
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
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.user,
    required this.avatarColor,
    this.roleLabel,
    this.trailing,
  });

  final UserModel user;
  final String avatarColor;
  final String? roleLabel;
  final Widget? trailing;

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
        subtitle: Text(
          roleLabel == null ? user.email : '$roleLabel • ${user.email}',
        ),
        trailing: trailing,
      ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

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
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

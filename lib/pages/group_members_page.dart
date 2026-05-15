import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/imageAvatar.dart';

class GroupMembersPage extends StatefulWidget {
  const GroupMembersPage({
    super.key,
    required this.group,
    required this.currentUser,
  });

  final ClassGroupModel group;
  final UserModel currentUser;

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final TextEditingController _emailController = TextEditingController();

  List<UserModel> _members = [];
  UserModel? _teacher;
  UserModel? _searchResult;
  bool _loading = true;
  bool _searching = false;

  bool get isTeacher => widget.currentUser.role == 'teacher';

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
      _showSnack('لا يوجد مستخدم بهذا البريد: $query');
    }
  }

  Future<void> _addMember(UserModel user) async {
    if (_members.any((m) => m.id == user.id)) {
      _showSnack('هذا المستخدم موجود في المجموعة بالفعل');
      return;
    }

    final confirm = await _confirm(
      title: 'إضافة عضو',
      message: 'هل تريد إضافة ${user.name} إلى هذه المجموعة؟',
      confirmLabel: 'إضافة',
    );

    if (confirm != true) return;

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

    _showSnack('تمت إضافة ${user.name}');
  }

  Future<void> _removeMember(UserModel user) async {
    final confirm = await _confirm(
      title: 'إزالة عضو',
      message: 'هل تريد إزالة ${user.name} من المجموعة؟',
      confirmLabel: 'إزالة',
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperClasses.removeStudentFromClass(
      widget.group.classGroupId,
      user.id,
    );

    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m.id == user.id));
    _showSnack('تمت إزالة ${user.name}');
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
    final students = _members
        .where((m) => m.id != (_teacher?.id ?? widget.group.teacherId))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('أعضاء المجموعة')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadMembers,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    if (isTeacher) ...[
                      const _SectionTitle(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'إضافة طالب',
                      ),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'بريد الطالب',
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
                                  tooltip: 'بحث',
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
                          avatarColor:
                              _searchResult?.avatarColor ?? widget.group.avatarColor,
                          roleLabel: 'نتيجة البحث',
                          trailing: FilledButton.icon(
                            onPressed: () => _addMember(_searchResult!),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('إضافة'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                    ],
                    const _SectionTitle(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'المعلم',
                    ),
                    if (_teacher != null)
                      _MemberTile(
                        user: _teacher!,
                        avatarColor: _teacher?.avatarColor ?? widget.group.avatarColor,
                        roleLabel: 'مالك المجموعة',
                      ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      icon: Icons.groups_2_outlined,
                      title: 'الطلاب (${students.length})',
                    ),
                    if (students.isEmpty)
                      const _EmptyMembers()
                    else
                      ...students.map(
                        (member) => _MemberTile(
                          user: member,
                          avatarColor: member.avatarColor ?? widget.group.avatarColor,
                          roleLabel: 'طالب',
                          trailing: isTeacher
                              ? IconButton(
                                  tooltip: 'إزالة',
                                  onPressed: () => _removeMember(member),
                                  icon: Icon(
                                    Icons.person_remove_alt_1_outlined,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
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
    this.trailing,
  });

  final UserModel user;
  final String avatarColor;
  final String roleLabel;
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
        subtitle: Text('$roleLabel • ${user.email}'),
        trailing: trailing,
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        'لا يوجد طلاب في هذه المجموعة بعد.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

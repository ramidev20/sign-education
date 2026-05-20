import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_strings.dart';
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

  AppStrings get _strings =>
      AppStrings(Localizations.localeOf(context).languageCode);

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
    final strings = _strings;
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
      _showSnack(
        '${strings.text('لا يوجد مستخدم بهذا البريد', 'No user found for email', 'Aucun utilisateur trouve pour')} : $query',
      );
    }
  }

  Future<void> _addMember(UserModel user) async {
    final strings = _strings;
    if (_members.any((m) => m.id == user.id)) {
      _showSnack(
        strings.text(
          'هذا المستخدم موجود في المجموعة بالفعل',
          'This user is already in the group',
          'Cet utilisateur est deja dans le groupe',
        ),
      );
      return;
    }

    final confirm = await _confirm(
      title: strings.text('إضافة عضو', 'Add member', 'Ajouter un membre'),
      message: strings.text(
        'هل تريد إضافة ${user.name} إلى هذه المجموعة؟',
        'Add ${user.name} to this group?',
        'Ajouter ${user.name} a ce groupe ?',
      ),
      confirmLabel: strings.text('إضافة', 'Add', 'Ajouter'),
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

    _showSnack(
      strings.text(
        'تمت إضافة ${user.name}',
        'Added ${user.name}',
        '${user.name} a ete ajoute',
      ),
    );
  }

  Future<void> _removeMember(UserModel user) async {
    final strings = _strings;
    final confirm = await _confirm(
      title: strings.text('إزالة عضو', 'Remove member', 'Retirer un membre'),
      message: strings.text(
        'هل تريد إزالة ${user.name} من المجموعة؟',
        'Remove ${user.name} from the group?',
        'Retirer ${user.name} du groupe ?',
      ),
      confirmLabel: strings.text('إزالة', 'Remove', 'Retirer'),
      destructive: true,
    );

    if (confirm != true) return;

    await DbHelperClasses.removeStudentFromClass(
      widget.group.classGroupId,
      user.id,
    );

    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m.id == user.id));
    _showSnack(
      strings.text(
        'تمت إزالة ${user.name}',
        'Removed ${user.name}',
        '${user.name} a ete retire',
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final teacher = _teacher;
    final students = _members
        .where((m) => m.id != (teacher?.id ?? widget.group.teacherId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('أعضاء المجموعة', 'Group members', 'Membres du groupe')),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (isTeacher) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.person_add_alt_1_outlined,
                              title: strings.text(
                                'إضافة طالب',
                                'Add student',
                                'Ajouter un eleve',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: strings.text(
                                        'بريد الطالب',
                                        "Student's email",
                                        "Email de l'eleve",
                                      ),
                                      hintText: 'student@email.com',
                                    ),
                                    onSubmitted: _searchUserByEmail,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: _searching
                                      ? null
                                      : () => _searchUserByEmail(
                                            _emailController.text,
                                          ),
                                  icon: _searching
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.search_rounded),
                                  label: Text(
                                    strings.text('بحث', 'Search', 'Rechercher'),
                                  ),
                                ),
                              ],
                            ),
                            if (_searchResult != null) ...[
                              const SizedBox(height: 12),
                              _MemberTile(
                                user: _searchResult!,
                                avatarColor: _searchResult?.avatarColor ??
                                    widget.group.avatarColor,
                                roleLabel: strings.text(
                                  'نتيجة البحث',
                                  'Search result',
                                  'Resultat de recherche',
                                ),
                                trailing: FilledButton.icon(
                                  onPressed: () => _addMember(_searchResult!),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(strings.text('إضافة', 'Add', 'Ajouter')),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _SectionTitle(
                    icon: Icons.admin_panel_settings_outlined,
                    title: strings.text('المعلم', 'Teacher', 'Enseignant'),
                  ),
                  if (teacher != null)
                    _MemberTile(
                      user: teacher,
                      avatarColor:
                          teacher.avatarColor ?? widget.group.avatarColor,
                      roleLabel: strings.text(
                        'مالك المجموعة',
                        'Group owner',
                        'Proprietaire du groupe',
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    icon: Icons.groups_2_outlined,
                    title:
                        '${strings.text('الطلاب', 'Students', 'Eleves')} (${students.length})',
                  ),
                  if (students.isEmpty)
                    _EmptyMembers(
                      message: strings.text(
                        'لا يوجد طلاب في هذه المجموعة بعد.',
                        'No students in this group yet.',
                        "Il n'y a pas encore d'eleves dans ce groupe.",
                      ),
                    )
                  else
                    ...students.map(
                      (member) => _MemberTile(
                        user: member,
                        avatarColor: member.avatarColor ?? widget.group.avatarColor,
                        roleLabel: strings.text('طالب', 'Student', 'Eleve'),
                        trailing: isTeacher
                            ? IconButton(
                                tooltip:
                                    strings.text('إزالة', 'Remove', 'Retirer'),
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
        trailing: trailing,
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers({required this.message});

  final String message;

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
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }
}


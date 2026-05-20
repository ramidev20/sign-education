import 'package:flutter/material.dart';
import 'package:sign_education/auth.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_strings.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late UserModel user;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _schoolNameController;
  late final TextEditingController _subjectsController;
  late final TextEditingController _specializationController;
  late final TextEditingController _yearsExperienceController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianPhoneController;
  late final TextEditingController _studentNumberController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _schoolNameController = TextEditingController(text: user.schoolName ?? '');
    _subjectsController = TextEditingController(
      text: (user.subjects ?? const <String>[]).join(', '),
    );
    _specializationController = TextEditingController(
      text: user.specialization ?? '',
    );
    _yearsExperienceController = TextEditingController(
      text: user.yearsExperience?.toString() ?? '',
    );
    _guardianNameController = TextEditingController(
      text: user.guardianName ?? '',
    );
    _guardianPhoneController = TextEditingController(
      text: user.guardianPhone ?? '',
    );
    _studentNumberController = TextEditingController(
      text: user.studentNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _schoolNameController.dispose();
    _subjectsController.dispose();
    _specializationController.dispose();
    _yearsExperienceController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  Color _colorFromHex(String? hex) {
    final safeHex = (hex == null || hex.isEmpty) ? '#607D8B' : hex;
    final buffer = StringBuffer();
    if (safeHex.length == 6 || safeHex.length == 7) buffer.write('ff');
    buffer.write(safeHex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _roleLabel(AppStrings strings) {
    if (user.role == 'teacher') return strings.teacher;
    if (user.role == 'student') return strings.student;
    return strings.user;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isTeacher = user.role == 'teacher';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, user);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, user),
          ),
          title: Text(strings.profile),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: strings.editProfileAction,
              icon: const Icon(Icons.edit_rounded),
              onPressed: _isSaving
                  ? null
                  : () async {
                      final updatedUser = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(user: user),
                        ),
                      );
                      if (updatedUser != null && mounted) {
                        setState(() {
                          user = updatedUser;
                          _nameController.text = updatedUser.name;
                          _emailController.text = updatedUser.email;
                          _phoneController.text = updatedUser.phone ?? '';
                          _bioController.text = updatedUser.bio ?? '';
                          _schoolNameController.text = updatedUser.schoolName ?? '';
                          _subjectsController.text =
                              (updatedUser.subjects ?? const <String>[]).join(', ');
                          _specializationController.text =
                              updatedUser.specialization ?? '';
                          _yearsExperienceController.text =
                              updatedUser.yearsExperience?.toString() ?? '';
                          _guardianNameController.text =
                              updatedUser.guardianName ?? '';
                          _guardianPhoneController.text =
                              updatedUser.guardianPhone ?? '';
                          _studentNumberController.text =
                              updatedUser.studentNumber ?? '';
                        });
                      }
                    },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final horizontalPadding = isWide ? 24.0 : 16.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                32,
              ),
              children: [
                _ProfileHeroCard(
                  user: user,
                  roleLabel: _roleLabel(strings),
                  colorFromHex: _colorFromHex,
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionCard(
                          title: strings.sharedInfo,
                          icon: Icons.badge_outlined,
                          children: _sharedSummary(strings),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: isTeacher
                            ? _SectionCard(
                                title: strings.teacherInfo,
                                icon: Icons.work_outline_rounded,
                                children: _teacherSummary(strings),
                              )
                            : _SectionCard(
                                title: strings.studentInfo,
                                icon: Icons.school_outlined,
                                children: _studentSummary(strings),
                              ),
                      ),
                    ],
                  )
                else ...[
                  _SectionCard(
                    title: strings.sharedInfo,
                    icon: Icons.badge_outlined,
                    children: _sharedSummary(strings),
                  ),
                  const SizedBox(height: 16),
                  if (isTeacher)
                    _SectionCard(
                      title: strings.teacherInfo,
                      icon: Icons.work_outline_rounded,
                      children: _teacherSummary(strings),
                    )
                  else
                    _SectionCard(
                      title: strings.studentInfo,
                      icon: Icons.school_outlined,
                      children: _studentSummary(strings),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sharedSummary(AppStrings strings) {
    return [
      _InfoTile(
        icon: Icons.person_outline_rounded,
        label: strings.fullName,
        value: user.name,
      ),
      _InfoTile(
        icon: Icons.email_outlined,
        label: strings.email,
        value: user.email,
      ),
      _InfoTile(
        icon: Icons.phone_outlined,
        label: strings.phone,
        value: user.phone ?? '-',
      ),
      _InfoTile(
        icon: Icons.school_outlined,
        label: strings.schoolName,
        value: user.schoolName ?? '-',
      ),
      _InfoTile(
        icon: Icons.notes_rounded,
        label: strings.bio,
        value: user.bio ?? '-',
      ),
    ];
  }

  List<Widget> _teacherSummary(AppStrings strings) {
    return [
      _InfoTile(
        icon: Icons.menu_book_rounded,
        label: strings.taughtSubjects,
        value: (user.subjects ?? const <String>[]).isEmpty
            ? '-'
            : user.subjects!.join(', '),
      ),
      _InfoTile(
        icon: Icons.workspace_premium_outlined,
        label: strings.specialization,
        value: user.specialization ?? '-',
      ),
      _InfoTile(
        icon: Icons.timeline_rounded,
        label: strings.yearsExperience,
        value: user.yearsExperience?.toString() ?? '-',
      ),
    ];
  }

  List<Widget> _studentSummary(AppStrings strings) {
    return [
      _InfoTile(
        icon: Icons.stacked_bar_chart_rounded,
        label: strings.academicLevel,
        value: user.level ?? '-',
      ),
      _InfoTile(
        icon: Icons.account_tree_rounded,
        label: strings.branch,
        value: user.branch ?? '-',
      ),
      _InfoTile(
        icon: Icons.groups_2_rounded,
        label: strings.group,
        value: user.classGroup ?? '-',
      ),
      _InfoTile(
        icon: Icons.badge_outlined,
        label: strings.studentNumber,
        value: user.studentNumber ?? '-',
      ),
      _InfoTile(
        icon: Icons.person_outline_rounded,
        label: strings.guardianName,
        value: user.guardianName ?? '-',
      ),
      _InfoTile(
        icon: Icons.phone_outlined,
        label: strings.guardianPhone,
        value: user.guardianPhone ?? '-',
      ),
    ];
  }

}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _schoolNameController;
  late final TextEditingController _subjectsController;
  late final TextEditingController _specializationController;
  late final TextEditingController _yearsExperienceController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianPhoneController;
  late final TextEditingController _studentNumberController;

  UserModel get user => widget.user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _schoolNameController = TextEditingController(text: user.schoolName ?? '');
    _subjectsController = TextEditingController(
      text: (user.subjects ?? const <String>[]).join(', '),
    );
    _specializationController = TextEditingController(
      text: user.specialization ?? '',
    );
    _yearsExperienceController = TextEditingController(
      text: user.yearsExperience?.toString() ?? '',
    );
    _guardianNameController = TextEditingController(
      text: user.guardianName ?? '',
    );
    _guardianPhoneController = TextEditingController(
      text: user.guardianPhone ?? '',
    );
    _studentNumberController = TextEditingController(
      text: user.studentNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _schoolNameController.dispose();
    _subjectsController.dispose();
    _specializationController.dispose();
    _yearsExperienceController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final strings = AppStrings.of(context);
    final subjects = _subjectsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final yearsExperience = int.tryParse(_yearsExperienceController.text.trim());

    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      phone: _emptyToNull(_phoneController.text),
      bio: _emptyToNull(_bioController.text),
      schoolName: _emptyToNull(_schoolNameController.text),
      subjects: user.role == 'teacher' ? subjects : user.subjects,
      specialization: _emptyToNull(_specializationController.text),
      yearsExperience: yearsExperience,
      guardianName: _emptyToNull(_guardianNameController.text),
      guardianPhone: _emptyToNull(_guardianPhoneController.text),
      studentNumber: _emptyToNull(_studentNumberController.text),
    );

    final updateData = <String, dynamic>{
      'name': updatedUser.name,
      'phone': updatedUser.phone,
      'bio': updatedUser.bio,
      'school_name': updatedUser.schoolName,
      'subjects': user.role == 'teacher' ? updatedUser.subjects : null,
      'specialization':
          user.role == 'teacher' ? updatedUser.specialization : null,
      'years_experience':
          user.role == 'teacher' ? updatedUser.yearsExperience : null,
      'guardian_name':
          user.role == 'student' ? updatedUser.guardianName : null,
      'guardian_phone':
          user.role == 'student' ? updatedUser.guardianPhone : null,
      'student_number':
          user.role == 'student' ? updatedUser.studentNumber : null,
    };

    setState(() => _isSaving = true);
    try {
      await DbHelperUsers.updateUser(user.id, updateData);
      await StorageService.saveUser(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.profileUpdated)));
      Navigator.pop(context, updatedUser);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.saveFailed)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isTeacher = user.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.editProfileDetails),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(strings.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _EditSectionCard(
              title: strings.sharedInfo,
              children: [
                _EditField(
                  controller: _nameController,
                  label: strings.fullName,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return strings.requiredName;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _emailController,
                  label: strings.email,
                  enabled: false,
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _phoneController,
                  label: strings.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _schoolNameController,
                  label: strings.schoolName,
                ),
                const SizedBox(height: 12),
                _EditField(
                  controller: _bioController,
                  label: strings.bio,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _EditSectionCard(
              title: isTeacher ? strings.teacherInfo : strings.studentInfo,
              children: isTeacher
                  ? [
                      _EditField(
                        controller: _subjectsController,
                        label: strings.taughtSubjects,
                      ),
                      const SizedBox(height: 12),
                      _EditField(
                        controller: _specializationController,
                        label: strings.specialization,
                      ),
                      const SizedBox(height: 12),
                      _EditField(
                        controller: _yearsExperienceController,
                        label: strings.yearsExperience,
                        keyboardType: TextInputType.number,
                      ),
                    ]
                  : [
                      _EditField(
                        controller: _studentNumberController,
                        label: strings.studentNumber,
                      ),
                      const SizedBox(height: 12),
                      _EditField(
                        controller: _guardianNameController,
                        label: strings.guardianName,
                      ),
                      const SizedBox(height: 12),
                      _EditField(
                        controller: _guardianPhoneController,
                        label: strings.guardianPhone,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(strings.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _EditSectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _EditField({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final UserModel user;
  final String roleLabel;
  final Color Function(String?) colorFromHex;

  const _ProfileHeroCard({
    required this.user,
    required this.roleLabel,
    required this.colorFromHex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;
            final avatar = Hero(
              tag: 'userAvatar',
              child: CircleAvatar(
                radius: compact ? 42 : 38,
                backgroundColor: colorFromHex(user.avatarColor),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );

            final details = Column(
              crossAxisAlignment:
                  compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment:
                      compact ? WrapAlignment.center : WrapAlignment.start,
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user.name,
                      textAlign: compact ? TextAlign.center : null,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _RoleChip(label: roleLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: compact ? TextAlign.center : null,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact) ...[
                  Center(child: avatar),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: details),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      avatar,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
              ],
            );
          },
        ),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Avoid overflow on small screens / long localized labels by using a flexible row.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

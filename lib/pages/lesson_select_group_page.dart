import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/app_theme.dart';

class LessonSelectGroupPage extends StatefulWidget {
  final UserModel user;
  final String? initiallySelectedGroupId;

  const LessonSelectGroupPage({
    super.key,
    required this.user,
    this.initiallySelectedGroupId,
  });

  @override
  State<LessonSelectGroupPage> createState() => _LessonSelectGroupPageState();
}

class _LessonSelectGroupPageState extends State<LessonSelectGroupPage> {
  bool _loading = true;
  String? _selectedGroupId;
  List<ClassGroupModel> _teacherGroups = const [];
  Map<String, int> _memberCounts = const {};

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initiallySelectedGroupId;
    _fetchTeacherGroups();
  }

  Future<void> _fetchTeacherGroups() async {
    try {
      final groups = await DbHelperClasses.getClassesByTeacher(widget.user.id);
      final counts = <String, int>{};
      for (final g in groups) {
        final members = await DbHelperClasses.getMembers(g.classGroupId);
        counts[g.classGroupId] = members.length;
      }
      if (!mounted) return;
      setState(() {
        _teacherGroups = groups;
        _memberCounts = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _parseColor(String hex) {
    try {
      var clean = hex.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse('0x$clean'));
    } catch (_) {
      return AppTheme.brand;
    }
  }

  void _confirmSelection() {
    if (_selectedGroupId == null) return;
    final selected = _teacherGroups.firstWhere(
      (g) => g.classGroupId == _selectedGroupId,
      orElse: () => _teacherGroups.first,
    );
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('lesson_select_group.title')),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedGroupId == null ? null : _confirmSelection,
            child: Text(
              strings.tr('lesson_select_group.confirm'),
              style: theme.textTheme.labelLarge?.copyWith(
                color:
                    _selectedGroupId == null ? cs.onSurfaceVariant : cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _teacherGroups.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      strings.tr('lesson_select_group.empty'),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          strings.tr('lesson_select_group.hint'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _teacherGroups.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, index) {
                          final group = _teacherGroups[index];
                          final isSelected = group.classGroupId == _selectedGroupId;
                          final memberCount = _memberCounts[group.classGroupId] ?? 0;

                          final color = _parseColor(group.avatarColor ?? '');
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() {
                                _selectedGroupId = group.classGroupId;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withOpacity(0.10)
                                    : cs.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      isSelected ? cs.primary : cs.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color,
                                    radius: 30,
                                    child: const Icon(
                                      Icons.group,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  Text(
                                    group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${group.level} • ${group.subject}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        strings
                                            .tr('lesson_select_group.member_count')
                                            .replaceAll('{n}', '$memberCount'),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: cs.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                      child: FilledButton.icon(
                        onPressed:
                            _selectedGroupId == null ? null : _confirmSelection,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(strings.tr('lesson_select_group.choose')),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

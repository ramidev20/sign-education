import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/new_group_page.dart';
import 'package:sign_education/utils/imageAvatar.dart';
import 'package:sign_education/widgets/app_state.dart';
import 'chat_page.dart';

class GroupsPage extends StatefulWidget {
  final UserModel user;

  const GroupsPage({super.key, required this.user});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<ClassGroupModel> _groups = [];
  Map<String, String> _latestMessages = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (mounted) setState(() => _loading = true);

    final List<ClassGroupModel> groups = widget.user.role == 'teacher'
        ? await DbHelperClasses.getClassesByTeacher(widget.user.id)
        : await DbHelperClasses.getClassesByStudent(widget.user.id);

    final latestByGroup = await Future.wait(
      groups.map((g) async {
        final latest = await DbHelperClasses.getLatestTextMessage(g.classGroupId);
        return MapEntry(g.classGroupId, latest ?? "");
      }),
    );

    if (!mounted) return;
    setState(() {
      _groups = groups;
      _latestMessages = {for (final e in latestByGroup) e.key: e.value};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("مجموعاتي")),
      body: _loading
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: _groups.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        AppEmptyState(
                          icon: Icons.groups_outlined,
                          title: "لا توجد مجموعات بعد",
                          message: widget.user.role == 'teacher'
                              ? "أنشئ مجموعة وابدأ المحادثات مع طلابك."
                              : "سيتم إضافتك إلى المجموعات من طرف المعلم.",
                          actionLabel: "تحديث",
                          onAction: _loadGroups,
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _groups.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (ctx, i) {
                        final g = _groups[i];
                        final latestMessage = _latestMessages[g.classGroupId] ?? "";
                        return ListTile(
                          leading: DefaultAvatar(
                            avatarColor: g.avatarColor,
                            name: g.name,
                            radius: 24,
                          ),
                          title: Text(
                            g.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            latestMessage.isNotEmpty ? latestMessage : "لا توجد رسائل بعد",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(group: g, user: widget.user),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: widget.user.role != 'teacher'
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewGroupPage(teacher: widget.user),
                  ),
                );

                if (created == true) {
                  _loadGroups();
                }
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}

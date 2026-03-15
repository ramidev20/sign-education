import 'package:flutter/material.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/new_group_page.dart';
import 'package:sign_education/utils/imageAvatar.dart';
import 'chat_page.dart';

class GroupsPage extends StatefulWidget {
  final UserModel user; // teacher logged in

  const GroupsPage({super.key, required this.user});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<ClassGroupModel> _groups = [];
  Map<String, String> _latestMessages = {}; // store last messages per group
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    List<ClassGroupModel> groups;
    if (widget.user.role == 'teacher') {
      groups = await DbHelperClasses.getClassesByTeacher(widget.user.id);
    } else {
      groups = await DbHelperClasses.getClassesByStudent(widget.user.id);
    }

    // Load latest message for each group (you need to implement DbHelperClasses.getLatestMessage)
    for (var g in groups) {
      final latest = await DbHelperClasses.getLatestTextMessage(g.classGroupId);
      _latestMessages[g.classGroupId] = latest ?? "";
    }

    if (!mounted) return;

    setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مجموعاتي")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groups.length,
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
                    latestMessage.isNotEmpty
                        ? latestMessage
                        : "لا توجد رسائل بعد",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      floatingActionButton: FloatingActionButton(
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

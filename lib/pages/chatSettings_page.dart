import 'package:flutter/material.dart';
import 'package:sign_education/data/models/class_group_model.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
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
  List<UserModel> _members = [];
  UserModel? _teacher;
  UserModel? _searchResult;
  final TextEditingController _emailController = TextEditingController();

  bool get isTeacher => widget.currentUser.role == "teacher";

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await DbHelperClasses.getMembers(widget.group.classGroupId);

    final teacher = members.firstWhere(
      (m) => m.id == widget.group.teacherId,
      orElse: () => widget.currentUser,
    );

    setState(() {
      _members = members;
      _teacher = teacher;
    });
  }

  Future<void> _searchUserByEmail(String email) async {
    if (email.isEmpty) return;
    final data = await DbHelperClasses.findUserByEmail(email);
    setState(() => _searchResult = data);
  }

  Future<void> _addMember(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "إضافة عضو",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          "هل تريد إضافة ${user.name} (${user.email}) إلى المجموعة؟",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text("إضافة"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_members.any((m) => m.id == user.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ ${user.email} عضو بالفعل")));
      return;
    }

    await DbHelperClasses.addStudentToClass(
      classGroupId: widget.group.classGroupId,
      studentId: user.id,
    );

    setState(() {
      _members.add(user);
      _searchResult = null;
      _emailController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("✅ تمت إضافة ${user.name}")));
  }

  Future<void> _removeMember(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "تأكيد الإزالة",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          "هل تريد إزالة ${user.name} من المجموعة?",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("إزالة"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DbHelperClasses.removeStudentFromClass(
      widget.group.classGroupId,
      user.id,
    );

    setState(() => _members.removeWhere((m) => m.id == user.id));
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "مسح الرسائل",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          "هل تريد مسح جميع رسائل المحادثة؟",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("مسح"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DbHelperUsers.supabase
        .from('messages')
        .delete()
        .eq('class_group_id', widget.group.classGroupId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ تم مسح جميع الرسائل")));
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "حذف المجموعة",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          "لن يمكنك التراجع عن هذه العملية.",
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DbHelperClasses.deleteClassGroup(widget.group.classGroupId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          "إعدادات المجموعة",
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          DefaultAvatar(
            avatarColor: widget.group.avatarColor,
            name: widget.group.name,
            radius: 36,
          ),
          const SizedBox(height: 8),
          Text(
            widget.group.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.group.level} - ${widget.group.branch}",
            style: TextStyle(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "${_members.length} عضو",
            style: TextStyle(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(thickness: 1),

          if (_teacher != null)
            ListTile(
              leading: DefaultAvatar(
                avatarColor: widget.group.avatarColor,
                name: widget.group.name,
                radius: 18,
              ),
              title: Text(
                _teacher!.name,
                style: TextStyle(color: theme.colorScheme.onBackground),
              ),
              subtitle: Text(
                "👑 المشرف",
                style: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ),

          const Divider(thickness: 1),

          if (isTeacher) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "إضافة عضو بالإيميل",
                  hintText: "example@email.com",
                  prefixIcon: Icon(
                    Icons.email,
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                onSubmitted: (value) => _searchUserByEmail(value.trim()),
              ),
            ),
            if (_searchResult != null)
              ListTile(
                leading: DefaultAvatar(
                  avatarColor: widget.group.avatarColor,
                  name: widget.group.name,
                  radius: 18,
                ),
                title: Text(
                  _searchResult!.name,
                  style: TextStyle(color: theme.colorScheme.onBackground),
                ),
                subtitle: Text(
                  _searchResult!.email,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.person_add,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: () => _addMember(_searchResult!),
                ),
              ),
            const Divider(),
          ],

          ListTile(
            title: Text(
              "الأعضاء",
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
          ),
          ..._members
              .where((m) => m.id != _teacher?.id)
              .map(
                (m) => ListTile(
                  leading: DefaultAvatar(
                    avatarColor: widget.group.avatarColor,
                    name: widget.group.name,
                    radius: 18,
                  ),
                  title: Text(
                    m.name,
                    style: TextStyle(color: theme.colorScheme.onBackground),
                  ),
                  subtitle: Text(
                    m.email,
                    style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  trailing: isTeacher && m.id != widget.currentUser.id
                      ? IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _removeMember(m),
                        )
                      : null,
                ),
              ),

          const Divider(),

          ListTile(
            leading: Icon(Icons.photo, color: theme.colorScheme.onBackground),
            title: Text(
              "📷 الصور المشتركة",
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.link, color: theme.colorScheme.onBackground),
            title: Text(
              "🔗 الروابط المشتركة",
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
            onTap: () {},
          ),

          if (isTeacher) ...[
            ListTile(
              leading: Icon(
                Icons.cleaning_services,
                color: theme.colorScheme.secondary,
              ),
              title: Text(
                "مسح جميع الرسائل",
                style: TextStyle(color: theme.colorScheme.onBackground),
              ),
              onTap: _clearChat,
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: theme.colorScheme.error,
              ),
              title: Text(
                "حذف المجموعة",
                style: TextStyle(color: theme.colorScheme.onBackground),
              ),
              onTap: _deleteGroup,
            ),
          ],
        ],
      ),
    );
  }
}

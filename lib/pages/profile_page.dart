import 'package:flutter/material.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/data/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _user.role == "teacher";

    return Scaffold(
      appBar: AppBar(
        title: const Text("الملف الشخصي"),
        centerTitle: true,
        backgroundColor: isTeacher ? AppTheme.accent : AppTheme.brand,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- Profile Avatar ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: _colorFromHex(
                      _user.avatarColor ?? "#607D8B",
                    ),
                    child: Text(
                      _user.name.isNotEmpty ? _user.name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTeacher ? AppTheme.accent : AppTheme.brand,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _user.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _user.email,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 24),

            // --- Role-Specific Layout ---
            if (isTeacher) _teacherLayout(context) else _studentLayout(context),

            const SizedBox(height: 30),

            // --- Edit Button ---
            FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("تعديل المعلومات"),
              onPressed: () async {},
              style: FilledButton.styleFrom(
                backgroundColor: isTeacher ? AppTheme.accent : AppTheme.brand,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.globalRadius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧑‍🎓 Student Layout
  Widget _studentLayout(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.globalRadius),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppTheme.brand),
                const SizedBox(width: 8),
                Text(
                  "معلومات الطالب",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.brand),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("المستوى الدراسي", _user.level ?? "-", context),
            _infoRow("الشعبة", _user.branch ?? "-", context),
            _infoRow(
              "تاريخ التسجيل",
              "${_user.createdAt.year}-${_user.createdAt.month}-${_user.createdAt.day}",
              context,
            ),
          ],
        ),
      ),
    );
  }

  // 👨‍🏫 Teacher Layout
  Widget _teacherLayout(BuildContext context) {
    final subjects = (_user.subjects != null && _user.subjects!.isNotEmpty)
        ? _user.subjects!.join(", ")
        : "-";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.globalRadius),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  "معلومات المعلم",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("المواد التي يدرسها", subjects, context),
            _infoRow(
              "تاريخ الانضمام",
              "${_user.createdAt.year}-${_user.createdAt.month}-${_user.createdAt.day}",
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

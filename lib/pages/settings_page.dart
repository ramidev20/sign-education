import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_education/auth.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/login_page.dart';
import 'package:sign_education/pages/profile_page.dart';
import 'package:sign_education/utils/realtime_listener_service.dart';
import 'package:sign_education/utils/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  final UserModel user;
  const SettingsPage({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    await StorageService.clearUser();
    RealtimeListenerService().stop(); // Stop listeners

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            icon: Icons.person,
            color: Colors.blue,
            title: "الملف الشخصي",
            subtitle: "تعديل معلومات الحساب",
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(user: user)),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.language,
            color: Colors.green,
            title: "اللغة",
            subtitle: "تغيير لغة التطبيق",
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.dark_mode,
            color: Colors.deepPurple,
            title: "الوضع الليلي",
            subtitle: "تفعيل أو إلغاء الوضع الليلي",
            trailing: Switch(
              value: themeController.isDarkMode,
              onChanged: themeController.toggleTheme,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text("تسجيل الخروج"),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

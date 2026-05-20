import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_education/auth.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/local_provider.dart';
import 'package:sign_education/pages/login_page.dart';
import 'package:sign_education/pages/profile_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/realtime_listener_service.dart';
import 'package:sign_education/utils/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel>? onUserChanged;

  const SettingsPage({super.key, required this.user, this.onUserChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _user = widget.user;
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    await StorageService.clearUser();
    RealtimeListenerService().stop();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(user: _user)),
    );

    if (updatedUser != null) {
      setState(() => _user = updatedUser);
      widget.onUserChanged?.call(updatedUser);
    }
  }

  Future<void> _pickLanguage(
    BuildContext context,
    LocaleProvider localeProvider,
  ) async {
    final strings = AppStrings(localeProvider.locale.languageCode);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final currentCode = localeProvider.locale.languageCode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  strings.selectLanguage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${strings.languageCurrentLabel}: ${strings.languageNameForCode(currentCode)}',
                ),
              ),
              _LanguageChoiceTile(
                flag: '🇩🇿',
                label: strings.languageArabicNative,
                selected: currentCode == 'ar',
                onTap: () async {
                  await localeProvider.setLocale(const Locale('ar'));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              _LanguageChoiceTile(
                flag: '🇬🇧',
                label: strings.languageEnglishNative,
                selected: currentCode == 'en',
                onTap: () async {
                  await localeProvider.setLocale(const Locale('en'));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              _LanguageChoiceTile(
                flag: '🇫🇷',
                label: strings.languageFrenchNative,
                selected: currentCode == 'fr',
                onTap: () async {
                  await localeProvider.setLocale(const Locale('fr'));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final strings = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            icon: Icons.person,
            color: cs.secondary,
            title: strings.profile,
            subtitle: strings.profileSettingsSubtitle,
            onTap: () => _openProfile(context),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.language,
            color: cs.tertiary,
            title: strings.language,
            subtitle: localeProvider.locale.languageCode == 'fr'
                ? strings.languageFrenchNative
                : localeProvider.locale.languageCode == 'ar'
                ? strings.languageArabicNative
                : strings.languageEnglishNative,
            onTap: () => _pickLanguage(context, localeProvider),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.dark_mode,
            color: cs.primary,
            title: strings.appTheme,
            subtitle: strings.themeSubtitle,
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
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(strings.logout),
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

class _LanguageChoiceTile extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChoiceTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.surfaceContainerHighest,
        child: Text(flag),
      ),
      title: Text(label),
      trailing: selected ? Icon(Icons.check_circle, color: cs.primary) : null,
      onTap: onTap,
    );
  }
}

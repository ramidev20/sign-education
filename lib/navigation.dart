import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/pages/assignments_page.dart';
import 'package:sign_education/pages/groups_page.dart';
import 'package:sign_education/pages/home_page.dart';
import 'package:sign_education/pages/settings_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:sign_education/utils/theme_controller.dart';

class MyHomePage extends StatefulWidget {
  final UserModel user;
  final String title;

  const MyHomePage({super.key, required this.title, required this.user});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = context.watch<ThemeController>();
    final strings = AppStrings.of(context);
    final isDark = themeController.isDarkMode;

    final pages = <Widget>[
      HomePage(
        user: _user,
        onUserChanged: (updatedUser) {
          setState(() => _user = updatedUser);
        },
      ),
      AssignmentsPage(user: _user),
      GroupsPage(user: _user),
      SettingsPage(
        user: _user,
        onUserChanged: (updatedUser) {
          setState(() => _user = updatedUser);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                  alpha: isDark ? 0.35 : 0.12,
                ),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            iconSize: 28,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: strings.localeHomeLabel,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_rounded),
                label: strings.assignments,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_rounded),
                label: strings.chats,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: strings.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

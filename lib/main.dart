import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:sign_education/auth.dart';
import 'package:sign_education/pages/local_provider.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/utils/theme_controller.dart';
import 'package:sign_education/pages/login_page.dart';
import 'package:sign_education/navigation.dart';
import 'package:sign_education/utils/notification_service.dart';
import 'package:sign_education/utils/realtime_listener_service.dart';
import 'package:sign_education/pages/lessons_page.dart';
import 'package:sign_education/pages/assignments_page.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/pages/quizzes_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://ypbwrimcbxtihamevetr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwYndyaW1jYnh0aWhhbWV2ZXRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3NTI5MzMsImV4cCI6MjA3MjMyODkzM30.25rC-HsNZjbY765KKX1eyxIbGIaYLHk-mcGU44lI_w4',
  );

  // ✅ Initialize local notifications & global navigation tap handler
  await NotificationService.init(
    onNotificationTap: (payload) async {
      final user = await StorageService.getUser();
      if (user == null) return;

      if (payload == 'lessons') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => LessonsPage(user: user)),
        );
      } else if (payload == 'assignments') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => AssignmentsPage(user: user)),
        );
      } else if (payload == 'live_quizzes') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => QuizzesPage(user: user)),
        );
      } else if (payload == 'delivered_assignments') {
        // For teachers: open deliveries tab. For students: open delivered tab.
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AssignmentsPage(
              user: user,
              initialTabIndex: 1,
            ),
          ),
        );
      }
    },
  );

  // ✅ Start the app
  void appRunner() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const MyApp(),
      ),
    );
  }

  final sentryDsn = const String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
      },
      appRunner: appRunner,
    );
  } else {
    appRunner();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Sign Education',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 2));
    var user = await StorageService.getUser();
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    final hasValidSession =
        session != null && session.user.id == (user?.id ?? session.user.id);

    if (user == null && session?.user != null) {
      user = await DbHelperUsers.getUserById(session!.user.id);
      if (user != null) {
        await StorageService.saveUser(user);
      }
    }

    if (user != null && hasValidSession) {
      final resolvedUser = user;
      // ✅ Start realtime listeners globally here
      RealtimeListenerService().start(resolvedUser.id, resolvedUser.role);

      // ✅ Check for any new content since last app open
      await StorageService.checkForNewContent();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MyHomePage(title: "المنصة التعليمية", user: resolvedUser),
        ),
      );
    } else {
      await StorageService.clearUser();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 200),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Education with Signs – Where vision begins and opportunities grow",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

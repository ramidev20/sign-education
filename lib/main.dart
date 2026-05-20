import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sign_education/auth.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/navigation.dart';
import 'package:sign_education/pages/assignments_page.dart';
import 'package:sign_education/pages/lessons_page.dart';
import 'package:sign_education/pages/local_provider.dart';
import 'package:sign_education/pages/login_page.dart';
import 'package:sign_education/pages/quizzes_page.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:sign_education/utils/notification_service.dart';
import 'package:sign_education/utils/realtime_listener_service.dart';
import 'package:sign_education/utils/theme_controller.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypbwrimcbxtihamevetr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwYndyaW1jYnh0aWhhbWV2ZXRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3NTI5MzMsImV4cCI6MjA3MjMyODkzM30.25rC-HsNZjbY765KKX1eyxIbGIaYLHk-mcGU44lI_w4',
  );

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
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AssignmentsPage(user: user, initialTabIndex: 1),
          ),
        );
      }
    },
  );

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
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
    }, appRunner: appRunner);
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
      title: 'EduBridge',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: localeProvider.textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
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
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _brandReveal;
  late final Animation<double> _bridgeSweep;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..forward();

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutBack),
      ),
    );
    _logoLift = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _brandReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic),
    );
    _bridgeSweep = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.92, curve: Curves.easeInOutCubic),
    );
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(milliseconds: 2800));
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
      RealtimeListenerService().start(resolvedUser.id, resolvedUser.role);

      await StorageService.checkForNewContent();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MyHomePage(title: 'EduBridge', user: resolvedUser),
        ),
      );
    } else {
      await StorageService.clearUser();

      if (!mounted) return;

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
    const purpleDark = Color(0xFF4E54C8);
    const purpleMid = Color(0xFF6C7BFF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F8FF), Color(0xFFEAF0FF), Color(0xFFF6F8FF)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _logoLift.value),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: purpleDark.withValues(alpha: 0.22),
                                blurRadius: 34,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: purpleMid.withValues(alpha: 0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/app_icon_master.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 2,
                        left: 18,
                        right: 18,
                        child: SizedBox(
                          height: 18,
                          child: CustomPaint(
                            painter: _BridgeSweepPainter(
                              progress: _bridgeSweep.value,
                              color: purpleMid.withValues(alpha: 0.34),
                            ),
                          ),
                        ),
                      ),
                      _AnimatedBrandName(progress: _brandReveal.value),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedBrandName extends StatelessWidget {
  const _AnimatedBrandName({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const letters = 'EduBridge';
    const brandColor = Color(0xFF4E54C8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: List.generate(letters.length, (index) {
        final start = index / letters.length * 0.34;
        final localProgress = ((progress - start) / 0.66)
            .clamp(0.0, 1.0)
            .toDouble();
        final eased = Curves.easeOutBack.transform(localProgress);

        return Opacity(
          opacity: localProgress,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - eased)),
            child: Text(
              letters[index],
              style: TextStyle(
                color: brandColor,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BridgeSweepPainter extends CustomPainter {
  const _BridgeSweepPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.46,
        -size.height * 0.34,
        size.width,
        size.height * 0.42,
      );

    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(0, metric.length * progress);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawPath(visiblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _BridgeSweepPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

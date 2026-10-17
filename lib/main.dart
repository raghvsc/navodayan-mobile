import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/about_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/connections_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/contributions_screen.dart';
import 'screens/coordinator_dashboard_screen.dart';
import 'screens/directory_screen.dart';
import 'screens/events_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/meeting_screen.dart';
import 'screens/mentorship_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/offerings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/analytics_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    // Pass all uncaught fatal errors from Flutter framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const NavodayanApp());
}

class NavodayanApp extends StatelessWidget {
  const NavodayanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, authProvider, notifProvider, chatProvider) {
            final provider = chatProvider ?? ChatProvider();
            provider.updateAuthProvider(authProvider);
            provider.updateNotificationProvider(notifProvider);
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Navodayan Community',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorObservers: [
              AnalyticsService.instance.observer,
            ],
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/': (context) => const MainNavigationShell(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/join': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/directory': (context) => const DirectoryScreen(),
              '/mentorship': (context) => const MentorshipScreen(),
              '/events': (context) => const EventsScreen(),
              '/about': (context) => const AboutScreen(),
              '/contact': (context) => const ContactScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/profile': (context) => const ProfileScreen(isSelf: true),
              '/chats': (context) => const ChatsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/meeting': (context) => const MeetingScreen(),
              '/contributions': (context) => const ContributionsScreen(),
              '/offerings': (context) => const OfferingsScreen(),
              '/connections': (context) => const ConnectionsScreen(),
              '/coordinator': (context) => const CoordinatorDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}

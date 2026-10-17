import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:navodayan/models/chat_models.dart';
import 'package:navodayan/models/notification_item.dart';
import 'package:navodayan/models/profile.dart';
import 'package:navodayan/models/school.dart';
import 'package:navodayan/providers/auth_provider.dart';
import 'package:navodayan/providers/chat_provider.dart';
import 'package:navodayan/providers/notification_provider.dart';
import 'package:navodayan/providers/theme_provider.dart';
import 'package:navodayan/screens/chats_screen.dart';
import 'package:navodayan/screens/chat_detail_screen.dart';
import 'package:navodayan/screens/home_screen.dart';
import 'package:navodayan/screens/notifications_screen.dart';
import 'package:navodayan/screens/profile_screen.dart';
import 'package:navodayan/screens/settings_screen.dart';
import 'package:navodayan/theme/app_theme.dart';
import 'package:navodayan/utils/image_compressor.dart';
import 'package:navodayan/widgets/app_bar_actions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child, {ThemeProvider? themeProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider ?? ThemeProvider(),
        ),
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
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('ProfileScreen Tests', () {
    testWidgets('Renders ProfileScreen with full details', (WidgetTester tester) async {
      final sampleProfile = Profile(
        id: 'test-p1',
        fullName: 'Anita Kumari',
        currentRole: 'Principal Architect',
        company: 'Microsoft',
        location: 'Hyderabad',
        country: 'India',
        bio: 'Passionate about distributed cloud systems.',
        openToMentor: true,
        industry: 'Technology',
        experience: '12+ Years',
        jnv: School(jnvId: '101', name: 'JNV Ranchi', distt: 'Ranchi'),
        skills: [ProfileSkill(name: 'Cloud Computing'), ProfileSkill(name: 'Architecture')],
      );

      await tester.pumpWidget(
        createTestWidget(
          ProfileScreen(
            initialProfile: sampleProfile,
            profileId: sampleProfile.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anita Kumari'), findsOneWidget);
      expect(find.text('Principal Architect @ Microsoft'), findsOneWidget);
      expect(find.text('JNV School & Batch'), findsOneWidget);
      expect(find.text('JNV Ranchi'), findsOneWidget);
      expect(find.text('Open to Mentoring Navodayans'), findsOneWidget);
      expect(find.text('Passionate about distributed cloud systems.'), findsOneWidget);
      expect(find.text('Cloud Computing'), findsOneWidget);
      expect(find.text('Start Chat'), findsOneWidget);
    });
  });

  group('NotificationsScreen Tests', () {
    testWidgets('Renders NotificationsScreen with items or empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(const NotificationsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ChatsScreen Tests', () {
    testWidgets('Renders login requirement when unauthenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(const ChatsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Member Chat Requires Login'), findsOneWidget);
      expect(find.text('Log In to Chat'), findsOneWidget);
    });
  });

  group('HomeScreen Profile Menu Tests', () {
    testWidgets('Renders Full Name, Profile, Chat Requests, and Logout in profile popup menu', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AuthProvider.tokenKey: 'test-token',
        AuthProvider.userKey: jsonEncode({
          'id': 'u1',
          'email': 'rahul.sharma@example.com',
          'profile': {'fullName': 'Rahul Sharma'},
        }),
      });

      final authProvider = AuthProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider, ChatProvider>(
              create: (_) => ChatProvider(),
              update: (_, auth, notif, chat) {
                final provider = chat ?? ChatProvider();
                provider.updateAuthProvider(auth);
                provider.updateNotificationProvider(notif);
                return provider;
              },
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            routes: {
              '/': (context) => const HomeScreen(),
              '/profile': (context) => const Scaffold(body: Text('Profile Screen Target')),
              '/chats': (context) => const Scaffold(body: Text('Chats Screen Target')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Avatar initial should show 'R'
      expect(find.text('R'), findsOneWidget);

      // Tap on avatar popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify PopupMenu displays Full Name, Profile, Chat Requests, Logout
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Chat Requests'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Verify outdated menu items are NOT in the popup menu
      expect(find.text('About Community'), findsNothing);
      expect(find.text('Contact & Feedback'), findsNothing);
    });
  });

  group('ChatDetailScreen 1-on-1 Video Call Tests', () {
    testWidgets('Renders 1-on-1 video call button and call invite bubble', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AuthProvider.tokenKey: 'test-token',
        AuthProvider.userKey: jsonEncode({
          'id': 'u1',
          'email': 'sender@example.com',
          'profile': {'fullName': 'Sender User'},
        }),
      });

      final authProvider = AuthProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider, ChatProvider>(
              create: (_) => ChatProvider(),
              update: (_, auth, notif, chat) {
                final provider = chat ?? ChatProvider();
                provider.updateAuthProvider(auth);
                provider.updateNotificationProvider(notif);
                return provider;
              },
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ChatDetailScreen(
              conversationId: 'c1',
              participantId: 'u2',
              participantName: 'Alok Singh',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Video Call icon is present in AppBar
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);

      // Tap the video call icon to open confirmation bottom sheet
      await tester.tap(find.byIcon(Icons.videocam_rounded));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and confirmation button
      expect(find.text('1-on-1 Video Call'), findsOneWidget);
      expect(find.text('with Alok Singh'), findsOneWidget);
      expect(find.text('Start Call'), findsOneWidget);
    });
  });

  group('Global AppBar Actions Tests', () {
    testWidgets('NotificationBellButton and UserProfileMenuButton render on HomeScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationBellButton), findsOneWidget);
      expect(find.byType(UserProfileMenuButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('NotificationBellButton displays unread badge count', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'navodayan_notifications': jsonEncode(List.generate(
          5,
          (i) => {
            'id': 'n_$i',
            'title': 'Test $i',
            'body': 'Body $i',
            'type': 'general',
            'createdAt': DateTime.now().toIso8601String(),
            'isRead': false,
          },
        )),
      });

      final notifProvider = NotificationProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  NotificationBellButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });
  });

  group('Theme & Settings Tests', () {
    test('ThemeProvider defaults to system mode and persists change', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await themeProvider.loadFromPrefs();

      expect(themeProvider.themeMode, ThemeMode.system);
      expect(themeProvider.themeModeName, 'system');

      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.themeModeName, 'dark');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.themeModeName, 'light');
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    testWidgets('SettingsScreen renders Light, Dark, System options with System as default', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await themeProvider.loadFromPrefs();

      await tester.pumpWidget(
        createTestWidget(
          const SettingsScreen(),
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      // Verify System Default is initially selected
      expect(themeProvider.themeMode, ThemeMode.system);

      // Tap Dark Mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, ThemeMode.dark);
    });
  });

  group('HomeScreen Stats & Spotlight Tests', () {
    testWidgets('HomeScreen renders Community stats and Spotlight section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      // Check stats cards
      expect(find.text('Navodayans'), findsOneWidget);
      expect(find.text('JNV Schools'), findsOneWidget);
      expect(find.text('Countries'), findsOneWidget);

      // Check spotlight title
      expect(find.text('Navodayans in the spotlight'), findsOneWidget);
    });
  });

  group('Profile Picture & ImageCompressor Tests', () {
    test('ImageCompressor strictly compresses large images to <= 10 KB (10240 bytes)', () {
      // Create a 600x600 image with complex color patterns
      final testImage = img.Image(width: 600, height: 600);
      for (int y = 0; y < 600; y++) {
        for (int x = 0; x < 600; x++) {
          testImage.setPixelRgb(x, y, (x * 255 ~/ 600), (y * 255 ~/ 600), ((x + y) * 255 ~/ 1200));
        }
      }
      final rawJpeg = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));
      expect(rawJpeg.lengthInBytes, greaterThan(10240));

      final compressed = ImageCompressor.compressToMax10Kb(rawJpeg);
      expect(compressed.lengthInBytes, lessThanOrEqualTo(ImageCompressor.maxBytes));
      expect(compressed.lengthInBytes, lessThanOrEqualTo(10240));
    });

    test('ImageCompressor.cropAndCompress crops image region and compresses to <= 10 KB', () {
      final testImage = img.Image(width: 500, height: 500);
      final rawJpeg = Uint8List.fromList(img.encodeJpg(testImage, quality: 85));

      final cropped = ImageCompressor.cropAndCompress(
        imageBytes: rawJpeg,
        normX: 0.1,
        normY: 0.1,
        normWidth: 0.8,
        normHeight: 0.8,
      );

      expect(cropped.lengthInBytes, lessThanOrEqualTo(10240));
    });

    test('Profile and SpotlightMember deserialize imageUrl field properly', () {
      final profile = Profile.fromJson({
        'id': 'p1',
        'fullName': 'Test User',
        'imageUrl': 'https://navodayan-profile-photos.s3.amazonaws.com/test.jpg',
      });
      expect(profile.imageUrl, 'https://navodayan-profile-photos.s3.amazonaws.com/test.jpg');
    });
  });

  group('Chat Request Notification & Offline Delivery Tests', () {
    testWidgets('NotificationsScreen displays Accept and Reject buttons on pending chat requests', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'navodayan_notifications': jsonEncode([
          {
            'id': 'notif_123',
            'title': 'Chat Request from Priya Sharma',
            'body': 'Hi, I would like to connect with you!',
            'type': 'chatRequest',
            'createdAt': DateTime.now().toIso8601String(),
            'isRead': false,
            'data': {
              'requestId': 'req_test_123',
              'senderId': 'sender_1',
              'senderName': 'Priya Sharma',
              'isOutgoing': false,
            },
          }
        ]),
      });

      final notifProvider = NotificationProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
            ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider, ChatProvider>(
              create: (_) => ChatProvider(),
              update: (_, auth, notif, chat) {
                final provider = chat ?? ChatProvider();
                provider.updateAuthProvider(auth);
                provider.updateNotificationProvider(notif);
                return provider;
              },
            ),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chat Request from Priya Sharma'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Tap Accept
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // Verify that ChatDetailScreen was launched to immediately start the conversation
      expect(find.byType(ChatDetailScreen), findsOneWidget);

      // Pop back to NotificationsScreen
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Accepted • Tap to Chat'), findsOneWidget);
    });
  });
}

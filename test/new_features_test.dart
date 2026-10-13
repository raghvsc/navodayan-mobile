import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navodayan/models/connection.dart';
import 'package:navodayan/models/contribution.dart';
import 'package:navodayan/models/coordinator.dart';
import 'package:navodayan/models/offering.dart';
import 'package:navodayan/providers/auth_provider.dart';
import 'package:navodayan/providers/chat_provider.dart';
import 'package:navodayan/providers/notification_provider.dart';
import 'package:navodayan/screens/connections_screen.dart';
import 'package:navodayan/screens/contributions_screen.dart';
import 'package:navodayan/screens/coordinator_dashboard_screen.dart';
import 'package:navodayan/screens/offerings_screen.dart';
import 'package:navodayan/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
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
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Contributions Model & Screen Tests', () {
    test('Parses ContributionsData correctly', () {
      final json = {
        'status': 'success',
        'data': {
          'jnvId': 346,
          'jnvName': 'JNV Basantpur, Siddharthnagar',
          'summary': {
            'verifiedMoney': 50000,
            'pendingMoney': 10000,
            'committedMoney': 20000,
            'verifiedHours': 120,
            'pendingHours': 15,
          },
          'financial': [
            {
              'id': 'f1',
              'amount': 5000,
              'status': 'VERIFIED',
              'campaignTitle': 'Computer Lab Fund',
              'note': 'Donated for monitors',
            }
          ],
          'physical': [
            {
              'id': 'p1',
              'type': 'MENTORING',
              'hours': 8,
              'status': 'VERIFIED',
              'description': 'Guided Class 12 on JEE prep',
            }
          ]
        }
      };

      final data = ContributionsData.fromJson(json);
      expect(data.jnvId, 346);
      expect(data.jnvName, 'JNV Basantpur, Siddharthnagar');
      expect(data.summary.verifiedMoney, 50000);
      expect(data.summary.verifiedHours, 120);
      expect(data.financial.length, 1);
      expect(data.financial.first.amount, 5000);
      expect(data.financial.first.campaignTitle, 'Computer Lab Fund');
      expect(data.physical.length, 1);
      expect(data.physical.first.hours, 8);
    });

    testWidgets('Renders ContributionsScreen structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ContributionsScreen()));
      await tester.pump();

      expect(find.text('My Contributions'), findsWidgets);
      expect(find.text('Campaigns'), findsWidgets);
      expect(find.text('Log Money'), findsOneWidget);
      expect(find.text('Log Hours'), findsOneWidget);
    });
  });

  group('Offerings Model & Screen Tests', () {
    test('Parses OfferingItem and Category correctly', () {
      final catJson = {'key': 'SERVICE', 'label': 'Service'};
      final cat = OfferingCategory.fromJson(catJson);
      expect(cat.key, 'SERVICE');
      expect(cat.label, 'Service');

      final itemJson = {
        'id': 'off-1',
        'businessName': 'EduNav Tech',
        'category': 'SERVICE',
        'categoryLabel': 'Service',
        'summary': 'EdTech platform built by Navodayans',
        'hiring': true,
        'city': 'Bengaluru',
      };
      final item = OfferingItem.fromJson(itemJson);
      expect(item.id, 'off-1');
      expect(item.businessName, 'EduNav Tech');
      expect(item.category, 'SERVICE');
      expect(item.hiring, isTrue);
      expect(item.city, 'Bengaluru');
    });

    testWidgets('Renders OfferingsScreen with filters and actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const OfferingsScreen()));
      await tester.pump();

      expect(find.text('Navodayan Offerings'), findsOneWidget);
      expect(find.text('All Offerings'), findsOneWidget);
      expect(find.text('Post Offering'), findsOneWidget);
    });
  });

  group('Connections Model & Screen Tests', () {
    test('Parses ConnectionsData correctly', () {
      final json = {
        'status': 'success',
        'data': {
          'incoming': [
            {
              'id': 'req-1',
              'status': 'PENDING',
              'note': 'Hi batchmate!',
              'member': {
                'id': 'm1',
                'fullName': 'Suman Verma',
                'currentRole': 'Data Scientist',
              }
            }
          ],
          'outgoing': [],
          'accepted': [
            {
              'id': 'conn-1',
              'status': 'ACCEPTED',
              'member': {
                'id': 'm2',
                'fullName': 'Prakash Singh',
                'currentRole': 'Founder',
              }
            }
          ],
        }
      };

      final data = ConnectionsData.fromJson(json);
      expect(data.incoming.length, 1);
      expect(data.incoming.first.note, 'Hi batchmate!');
      expect(data.incoming.first.otherMember?.fullName, 'Suman Verma');
      expect(data.accepted.length, 1);
      expect(data.accepted.first.otherMember?.fullName, 'Prakash Singh');
    });

    testWidgets('Renders ConnectionsScreen tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ConnectionsScreen()));
      await tester.pump();

      expect(find.text('My Connections'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Incoming'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
    });
  });

  group('Coordinator Model & Screen Tests', () {
    test('Parses CoordinatorContext and Feedback correctly', () {
      final json = {
        'status': 'success',
        'data': {
          'readOnly': false,
          'canApproveMembers': true,
          'canReviewContributions': true,
          'canManageBatchCoordinators': true,
          'features': {
            'members': true,
            'membershipApprovals': true,
            'contributions': true,
            'feedback': true,
          },
          'viewing': {
            'level': 'JNV',
            'scopeLabel': 'JNV Basantpur, Siddharthnagar',
            'jnvName': 'JNV Basantpur, Siddharthnagar',
          }
        }
      };

      final ctx = CoordinatorContext.fromJson(json);
      expect(ctx.canApproveMembers, isTrue);
      expect(ctx.canReviewContributions, isTrue);
      expect(ctx.features.members, isTrue);
      expect(ctx.viewing.scopeLabel, 'JNV Basantpur, Siddharthnagar');

      final fbJson = {
        'id': 'fb-1',
        'type': 'ISSUE',
        'title': 'Notification Bug',
        'description': 'Push notifications not firing',
        'status': 'IN_PROGRESS',
      };
      final fb = CoordinatorFeedback.fromJson(fbJson);
      expect(fb.id, 'fb-1');
      expect(fb.title, 'Notification Bug');
      expect(fb.status, 'IN_PROGRESS');
    });

    testWidgets('Renders CoordinatorDashboardScreen tabs and feedback action', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const CoordinatorDashboardScreen()));
      await tester.pump();

      expect(find.text('Coordinator Dashboard'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);
    });
  });
}

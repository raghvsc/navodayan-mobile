import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navodayan/main.dart';
import 'package:navodayan/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Renders SplashScreen with logo and branding', (WidgetTester tester) async {
    await tester.pumpWidget(const NavodayanApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('NAVODAYAN'), findsOneWidget);
    expect(find.text('Empowerment Through Education'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Welcome to the Navodayan Community'), findsOneWidget);
  });

  testWidgets('Renders MainNavigationShell with 5 navigation destinations and Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    expect(find.text('NAVODAYAN'), findsWidgets);
    expect(find.text('Welcome to the Navodayan Community'), findsOneWidget);
    expect(find.text('Explore Directory'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.school_outlined), findsWidgets);
    expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
  });

  testWidgets('Renders in Dark Mode when system brightness is dark', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() => tester.platformDispatcher.clearPlatformBrightnessTestValue());

    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    expect(find.text('NAVODAYAN'), findsWidgets);
    expect(find.text('Welcome to the Navodayan Community'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Directory in dark mode
    await tester.tap(find.byIcon(Icons.people_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Navodayan Directory'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Mentorship in dark mode
    await tester.tap(find.byIcon(Icons.school_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Navodayan Mentorship'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Switch to Events in dark mode
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Navodayan Events'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders HomeScreen without RenderFlex overflow on small viewports', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(804, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    expect(find.text('NAVODAYAN'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navigates to LoginScreen on Login button tap', (WidgetTester tester) async {
    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log in to reconnect with your community'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Switches tabs to Directory, Mentorship, Events, and More', (WidgetTester tester) async {
    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    // Tap Directory tab icon
    await tester.tap(find.byIcon(Icons.people_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Navodayan Directory'), findsOneWidget);

    // Tap Mentorship tab icon
    await tester.tap(find.byIcon(Icons.school_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Navodayan Mentorship'), findsWidgets);

    // Tap Events tab icon
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Navodayan Events'), findsWidgets);

    // Tap More tab icon
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
    expect(find.text('More Options'), findsWidgets);
    expect(find.text('About Us'), findsOneWidget);
    expect(find.text('Contact & Feedback'), findsOneWidget);
  });

  testWidgets('Mentorship screen renders Hub and Hero section without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.school_outlined).last);
    await tester.pumpAndSettle();

    expect(find.text('Navodayan Mentorship'), findsWidgets);
    expect(find.text('Alumni Mentorship'), findsOneWidget);
    expect(find.text('Browse Mentors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Community Lounge button is hidden when user is logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const NavodayanApp());
    await tester.pumpAndSettle();

    // In home / root screen when logged out, Community Lounge FAB should not exist
    expect(find.byKey(const ValueKey('global_community_lounge_fab')), findsNothing);
    expect(find.widgetWithText(FloatingActionButton, 'Community Lounge'), findsNothing);

    // In More Options screen when logged out, Community Lounge menu item should not exist
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Community Lounge (Video/Audio)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}


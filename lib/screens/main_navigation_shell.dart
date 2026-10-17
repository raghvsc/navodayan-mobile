import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'chats_screen.dart';
import 'connections_screen.dart';
import 'contributions_screen.dart';
import 'coordinator_dashboard_screen.dart';
import 'directory_screen.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'mentorship_screen.dart';
import 'notifications_screen.dart';
import 'offerings_screen.dart';
import 'profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);

    final pages = [
      HomeScreen(onNavigateTab: _navigateToTab),
      const DirectoryScreen(),
      const MentorshipScreen(),
      const EventsScreen(),
      _buildMoreScreen(auth),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: colors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: colors.primary),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: colors.primary),
            label: 'Mentorship',
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded, color: colors.primary),
            label: 'Events',
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_sharp, color: colors.primary),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildMoreScreen(AuthProvider auth) {
    final colors = AppColors.of(context);
    final notifProvider = context.watch<NotificationProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('More Options'),
        actions: const [
          CommonAppBarActions(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.isAuthenticated) ...[
              Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(isSelf: true),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colors.primary,
                          child: Text(
                            auth.user?.profile?.fullName?.isNotEmpty == true
                                ? auth.user!.profile!.fullName![0].toUpperCase()
                                : (auth.user?.email.isNotEmpty == true
                                    ? auth.user!.email[0].toUpperCase()
                                    : 'U'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.user?.profile?.fullName ?? 'Navodayan Member',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      auth.user?.role ?? 'MEMBER',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  if (auth.user?.isApproved == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join the Community',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create an account or log in to connect with fellow alumni, access mentorship, and chat.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              'COMMUNICATION & NETWORKING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _buildMenuTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Member Chats & Requests',
              subtitle: '1-on-1 private messaging with alumni',
              badgeCount: chatProvider.totalUnreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            if (auth.isAuthenticated) ...[
              _buildMenuTile(
                icon: Icons.people_outline_rounded,
                title: 'My Connections',
                subtitle: 'Manage alumni connection requests & network',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            _buildMenuTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notification Center',
              subtitle: 'Mentorship updates, reminders, and alerts',
              badgeCount: notifProvider.unreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              'OPPORTUNITIES & CONTRIBUTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _buildMenuTile(
              icon: Icons.storefront_outlined,
              title: 'Offerings & Marketplace',
              subtitle: 'Alumni businesses, hiring, services & initiatives',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OfferingsScreen()),
                );
              },
            ),
            if (auth.isAuthenticated) ...[
              const SizedBox(height: 10),
              _buildMenuTile(
                icon: Icons.volunteer_activism_outlined,
                title: 'School Contributions & Support',
                subtitle: 'Track school funds, volunteer hours & campaigns',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContributionsScreen()),
                  );
                },
              ),
            ],
            if (auth.isAuthenticated && (auth.user?.isCoordinator == true || auth.user?.isAdmin == true)) ...[
              const SizedBox(height: 20),
              Text(
                'COORDINATOR PORTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Coordinator Dashboard',
                subtitle: 'School overview, approvals, reviews & feedback',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoordinatorDashboardScreen()),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),

            Text(
              'GENERAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _buildMenuTile(
              icon: Icons.info_outline_rounded,
              title: 'About Us',
              subtitle: 'Our mission and ecosystem',
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
            const SizedBox(height: 10),
            _buildMenuTile(
              icon: Icons.mail_outline_rounded,
              title: 'Contact & Feedback',
              subtitle: 'Get in touch with the volunteer team',
              onTap: () => Navigator.pushNamed(context, '/contact'),
            ),
            const SizedBox(height: 10),
            _buildMenuTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Theme (Light, Dark, System) and preferences',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const SizedBox(height: 10),
            _buildMenuTile(
              icon: Icons.share_rounded,
              title: 'Share Navodayan App',
              subtitle: 'Invite alumni and batchmates to join',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing navodayan.org link...')),
                );
              },
            ),

            if (auth.isAuthenticated) ...[
              const SizedBox(height: 20),
              Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                subtitle: 'View and edit your alumni profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(isSelf: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out from this device',
                onTap: () {
                  auth.logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/navodayan_logo.png',
                    height: 48,
                    width: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Navodayan App v1.0.0\nEmpowerment Through Education',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

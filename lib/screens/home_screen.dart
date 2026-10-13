import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Logo & User Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/navodayan_logo.png',
                        height: 38,
                        width: 38,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NAVODAYAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: colors.primary,
                            ),
                          ),
                          Text(
                            'Community Network',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (auth.isAuthenticated)
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: colors.surface,
                          icon: CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.primary,
                            child: Text(
                              (auth.user?.profile?.fullName?.isNotEmpty == true)
                                  ? auth.user!.profile!.fullName![0].toUpperCase()
                                  : (auth.user?.email.isNotEmpty == true)
                                      ? auth.user!.email[0].toUpperCase()
                                      : 'U',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF0B1120) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          itemBuilder: (ctx) {
                            final fullName = auth.user?.profile?.fullName?.trim();
                            final displayName = (fullName != null && fullName.isNotEmpty)
                                ? fullName
                                : (auth.user?.email ?? 'Navodayan Member');

                            return [
                              PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded, size: 18, color: colors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('Profile', style: TextStyle(color: colors.textPrimary)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'connections',
                                child: Row(
                                  children: [
                                    Icon(Icons.people_outline_rounded, size: 18, color: colors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('My Connections', style: TextStyle(color: colors.textPrimary)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'contributions',
                                child: Row(
                                  children: [
                                    Icon(Icons.volunteer_activism_outlined, size: 18, color: colors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('Contributions', style: TextStyle(color: colors.textPrimary)),
                                  ],
                                ),
                              ),
                              if (auth.user?.isCoordinator == true || auth.user?.isAdmin == true)
                                PopupMenuItem(
                                  value: 'coordinator',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings_outlined, size: 18, color: colors.primary),
                                      const SizedBox(width: 8),
                                      Text('Coordinator Portal', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'chat_requests',
                                child: Row(
                                  children: [
                                    Icon(Icons.mark_chat_unread_outlined, size: 18, color: colors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('Chat Requests', style: TextStyle(color: colors.textPrimary)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout_rounded, color: colors.error, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Logout', style: TextStyle(color: colors.error)),
                                  ],
                                ),
                              ),
                            ];
                          },
                          onSelected: (val) {
                            if (val == 'logout') {
                              auth.logout();
                            } else if (val == 'profile') {
                              Navigator.pushNamed(context, '/profile');
                            } else if (val == 'connections') {
                              Navigator.pushNamed(context, '/connections');
                            } else if (val == 'contributions') {
                              Navigator.pushNamed(context, '/contributions');
                            } else if (val == 'coordinator') {
                              Navigator.pushNamed(context, '/coordinator');
                            } else if (val == 'chat_requests') {
                              Navigator.pushNamed(context, '/chats', arguments: 1);
                            }
                          },
                        )
                      else
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              child: Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text('Join', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF162D59), const Color(0xFF0E1C38)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_outlined, size: 15, color: Color(0xFF93C5FD)),
                        SizedBox(width: 6),
                        Text(
                          'Navodaya Alumni Network',
                          style: TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      auth.isAuthenticated && (auth.user?.profile?.fullName?.isNotEmpty == true)
                          ? 'Welcome back, ${auth.user!.profile!.fullName}!'
                          : 'Welcome to the Navodayan Community',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search batchmates, seek career mentorship, and stay connected with the global JNV family.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(1); // Directory
                        } else {
                          Navigator.pushNamed(context, '/directory');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: isDark ? const Color(0xFF0B1120) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Explore Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  _buildStatItem(context, '10,000+', 'Navodayans'),
                  _buildStatItem(context, '600+', 'JNV Schools'),
                  _buildStatItem(context, '30+', 'Countries'),
                ],
              ),
              const SizedBox(height: 28),

              // Feature shortcuts grid
              Text(
                'Explore Community',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Alumni Directory',
                      desc: 'Search batchmates and professionals',
                      color: colors.primary,
                      onTap: () => onNavigateTab != null ? onNavigateTab!(1) : Navigator.pushNamed(context, '/directory'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.school_rounded,
                      title: 'Mentorship',
                      desc: 'Connect with career mentors',
                      color: colors.secondary,
                      onTap: () => onNavigateTab != null ? onNavigateTab!(2) : Navigator.pushNamed(context, '/mentorship'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.event_available_rounded,
                      title: 'Events & Meets',
                      desc: 'Join meetups and reunions',
                      color: colors.accent,
                      onTap: () => onNavigateTab != null ? onNavigateTab!(3) : Navigator.pushNamed(context, '/events'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.connect_without_contact_rounded,
                      title: 'My Connections',
                      desc: 'Alumni network & requests',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        if (!auth.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please log in to view connections')),
                          );
                          Navigator.pushNamed(context, '/login');
                          return;
                        }
                        Navigator.pushNamed(context, '/connections');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.storefront_rounded,
                      title: 'Offerings & Market',
                      desc: 'Alumni businesses & opportunities',
                      color: const Color(0xFF0284C7),
                      onTap: () => Navigator.pushNamed(context, '/offerings'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.volunteer_activism_rounded,
                      title: 'School Contributions',
                      desc: 'Funds, hours & school campaigns',
                      color: const Color(0xFF059669),
                      onTap: () {
                        if (!auth.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please log in to view contributions')),
                          );
                          Navigator.pushNamed(context, '/login');
                          return;
                        }
                        Navigator.pushNamed(context, '/contributions');
                      },
                    ),
                  ),
                ],
              ),
              if (auth.isAuthenticated && (auth.user?.isCoordinator == true || auth.user?.isAdmin == true)) ...[
                const SizedBox(height: 14),
                _buildFeatureCard(
                  context,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Coordinator Dashboard',
                  desc: 'Manage school alumni, approvals & reviews',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.pushNamed(context, '/coordinator'),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About Us',
                      desc: 'Our mission and ecosystem',
                      color: const Color(0xFF0D9488),
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.forum_rounded,
                      title: 'Member Chats',
                      desc: '1-on-1 alumni messaging',
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        if (!auth.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please log in to view chats')),
                          );
                          Navigator.pushNamed(context, '/login');
                          return;
                        }
                        Navigator.pushNamed(context, '/chats');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact banner card
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/contact'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.mail_outline_rounded, color: colors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Have Suggestions or Feedback?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reach out to our volunteer team',
                              style: TextStyle(color: colors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final colors = AppColors.of(context);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

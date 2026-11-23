import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/community_stats.dart';
import '../providers/auth_provider.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'care_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CommunityService _communityService = CommunityService();

  CommunityStats _stats = CommunityStats.defaultStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final stats = await _communityService.getStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          color: colors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    const CommonAppBarActions(),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Card (matches home_redesigned/code.html)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFF0B2545),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B2545).withValues(alpha: isDark ? 0.35 : 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hub_outlined, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 7),
                          Text(
                            'Navodaya Alumni Network',
                            style: TextStyle(
                              color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                          fontSize: 12.5,
                          color: const Color(0xFFCBD5E1),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(1); // Directory
                          } else {
                            Navigator.pushNamed(context, '/directory');
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF183963),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF60A5FA).withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore Directory',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFBFDBFE)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dynamic Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      context,
                      _isLoadingStats ? '...' : NumberFormat('#,###').format(_stats.navodayans),
                      'Navodayans',
                    ),
                    _buildStatItem(
                      context,
                      _isLoadingStats ? '...' : NumberFormat('#,###').format(_stats.jnvSchools),
                      'JNV Schools',
                    ),
                    _buildStatItem(
                      context,
                      _isLoadingStats ? '...' : NumberFormat('#,###').format(_stats.countries),
                      'Countries',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (auth.isAuthenticated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.space_dashboard_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Desk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check verification, batchmates & circle activity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

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
                        onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(1) : Navigator.pushNamed(context, '/directory'),
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
                        onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(2) : Navigator.pushNamed(context, '/mentorship'),
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
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Navodayan CARE',
                        desc: 'Alumni sessions on exams & careers',
                        color: const Color(0xFFD97706),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CareScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        icon: Icons.event_available_rounded,
                        title: 'Events & Meets',
                        desc: 'Join meetups and reunions',
                        color: colors.accent,
                        onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(3) : Navigator.pushNamed(context, '/events'),
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
                if (auth.isAuthenticated && auth.user?.isCoordinator == true) ...[
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
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Guide',
                        desc: 'Roles, CARE & app guide',
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.pushNamed(context, '/help'),
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
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.35,
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

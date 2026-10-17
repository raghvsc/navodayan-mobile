import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/community_stats.dart';
import '../models/spotlight_member.dart';
import '../providers/auth_provider.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
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

  SpotlightData? _spotlightData;
  bool _isLoadingSpotlight = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final statsFuture = _communityService.getStats();
    final spotlightFuture = _communityService.getSpotlight();

    final results = await Future.wait([statsFuture, spotlightFuture]);

    if (mounted) {
      setState(() {
        _stats = results[0] as CommunityStats;
        _isLoadingStats = false;
        _spotlightData = results[1] as SpotlightData?;
        _isLoadingSpotlight = false;
      });
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
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(1); // Directory
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

                // Navodayans in the Spotlight Section
                _buildSpotlightSection(context),
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
                        icon: Icons.event_available_rounded,
                        title: 'Events & Meets',
                        desc: 'Join meetups and reunions',
                        color: colors.accent,
                        onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(3) : Navigator.pushNamed(context, '/events'),
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
      ),
    );
  }

  Widget _buildSpotlightSection(BuildContext context) {
    final colors = AppColors.of(context);
    final members = _spotlightData?.members ?? [];
    final mode = _spotlightData?.mode ?? 'STATE_RANDOM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: colors.secondary, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Navodayans in the spotlight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1); // Directory
                } else {
                  Navigator.pushNamed(context, '/directory');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'See Directory',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          mode == 'MANUAL'
              ? 'People featured by the community team. Tap card to view profile.'
              : 'One from each state. Tap card to view profile.',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_isLoadingSpotlight)
          SizedBox(
            height: 135,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildSpotlightPlaceholder(colors),
            ),
          )
        else if (members.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No spotlight members available right now. Pull down to refresh.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 135,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildSpotlightCard(context, member, colors);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSpotlightCard(BuildContext context, SpotlightMember member, ThemePalette colors) {
    final initial = member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'N';
    final schoolBatch = member.schoolBatchDisplay;
    final roleCompany = member.roleCompanyDisplay;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(profileId: member.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Avatar + Name + State
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: colors.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        member.state ?? 'India',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Middle: School & Batch
            Row(
              children: [
                Icon(Icons.school_outlined, size: 13, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    schoolBatch.isNotEmpty ? schoolBatch : (member.school ?? 'Navodaya Alumni'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Bottom: Role & Company
            Row(
              children: [
                Icon(Icons.work_outline_rounded, size: 13, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    roleCompany.isNotEmpty ? roleCompany : (member.role ?? member.company ?? 'Alumni'),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightPlaceholder(ThemePalette colors) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: colors.background,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 100, color: colors.background),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 60, color: colors.background),
                  ],
                ),
              ),
            ],
          ),
          Container(height: 10, width: 180, color: colors.background),
          Container(height: 10, width: 140, color: colors.background),
        ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'chat_detail_screen.dart';
import 'edit_profile_dialog.dart';
import 'mentorship_screen.dart';
import 'send_chat_request_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final String? profileId;
  final Profile? initialProfile;
  final bool isSelf;

  const ProfileScreen({
    super.key,
    this.profileId,
    this.initialProfile,
    this.isSelf = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  Profile? _profile;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    // Check if self
    final isViewingSelf = widget.isSelf ||
        widget.profileId == null ||
        widget.profileId == 'me' ||
        (auth.user?.profile?.id != null && auth.user!.profile!.id == widget.profileId);

    if (widget.initialProfile != null && !isViewingSelf) {
      setState(() => _loading = false);
    }

    try {
      Profile fetched;
      if (isViewingSelf && token != null) {
        fetched = await _profileService.getMyProfile(token: token);
      } else if (widget.profileId != null) {
        fetched = await _profileService.getProfileById(widget.profileId!, token: token);
      } else if (_profile != null) {
        fetched = _profile!;
      } else {
        throw Exception('Profile ID not specified');
      }

      if (mounted) {
        setState(() {
          _profile = fetched;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_profile == null) {
          setState(() {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
            _loading = false;
          });
        }
      }
    }
  }

  void _handleChatAction(Profile profile) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.hasChat(profile.id)) {
      final conv = chatProvider.conversations.firstWhere((c) => c.participantId == profile.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conv.id,
            participantId: profile.id,
            participantName: profile.displayName,
            participantRole: profile.currentRole,
            participantCompany: profile.company,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => SendChatRequestDialog(recipient: profile),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final isSelf = widget.isSelf ||
        (auth.user?.profile?.id != null && auth.user!.profile!.id == _profile?.id);

    if (_loading && _profile == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('User Profile'),
          actions: const [CommonAppBarActions()],
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (_errorMessage != null && _profile == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('User Profile'),
          actions: const [CommonAppBarActions()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_rounded, size: 56, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Profile Not Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchProfile,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _profile!;
    final initials = p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'N';

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.8),
                      colors.accent.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.school_rounded,
                        size: 180,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      right: 20,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: colors.surface,
                              backgroundImage: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                  ? NetworkImage(p.imageUrl!)
                                  : null,
                              child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                                  ? Text(
                                      initials,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.displayName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (p.openToMentor)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent.shade700,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'MENTOR',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (p.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    p.subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (p.location != null && p.location!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 13,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          p.country != null && p.country!.isNotEmpty
                                              ? '${p.location!}, ${p.country!}'
                                              : p.location!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (isSelf)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit Profile',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => EditProfileDialog(
                        currentProfile: p,
                        onSaved: _fetchProfile,
                      ),
                    );
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share Profile',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sharing ${p.displayName}\'s profile link')),
                    );
                  },
                ),
              const CommonAppBarActions(),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Action Buttons for other members
                  if (!isSelf) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                            label: const Text('Start Chat'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _handleChatAction(p),
                          ),
                        ),
                        if (p.openToMentor) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.school_rounded, size: 18),
                              label: const Text('Request Mentor'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MentorshipScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // School & Batch Card
                  _buildSectionCard(
                    title: 'JNV School & Batch',
                    icon: Icons.school_outlined,
                    colors: colors,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.jnv != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.account_balance_rounded, color: colors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.jnv!.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (p.jnv!.distt.isNotEmpty)
                                      Text(
                                        'District: ${p.jnv!.distt}${p.jnv!.state != null && p.jnv!.state!.name.isNotEmpty ? ' • ${p.jnv!.state!.name}' : ''}',
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (p.batch != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_edu_rounded, size: 16, color: colors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Batch of ${p.batch!.displayName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mentorship Status Card
                  if (p.openToMentor) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: colors.success, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Open to Mentoring Navodayans',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ready to offer career guidance, resume reviews, and industry insights.',
                                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // About / Bio Card
                  if (p.bio != null && p.bio!.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'About',
                      icon: Icons.person_outline_rounded,
                      colors: colors,
                      child: Text(
                        p.bio!,
                        style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Professional Experience & Domain
                  if ((p.currentRole != null && p.currentRole!.isNotEmpty) ||
                      (p.experience != null && p.experience!.isNotEmpty) ||
                      (p.industry != null && p.industry!.isNotEmpty)) ...[
                    _buildSectionCard(
                      title: 'Professional Experience',
                      icon: Icons.work_outline_rounded,
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.currentRole != null && p.currentRole!.isNotEmpty)
                            _buildInfoRow(
                              'Role',
                              p.currentRole!,
                              colors,
                              icon: Icons.badge_outlined,
                            ),
                          if (p.company != null && p.company!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              'Company',
                              p.company!,
                              colors,
                              icon: Icons.business_rounded,
                            ),
                          ],
                          if (p.industry != null && p.industry!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              'Industry',
                              p.industry!,
                              colors,
                              icon: Icons.category_outlined,
                            ),
                          ],
                          if (p.experience != null && p.experience!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              'Experience',
                              p.experience!,
                              colors,
                              icon: Icons.timeline_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Skills Card
                  if (p.skills.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Skills & Expertise',
                      icon: Icons.stars_rounded,
                      colors: colors,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              skill.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ThemePalette colors,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemePalette colors, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

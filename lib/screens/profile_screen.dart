import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/coordinator_service.dart';
import '../services/dashboard_service.dart';
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
  final String? approvalId;
  final bool isApprovalReview;
  final ValueChanged<bool>? onApprovalDecided;

  const ProfileScreen({
    super.key,
    this.profileId,
    this.initialProfile,
    this.isSelf = false,
    this.approvalId,
    this.isApprovalReview = false,
    this.onApprovalDecided,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final DashboardService _dashboardService = DashboardService();
  final CoordinatorService _coordinatorService = CoordinatorService();
  Profile? _profile;
  bool _loading = true;
  String? _errorMessage;
  bool _isDecidingApproval = false;
  String? _approvalDecision;

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

    // If viewing self and we already have a cached profile in auth.user, populate immediately
    if (_profile == null && isViewingSelf && auth.user?.profile != null) {
      _profile = Profile.fromUserProfile(auth.user!.profile!);
      _loading = false;
      if (mounted) setState(() {});
    }

    if (widget.initialProfile != null && !isViewingSelf) {
      setState(() => _loading = false);
    }

    // If viewing self and not authenticated
    if (isViewingSelf && (!auth.isAuthenticated || token == null)) {
      if (mounted) {
        setState(() {
          if (_profile == null) {
            _errorMessage = 'AUTH_REQUIRED';
          }
          _loading = false;
        });
      }
      return;
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
          _errorMessage = null;
          _loading = false;
        });
      }
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');
      final isAuthError = errorStr.toLowerCase().contains('invalid or expired token') ||
          errorStr.toLowerCase().contains('unauthorized') ||
          errorStr.toLowerCase().contains('401') ||
          errorStr.toLowerCase().contains('no token provided');

      if (isAuthError && isViewingSelf) {
        auth.logout();
      }

      if (mounted) {
        if (_profile == null) {
          setState(() {
            _errorMessage = isAuthError ? 'SESSION_EXPIRED' : errorStr;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
          if (isAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session expired. Please log in again.')),
            );
          }
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
    final targetId = profile.effectiveUserId;
    if (chatProvider.hasChat(profile.id) || chatProvider.hasChat(targetId)) {
      final conv = chatProvider.conversations.firstWhere(
        (c) => c.participantId == profile.id || c.participantId == targetId,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conv.id,
            participantId: conv.participantId,
            participantName: conv.participantName,
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

  void _showAppreciateDialog(Profile p) {
    final noteController = TextEditingController();
    String selectedCategory = 'Mentorship';
    final categories = ['Mentorship', 'Volunteering', 'Guidance', 'Collaboration', 'General'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Appreciate ${p.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thank them for help or support. They will receive recognition points for your selected category.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setModalState(() => selectedCategory = val ?? 'Mentorship'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'e.g. Thanks for the insightful career guidance!',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _dashboardService.sendAppreciation(
                      recipientId: p.id,
                      category: selectedCategory,
                      note: noteController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Appreciation sent to ${p.displayName}!')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Failed to send appreciation: $e')),
                    );
                  }
                },
                child: const Text('Send Recognition'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportDialog(Profile p) {
    String selectedReason = 'Inappropriate content';
    final detailsController = TextEditingController();
    final reasons = [
      'Inappropriate content',
      'Harassment or abuse',
      'Spam or fake profile',
      'Other policy violation',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Report Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us what is wrong. Reports go directly to Navodayan admins for review.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) => RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r, style: const TextStyle(fontSize: 13)),
                      value: r,
                      groupValue: selectedReason,
                      onChanged: (val) => setModalState(() => selectedReason = val ?? r),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Additional details (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _dashboardService.reportMember(
                      targetUserId: p.id,
                      reason: selectedReason,
                      details: detailsController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. Admins will review promptly.')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $e')),
                    );
                  }
                },
                child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmBlockDialog(Profile p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${p.displayName}?'),
        content: const Text(
          'You will no longer receive connection requests, messages, or interaction from this member.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _dashboardService.blockUser(p.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked ${p.displayName}')),
                  );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block user: $e')),
                  );
                }
              }
            },
            child: const Text('Block Member', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprovalDecision(bool approve) async {
    final targetId = widget.approvalId ?? widget.profileId ?? _profile?.id ?? '';
    if (targetId.isEmpty) return;

    setState(() => _isDecidingApproval = true);

    try {
      await _coordinatorService.decideApproval(targetId, approve: approve);
      if (mounted) {
        setState(() {
          _isDecidingApproval = false;
          _approvalDecision = approve ? 'APPROVED' : 'REJECTED';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: approve ? Colors.green.shade800 : Colors.red.shade800,
            content: Text(
              approve
                  ? 'Registration successfully approved for ${_profile?.displayName ?? 'applicant'}!'
                  : 'Registration rejected for ${_profile?.displayName ?? 'applicant'}.',
            ),
          ),
        );
        widget.onApprovalDecided?.call(approve);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDecidingApproval = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Failed to update approval status: $e'),
          ),
        );
      }
    }
  }

  Widget _buildApprovalActionCard(ThemePalette colors, Profile p) {
    if (_approvalDecision != null) {
      final isApproved = _approvalDecision == 'APPROVED';
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isApproved ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isApproved ? Colors.green : Colors.redAccent),
        ),
        child: Row(
          children: [
            Icon(
              isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApproved ? Colors.green : Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isApproved ? 'Registration Approved' : 'Registration Rejected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isApproved ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isApproved
                        ? 'This alumnus has been verified and their account is now active.'
                        : 'This application was rejected.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordinator Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review this applicant\'s details and take approval action.',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDecidingApproval ? null : () => _handleApprovalDecision(false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDecidingApproval ? null : () => _handleApprovalDecision(true),
                  icon: _isDecidingApproval
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_isDecidingApproval ? 'Processing...' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final isSelf = widget.isSelf ||
        (auth.user?.profile?.id != null && auth.user!.profile!.id == _profile?.id);

    final bool showApprovalCard = !isSelf &&
        (widget.isApprovalReview ||
            widget.approvalId != null ||
            (_profile?.approvalStatus?.toUpperCase() == 'PENDING' && auth.user?.isCoordinator == true));

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
      final isSessionExpired = _errorMessage == 'SESSION_EXPIRED' ||
          _errorMessage!.toLowerCase().contains('invalid or expired token');
      final isAuthRequired = _errorMessage == 'AUTH_REQUIRED';

      IconData errorIcon = Icons.person_off_rounded;
      Color iconColor = colors.error;
      String errorTitle = 'Profile Not Found';
      String errorSubtitle = _errorMessage!;
      String buttonText = 'Try Again';
      VoidCallback onButtonPressed = _fetchProfile;

      if (isSessionExpired) {
        errorIcon = Icons.lock_clock_outlined;
        iconColor = colors.secondary;
        errorTitle = 'Session Expired';
        errorSubtitle = 'Your login session has expired. Please sign in again to view and manage your profile.';
        buttonText = 'Sign In Again';
        onButtonPressed = () {
          Navigator.pushNamed(context, '/login').then((_) => _fetchProfile());
        };
      } else if (isAuthRequired) {
        errorIcon = Icons.account_circle_outlined;
        iconColor = colors.primary;
        errorTitle = 'Sign In Required';
        errorSubtitle = 'Please sign in to view and manage your Navodayan alumni profile.';
        buttonText = 'Sign In';
        onButtonPressed = () {
          Navigator.pushNamed(context, '/login').then((_) => _fetchProfile());
        };
      }

      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(isSelf ? 'My Profile' : 'User Profile'),
          actions: const [CommonAppBarActions()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(errorIcon, size: 56, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  errorTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  errorSubtitle,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(buttonText),
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
              else ...[
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share Profile',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sharing ${p.displayName}\'s profile link')),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'appreciate') {
                      _showAppreciateDialog(p);
                    } else if (value == 'report') {
                      _showReportDialog(p);
                    } else if (value == 'block') {
                      _confirmBlockDialog(p);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'appreciate',
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
                          SizedBox(width: 10),
                          Text('Appreciate / Recognize'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, color: Colors.orange, size: 18),
                          SizedBox(width: 10),
                          Text('Report Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded, color: Colors.red, size: 18),
                          SizedBox(width: 10),
                          Text('Block Member'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const CommonAppBarActions(),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Coordinator Approval Action Card
                  if (showApprovalCard)
                    _buildApprovalActionCard(colors, p),

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
                        if (p.isJnvVerified) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: colors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'JNV verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colors.success,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '· confirmed by coordinator or admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          Row(
                            children: [
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
                                      p.association?.toLowerCase() == 'teacher' || p.association?.toLowerCase() == 'staff'
                                          ? 'Joined ${p.batch!.startYear}'
                                          : 'Batch of ${p.batch!.displayName}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (p.postingStatus != null && p.postingStatusLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    p.postingStatusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Privacy & Contact Visibility Card for Self
                  if (isSelf) ...[
                    _buildSectionCard(
                      title: 'Privacy & Contact Visibility',
                      icon: Icons.lock_outline_rounded,
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVisibilityRow('Profile', p.profileVisibility == 'JNV' ? 'My JNV only' : 'Anyone on Navodayan', colors),
                          const SizedBox(height: 8),
                          _buildVisibilityRow('Email', p.emailVisibility == 'NONE' ? 'Nobody' : (p.emailVisibility == 'JNV' ? 'My JNV only' : 'Anyone on Navodayan'), colors),
                          const SizedBox(height: 8),
                          _buildVisibilityRow('Phone', p.phoneVisibility == 'NONE' ? 'Nobody' : (p.phoneVisibility == 'JNV' ? 'My JNV only' : 'Anyone on Navodayan'), colors),
                          const SizedBox(height: 12),
                          Text(
                            'Admin and your JNV coordinators can still reach you for school work.',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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

  Widget _buildVisibilityRow(String label, String value, ThemePalette colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mentorship_request.dart';
import '../models/profile.dart';
import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/mentorship_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'profile_screen.dart';

class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key});

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  final MentorshipService _mentorshipService = MentorshipService();
  final _searchController = TextEditingController();

  int _selectedTab = 0; // 0: Browse Mentors, 1: My Dashboard
  String _selectedIndustry = 'All';
  final List<String> _industries = [
    'All',
    'Technology',
    'Finance',
    'Healthcare',
    'Education',
    'Engineering',
    'Consulting',
    'Civil Services',
  ];

  List<Profile> _mentors = [];
  List<MentorshipRequest> _requests = [];
  bool _loadingMentors = true;
  bool _loadingRequests = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMentors();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMentors() async {
    setState(() {
      _loadingMentors = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final mentors = await _mentorshipService.getMentors(token: token);
      if (mounted) {
        setState(() {
          _mentors = mentors;
          _loadingMentors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loadingMentors = false;
        });
      }
    }
  }

  Future<void> _fetchRequests() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    setState(() => _loadingRequests = true);
    try {
      final reqs = await _mentorshipService.getMentorshipRequests(token: token);
      if (mounted) {
        setState(() {
          _requests = reqs;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRequests = false);
      }
    }
  }

  Future<void> _handleUpdateStatus(String requestId, String status) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _mentorshipService.updateRequestStatus(
        requestId: requestId,
        status: status,
        token: token,
      );
      _fetchRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showRequestModal(Profile mentor) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to request mentorship')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SendRequestDialog(
        mentor: mentor,
        onRequestSent: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request sent to ${mentor.displayName}!')),
          );
        },
      ),
    );
  }

  List<Profile> get _filteredMentors {
    final query = _searchController.text.trim().toLowerCase();
    return _mentors.where((m) {
      final matchesQuery = query.isEmpty ||
          m.fullName.toLowerCase().contains(query) ||
          (m.currentRole?.toLowerCase().contains(query) ?? false) ||
          (m.company?.toLowerCase().contains(query) ?? false) ||
          (m.location?.toLowerCase().contains(query) ?? false);

      final matchesIndustry = _selectedIndustry == 'All' ||
          (m.industry?.toLowerCase() == _selectedIndustry.toLowerCase());

      return matchesQuery && matchesIndustry;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Mentorship Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (_selectedTab == 0) {
                _fetchMentors();
              } else {
                _fetchRequests();
              }
            },
          ),
          const CommonAppBarActions(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedTab == 0) {
            await _fetchMentors();
          } else {
            await _fetchRequests();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mentorship Header Card (matches mentorship_redesigned/code.html)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFF152A5C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF152A5C).withValues(alpha: isDark ? 0.35 : 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school, size: 16, color: Color(0xFF93C5FD)),
                            SizedBox(width: 6),
                            Text(
                              'Alumni Mentorship',
                              style: TextStyle(
                                color: Color(0xFFDBEAFE),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '1-on-1 Guidance',
                          style: TextStyle(
                            color: const Color(0xFF93C5FD).withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Navodayan Mentorship',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connect with senior alumni for career advice, competitive exam tips, and professional guidance.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFDBEAFE),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Tabs: Browse Mentors / My Dashboard
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF162A5C))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Browse Mentors',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : colors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!auth.isAuthenticated) {
                            Navigator.pushNamed(context, '/login');
                            return;
                          }
                          setState(() => _selectedTab = 1);
                          _fetchRequests();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF162A5C))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'My Dashboard',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : colors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_selectedTab == 0)
                _buildBrowseMentorsView()
              else
                _buildDashboardView(auth),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseMentorsView() {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredMentors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search and Industry filters
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search mentors by name, role, company...',
              hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: colors.textSecondary, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _industries.map((ind) {
              final isSelected = _selectedIndustry == ind;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedIndustry = ind),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFCCD5E4))
                          : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : colors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Text(
                            '✓ ',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF132857),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        Text(
                          ind,
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF132857))
                                : colors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        if (_loadingMentors)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: colors.error),
              textAlign: TextAlign.center,
            ),
          )
        else if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.people_outline_rounded, size: 48, color: colors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'No Mentors Found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try modifying your search or industry filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) => _buildMentorCard(filtered[i]),
          ),
          const SizedBox(height: 32),

          // How Mentorship Works Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text(
                  'How Mentorship Works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStep(
                  '1',
                  'Find a Mentor',
                  'Browse through profiles based on industry, role, and experience.',
                ),
                const SizedBox(height: 16),
                _buildStep(
                  '2',
                  'Send Request',
                  'Briefly introduce yourself and what guidance you are seeking.',
                ),
                const SizedBox(height: 16),
                _buildStep(
                  '3',
                  'Connect & Grow',
                  'Once approved, connect directly via email and start your journey.',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep(String num, String title, String desc) {
    final colors = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMentorCard(Profile mentor) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = mentor.fullName.isNotEmpty ? mentor.fullName[0].toUpperCase() : 'N';

    return Container(
      padding: const EdgeInsets.all(16),
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
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    initialProfile: mentor,
                    profileId: mentor.id,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF162955),
                  backgroundImage: (mentor.imageUrl != null && mentor.imageUrl!.isNotEmpty)
                      ? NetworkImage(mentor.imageUrl!)
                      : null,
                  child: (mentor.imageUrl == null || mentor.imageUrl!.isEmpty)
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mentor.subtitle.isNotEmpty
                            ? mentor.subtitle
                            : (mentor.currentRole ?? 'Alumnus'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mentor.industry != null && mentor.industry!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162A5C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mentor.industry!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF162A5C),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (mentor.bio != null && mentor.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              mentor.bio!,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.35),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (mentor.schoolAndBatch.isNotEmpty || (mentor.location != null && mentor.location!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (mentor.schoolAndBatch.isNotEmpty) ...[
                  const Text('🎓', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mentor.schoolAndBatch,
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (mentor.location != null && mentor.location!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Text('📍', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    mentor.location!,
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _showRequestModal(mentor),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFF162A5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 15),
                  SizedBox(width: 8),
                  Text(
                    'Request Mentorship',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(AuthProvider auth) {
    final colors = AppColors.of(context);

    if (_loadingRequests) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final myProfileId = auth.user?.profile?.id;
    final received = _requests.where((r) => r.mentorId == myProfileId).toList();
    final sent = _requests.where((r) => r.requesterId == myProfileId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Requests Received
        Text(
          'Requests Received',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (received.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                'No mentorship requests received yet.',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: received.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildReceivedCard(received[i]),
          ),
        const SizedBox(height: 28),

        // Requests Sent
        Text(
          'Requests Sent',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (sent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                "You haven't sent any mentorship requests yet.",
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sent.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildSentCard(sent[i]),
          ),
      ],
    );
  }

  Widget _buildReceivedCard(MentorshipRequest req) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.requester?.fullName ?? 'Navodayan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          if (req.requester?.batchYear != null) ...[
            const SizedBox(height: 2),
            Text(
              'Batch of ${req.requester!.batchYear}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Text(
              '"${req.message}"',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: colors.textPrimary),
            ),
          ),
          if (req.status == MentorshipStatus.accepted && req.requester?.user?.email != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: colors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.requester!.user!.email,
                      style: TextStyle(
                        color: colors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (req.status == MentorshipStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleUpdateStatus(req.id, 'ACCEPTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleUpdateStatus(req.id, 'REJECTED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentCard(MentorshipRequest req) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.mentor?.fullName ?? 'Mentor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          if (req.mentor?.currentRole != null) ...[
            const SizedBox(height: 2),
            Text(
              req.mentor!.currentRole!,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Message: ${req.message}',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          if (req.status == MentorshipStatus.accepted && req.mentor?.user?.email != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.mentor!.user!.email,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MentorshipStatus status) {
    final colors = AppColors.of(context);
    Color bg;
    Color text;
    String label;

    switch (status) {
      case MentorshipStatus.accepted:
        bg = colors.success.withValues(alpha: 0.15);
        text = colors.success;
        label = 'ACCEPTED';
        break;
      case MentorshipStatus.rejected:
        bg = colors.error.withValues(alpha: 0.15);
        text = colors.error;
        label = 'REJECTED';
        break;
      case MentorshipStatus.pending:
        bg = colors.secondary.withValues(alpha: 0.15);
        text = colors.secondary;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

class _SendRequestDialog extends StatefulWidget {
  final Profile mentor;
  final VoidCallback onRequestSent;

  const _SendRequestDialog({
    required this.mentor,
    required this.onRequestSent,
  });

  @override
  State<_SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<_SendRequestDialog> {
  final _messageController = TextEditingController();
  final MentorshipService _mentorshipService = MentorshipService();

  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    setState(() => _submitting = true);

    try {
      final token = context.read<AuthProvider>().token!;
      await _mentorshipService.sendMentorshipRequest(
        mentorId: widget.mentor.id,
        message: msg,
        token: token,
      );

      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Mentorship Request Sent',
          body: 'Your mentorship request was sent to ${widget.mentor.displayName}. You will receive an update once reviewed.',
          type: NotificationType.mentorshipRequest,
          data: {'mentorId': widget.mentor.id, 'mentorName': widget.mentor.displayName},
          showPush: true,
        );
        Navigator.pop(context);
        widget.onRequestSent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Connect with ${widget.mentor.displayName}',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "👋 Introduce yourself and briefly explain why you're seeking mentorship.",
                  style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  hintText: "Hi, I'm interested in your career path...",
                  alignLabelWithHint: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _handleSend,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

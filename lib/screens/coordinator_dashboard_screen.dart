import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coordinator.dart';
import '../providers/auth_provider.dart';
import '../services/coordinator_service.dart';
import '../theme/app_theme.dart';

class CoordinatorDashboardScreen extends StatefulWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  State<CoordinatorDashboardScreen> createState() => _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState extends State<CoordinatorDashboardScreen> with SingleTickerProviderStateMixin {
  final CoordinatorService _service = CoordinatorService();
  late TabController _tabController;

  CoordinatorContext? _context;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _approvals = [];
  Map<String, dynamic>? _contributionReviews;
  List<CoordinatorFeedback> _feedbacks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ctx = await _service.getContext();
      final members = await _service.getMembers();
      final approvals = await _service.getApprovals();
      final reviews = await _service.getContributionReviews();
      final feedbacks = await _service.getFeedback();

      if (mounted) {
        setState(() {
          _context = ctx;
          _members = members;
          _approvals = approvals;
          _contributionReviews = reviews;
          _feedbacks = feedbacks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load coordinator portal.';
          _isLoading = false;
        });
      }
    }
  }

  void _showSubmitFeedbackDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'ISSUE';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final colors = AppColors.of(context);
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Submit Coordinator Feedback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Feedback Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ISSUE', child: Text('Issue / Bug Report')),
                      DropdownMenuItem(value: 'FEATURE_REQUEST', child: Text('Feature Request')),
                      DropdownMenuItem(value: 'DATA_CORRECTION', child: Text('Data Correction')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Subject / Title',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Brief title of the issue or idea',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detailed Description',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Provide details for the administration team to review...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final desc = descController.text.trim();
                            if (title.isEmpty || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill in title and description')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.submitFeedback(
                                type: selectedType,
                                title: title,
                                description: desc,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Feedback submitted for admin review!')),
                                );
                                _loadAll();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to submit feedback: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit to Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final viewing = _context?.viewing;
    final scopeLabel = viewing?.scopeLabel ?? viewing?.jnvName ?? 'JNV School Assignment';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Coordinator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Members (${_members.length})'),
            Tab(text: 'Approvals (${_approvals.length})'),
            const Tab(text: 'Reviews'),
            Tab(text: 'Feedback (${_feedbacks.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: TextStyle(color: colors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadAll, child: const Text('Try Again')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(colors, auth, scopeLabel),
                    _buildMembersTab(colors),
                    _buildApprovalsTab(colors),
                    _buildReviewsTab(colors),
                    _buildFeedbackTab(colors),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitFeedbackDialog,
        icon: const Icon(Icons.feedback_outlined),
        label: const Text('Submit Feedback'),
      ),
    );
  }

  Widget _buildOverviewTab(ThemePalette colors, AuthProvider auth, String scopeLabel) {
    final features = _context?.features ?? const CoordinatorFeatures();
    final ctx = _context ?? const CoordinatorContext();

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${auth.user?.profile?.fullName ?? "Coordinator"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              scopeLabel,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Level: ${ctx.viewing.level ?? "COORDINATOR"}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'COORDINATOR CAPABILITIES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            _buildCapabilityTile(
              colors,
              title: 'Member Directory Access',
              desc: 'View alumni in your assigned batch, school, or state',
              enabled: features.members,
              icon: Icons.people_alt_rounded,
            ),
            const SizedBox(height: 10),
            _buildCapabilityTile(
              colors,
              title: 'Membership Approvals',
              desc: 'Review and approve newly registered school alumni',
              enabled: features.membershipApprovals && ctx.canApproveMembers,
              icon: Icons.verified_user_rounded,
            ),
            const SizedBox(height: 10),
            _buildCapabilityTile(
              colors,
              title: 'Contribution Reviews',
              desc: 'Verify financial donations and volunteer hours',
              enabled: features.contributions && ctx.canReviewContributions,
              icon: Icons.volunteer_activism_rounded,
            ),
            const SizedBox(height: 10),
            _buildCapabilityTile(
              colors,
              title: 'Batch Coordinators Management',
              desc: 'Invite and manage coordinators for your school batches',
              enabled: ctx.canManageBatchCoordinators,
              icon: Icons.supervisor_account_rounded,
            ),
            const SizedBox(height: 10),
            _buildCapabilityTile(
              colors,
              title: 'Feedback Channel',
              desc: 'Submit enhancements and bug reports directly to admins',
              enabled: features.feedback,
              icon: Icons.mark_chat_read_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityTile(
    ThemePalette colors, {
    required String title,
    required String desc,
    required bool enabled,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: enabled ? colors.primary.withValues(alpha: 0.1) : colors.textSecondary.withValues(alpha: 0.1),
            child: Icon(icon, color: enabled ? colors.primary : colors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 20,
            color: enabled ? colors.success : colors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(ThemePalette colors) {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No members in assigned scope',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Verified alumni from your school or batch will appear here',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = _members[index];
        final name = m['fullName'] ?? m['email'] ?? 'Member';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    if (m['role'] != null) Text(m['role'], style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovalsTab(ThemePalette colors) {
    if (_approvals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No pending approvals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'New alumni registration requests will appear here for verification',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _approvals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _approvals[index];
        final id = item['id']?.toString() ?? '';
        final name = item['fullName'] ?? item['email'] ?? 'Alumni Applicant';

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
              Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              if (item['email'] != null) ...[
                const SizedBox(height: 2),
                Text(item['email'], style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await _service.decideApproval(id, approve: false);
                      _loadAll();
                    },
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _service.decideApproval(id, approve: true);
                      _loadAll();
                    },
                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(ThemePalette colors) {
    final reviews = _contributionReviews ?? {};
    final financial = (reviews['financial'] as List<dynamic>?) ?? [];
    final physical = (reviews['physical'] as List<dynamic>?) ?? [];
    final totalHours = reviews['hoursVerified'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.verified_rounded, color: colors.primary),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Verified Volunteer Hours',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    Text(
                      '$totalHours Hours',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PENDING CONTRIBUTIONS TO REVIEW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (financial.isEmpty && physical.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Text(
                  'No pending contributions awaiting review at this time.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab(ThemePalette colors) {
    if (_feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No feedback submitted yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Share suggestions, bugs, or enhancement requests with the portal team',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showSubmitFeedbackDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Submit Feedback'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _feedbacks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fb = _feedbacks[index];
        final isInProgress = fb.status == 'IN_PROGRESS';
        final isResolved = fb.status == 'RESOLVED';

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
                  Expanded(
                    child: Text(
                      fb.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isInProgress
                          ? Colors.blue.withValues(alpha: 0.12)
                          : isResolved
                              ? colors.success.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fb.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isInProgress
                            ? Colors.blue
                            : isResolved
                                ? colors.success
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                fb.description,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${fb.type}',
                style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
              ),
            ],
          ),
        );
      },
    );
  }
}

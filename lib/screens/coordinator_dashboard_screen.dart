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
  String? _approvalsMessage;
  List<Map<String, dynamic>> _coordinatorEvents = [];
  Map<String, dynamic>? _contributionReviews;
  Map<String, dynamic>? _campaignsData;
  Map<String, dynamic>? _batchCoordinatorsData;
  List<CoordinatorFeedback> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getContext().catchError((e) {
          debugPrint('getContext error: $e');
          return const CoordinatorContext();
        }),
        _service.getMembers().catchError((e) {
          debugPrint('getMembers error: $e');
          return <Map<String, dynamic>>[];
        }),
        _service.getApprovalsData().catchError((e) {
          debugPrint('getApprovalsData error: $e');
          return {'items': <Map<String, dynamic>>[], 'message': e.toString().replaceAll('Exception: ', '')};
        }),
        _service.getCoordinatorEvents().catchError((e) {
          debugPrint('getCoordinatorEvents error: $e');
          return <Map<String, dynamic>>[];
        }),
        _service.getContributionReviews().catchError((e) {
          debugPrint('getContributionReviews error: $e');
          return {'hoursVerified': 0, 'financial': [], 'physical': []};
        }),
        _service.getCampaigns().catchError((e) {
          debugPrint('getCampaigns error: $e');
          return {'campaigns': []};
        }),
        _service.getBatchCoordinatorsData().catchError((e) {
          debugPrint('getBatchCoordinatorsData error: $e');
          return {'coordinators': []};
        }),
        _service.getFeedback().catchError((e) {
          debugPrint('getFeedback error: $e');
          return <CoordinatorFeedback>[];
        }),
      ]);

      if (mounted) {
        final approvalsMap = results[2] as Map<String, dynamic>;
        setState(() {
          _context = results[0] as CoordinatorContext;
          _members = results[1] as List<Map<String, dynamic>>;
          _approvals = (approvalsMap['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          _approvalsMessage = approvalsMap['message'] as String?;
          _coordinatorEvents = results[3] as List<Map<String, dynamic>>;
          _contributionReviews = results[4] as Map<String, dynamic>;
          _campaignsData = results[5] as Map<String, dynamic>;
          _batchCoordinatorsData = results[6] as Map<String, dynamic>;
          _feedbacks = results[7] as List<CoordinatorFeedback>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _context ??= const CoordinatorContext();
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
                        'Submit Feedback to Admin',
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
                    'Category',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'ISSUE', child: Text('Bug or System Issue')),
                      DropdownMenuItem(value: 'FEATURE', child: Text('Feature Request')),
                      DropdownMenuItem(value: 'GENERAL', child: Text('General Feedback')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Subject',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Brief summary of your feedback...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Provide complete details for admin review...',
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
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    bool isOnline = false;
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
                        'Create Coordinator Event',
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
                    'Event Title',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. JNV Alumni Reunion or Mentorship Meet',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Event agenda and details...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Location / Venue',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. School Campus or Online Google Meet',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Checkbox(
                        value: isOnline,
                        onChanged: (val) => setModalState(() => isOnline = val ?? false),
                      ),
                      Text('Online Virtual Event', style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter an event title')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.createCoordinatorEvent({
                                'title': title,
                                'description': descController.text.trim(),
                                'location': locationController.text.trim().isNotEmpty
                                    ? locationController.text.trim()
                                    : (isOnline ? 'Online' : 'School Campus'),
                                'isOnline': isOnline,
                                'startDate': selectedDate.toIso8601String(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Event published successfully!')),
                                );
                                _loadAll();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to create event: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Publish Event', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInviteCoordinatorDialog() {
    final emailController = TextEditingController();
    final batchController = TextEditingController();
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
                        'Invite Batch Coordinator',
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
                    'Alumni Email',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'alumni@example.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Batch Year (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: batchController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2018',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter an email address')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              final bYear = int.tryParse(batchController.text.trim());
                              await _service.inviteBatchCoordinator(email, batchId: bYear);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coordinator invitation sent!')),
                                );
                                _loadAll();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to invite: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final scopeLabel = viewing?.scopeLabel ?? viewing?.jnvName ?? 'JNV Coordinator Scope';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Coordinator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
            Tab(text: 'Events (${_coordinatorEvents.length})'),
            const Tab(text: 'Contributions'),
            const Tab(text: 'Batch Coordinators'),
            Tab(text: 'Feedback (${_feedbacks.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(colors, auth, scopeLabel),
                _buildMembersTab(colors),
                _buildApprovalsTab(colors),
                _buildEventsTab(colors),
                _buildContributionsTab(colors),
                _buildBatchCoordinatorsTab(colors),
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

  // TAB 1: OVERVIEW (Exact text content from the web coordinator portal)
  Widget _buildOverviewTab(ThemePalette colors, AuthProvider auth, String scopeLabel) {
    final name = auth.user?.profile?.fullName ?? 'Coordinator';

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Welcome Header
            Text(
              'Hello, $name',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scopeLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Main Overview Card matching Web Dashboard
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to your Coordinator Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use the sidebar for the pages enabled for your coordinator assignment. An admin can change this under Feature access.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),
                  Text(
                    'Coordinator Portal Features:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint(
                    colors,
                    'View members in your assigned batch, school, state, country, or national list.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'Update login email for members shown on your Members page.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'Approve or reject verified members in your assignment.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'Create and manage community events.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'Broadcast announcements to members in your scope.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'Record contributions and verify member money and hours logs.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'See, invite, and revoke batch coordinators for this JNV.',
                  ),
                  _buildBulletPoint(
                    colors,
                    'Submit feedback or enhancement requests for admin to review.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(ThemePalette colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: MEMBERS
  Widget _buildMembersTab(ThemePalette colors) {
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 56, color: colors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'Members in your assignment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Verified alumni from your school or batch will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
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
        final email = m['email']?.toString() ?? '';
        final batch = m['batchYear']?.toString() ?? m['batch']?.toString();
        final role = m['role']?.toString() ?? 'Alumni';

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
                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(role, style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold)),
                        ),
                        if (batch != null && batch.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('Batch: $batch', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: APPROVALS
  Widget _buildApprovalsTab(ThemePalette colors) {
    if (_approvalsMessage != null && _approvalsMessage!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, size: 40, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'Coordinator Scope Assignment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _approvalsMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    if (_approvals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                'New alumni registration requests will appear here for verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
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
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _service.decideApproval(id, approve: true);
                      _loadAll();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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

  // TAB 4: EVENTS (Create events and list created events)
  Widget _buildEventsTab(ThemePalette colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: colors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coordinator Events',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  Text(
                    'Manage events for your JNV scope',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showCreateEventDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _coordinatorEvents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_outlined, size: 56, color: colors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No Coordinator Events Created',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Create Event" to schedule an alumni meetup, school activity, or reunion.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _showCreateEventDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create First Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _coordinatorEvents.length,
                  itemBuilder: (context, index) {
                    final ev = _coordinatorEvents[index];
                    final title = ev['title']?.toString() ?? 'Event';
                    final desc = ev['description']?.toString() ?? '';
                    final location = ev['location']?.toString() ?? 'School';
                    final date = ev['startDate']?.toString() ?? '';

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
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(desc, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: colors.textSecondary),
                              const SizedBox(width: 4),
                              Text(location, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              if (date.isNotEmpty) ...[
                                const SizedBox(width: 14),
                                Icon(Icons.calendar_today_outlined, size: 14, color: colors.textSecondary),
                                const SizedBox(width: 4),
                                Text(date.substring(0, date.length > 10 ? 10 : date.length),
                                    style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                ),
        ),
      ],
    );
  }

  // TAB 5: CONTRIBUTIONS
  Widget _buildContributionsTab(ThemePalette colors) {
    final reviews = _contributionReviews ?? {};
    final financial = (reviews['financial'] as List<dynamic>?) ?? [];
    final physical = (reviews['physical'] as List<dynamic>?) ?? [];
    final totalHours = reviews['hoursVerified'] ?? 0;
    final campaigns = (_campaignsData?['campaigns'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verified Hours Card
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

            // Campaigns Section
            Text(
              'SCHOOL CAMPAIGNS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            if (campaigns.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Text(
                    'No active contribution campaigns created for this scope.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...campaigns.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(c['title']?.toString() ?? 'Campaign', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  )),

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
            const SizedBox(height: 10),
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
      ),
    );
  }

  // TAB 6: BATCH COORDINATORS
  Widget _buildBatchCoordinatorsTab(ThemePalette colors) {
    final coordinators = (_batchCoordinatorsData?['coordinators'] as List<dynamic>?) ?? [];
    final error = _batchCoordinatorsData?['error'] as String?;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: colors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Coordinators',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  Text(
                    'Manage coordinators across batches',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showInviteCoordinatorDialog,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Invite Coordinator'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: error != null && error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded, size: 40, color: Colors.orange),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Batch Coordinator Scope',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : coordinators.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.supervisor_account_outlined, size: 56, color: colors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'No Batch Coordinators Assigned',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Invite alumni to coordinate specific batches for this JNV school.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: colors.textSecondary),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _showInviteCoordinatorDialog,
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Invite Batch Coordinator'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: coordinators.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = coordinators[index];
                        final name = c['fullName'] ?? c['email'] ?? 'Batch Coordinator';
                        final batch = c['batchYear']?.toString() ?? c['batch']?.toString() ?? '';

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
                                  name.isNotEmpty ? name[0].toUpperCase() : 'B',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                    if (batch.isNotEmpty) Text('Batch $batch', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // TAB 7: FEEDBACK (Create and list all previously created feedback)
  Widget _buildFeedbackTab(ThemePalette colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: colors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coordinator Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  Text(
                    'Share feedback and feature requests with admins',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showSubmitFeedbackDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _feedbacks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
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
                          'Submit feedback, suggestions, or issues directly to the portal team.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _showSubmitFeedbackDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Submit Feedback'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
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
                            'Category: ${fb.type}',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

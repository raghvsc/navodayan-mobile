import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contribution.dart';
import '../providers/auth_provider.dart';
import '../services/contributions_service.dart';
import '../theme/app_theme.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> with SingleTickerProviderStateMixin {
  final ContributionsService _service = ContributionsService();
  late TabController _tabController;

  ContributionsData? _data;
  List<ContributionCampaign> _campaigns = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getContributions(),
        _service.getCampaigns(),
      ]);

      if (mounted) {
        setState(() {
          _data = results[0] as ContributionsData;
          _campaigns = results[1] as List<ContributionCampaign>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data ??= const ContributionsData();
          _campaigns = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showLogFinancialDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedCampaignId;
    if (_campaigns.isNotEmpty) {
      selectedCampaignId = _campaigns.first.id;
    }
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
                        'Log Financial Contribution',
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
                  if (_campaigns.isNotEmpty) ...[
                    Text(
                      'Select Campaign (Optional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCampaignId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _campaigns.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedCampaignId = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Amount (₹)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 5000',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note / Reference (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. For computer lab refurbishment',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final amount = num.tryParse(amountController.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid contribution amount')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logFinancialContribution(
                                campaignId: selectedCampaignId,
                                amount: amount,
                                note: noteController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Contribution logged successfully!')),
                                );
                                _loadData();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to log contribution: $e')),
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
                        : const Text('Submit Contribution', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogHoursDialog() {
    final hoursController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'MENTORING';
    final types = [
      {'key': 'MENTORING', 'label': 'Mentoring Students'},
      {'key': 'TEACHING', 'label': 'Guest Lecture / Teaching'},
      {'key': 'EVENT', 'label': 'Event Organization'},
      {'key': 'CAMPUS_VISIT', 'label': 'Campus Visit & Guidance'},
      {'key': 'OTHER', 'label': 'Other Volunteering'},
    ];
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
                        'Log Volunteer Hours',
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
                    'Activity Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: types.map((t) {
                      return DropdownMenuItem(
                        value: t['key'],
                        child: Text(t['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hours Spent',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 4',
                      prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description / Highlights',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'What did you do with students or alumni?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final hours = num.tryParse(hoursController.text.trim());
                            if (hours == null || hours <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter valid hours')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logPhysicalContribution(
                                type: selectedType,
                                hours: hours,
                                description: descController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Volunteer hours logged successfully!')),
                                );
                                _loadData();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to log hours: $e')),
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
                        : const Text('Submit Hours', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Contributions & Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Financial'),
            Tab(text: 'Volunteer Hours'),
            Tab(text: 'Campaigns'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(colors, auth),
                    _buildFinancialTab(colors),
                    _buildPhysicalTab(colors),
                    _buildCampaignsTab(colors),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.currency_rupee_rounded, color: Colors.white),
                    ),
                    title: const Text('Log Financial Contribution', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Donate or record financial support to JNV projects'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showLogFinancialDialog();
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF3B82F6),
                      child: Icon(Icons.volunteer_activism_rounded, color: Colors.white),
                    ),
                    title: const Text('Log Volunteer Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Record mentoring, teaching or on-campus hours'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showLogHoursDialog();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Contribution'),
      ),
    );
  }

  Widget _buildOverviewTab(ThemePalette colors, AuthProvider auth) {
    final summary = _data?.summary ?? const ContributionSummary();
    final schoolName = _data?.jnvName ?? 'Your JNV';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // School Context Banner
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
                      const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schoolName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supporting alumni, current students, and school infrastructure development through collective Navodayan contributions.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'CONTRIBUTION SUMMARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    colors,
                    title: 'Verified Funds',
                    value: '₹${summary.verifiedMoney}',
                    icon: Icons.check_circle_outline_rounded,
                    color: colors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    colors,
                    title: 'Verified Hours',
                    value: '${summary.verifiedHours} hrs',
                    icon: Icons.timer_outlined,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    colors,
                    title: 'Pending Verification',
                    value: '₹${summary.pendingMoney}',
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    colors,
                    title: 'Pending Hours',
                    value: '${summary.pendingHours} hrs',
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showLogFinancialDialog,
                    icon: const Icon(Icons.currency_rupee_rounded, size: 18),
                    label: const Text('Donate Funds'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLogHoursDialog,
                    icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                    label: const Text('Log Hours'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    ThemePalette colors, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
                title,
                style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab(ThemePalette colors) {
    final list = _data?.financial ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No financial contributions recorded yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Make a donation to help support your JNV',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showLogFinancialDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record Contribution'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final isVerified = item.status == 'VERIFIED';
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
                backgroundColor: isVerified ? colors.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                child: Icon(
                  Icons.currency_rupee_rounded,
                  color: isVerified ? colors.success : Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${item.amount}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    if (item.campaignTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.campaignTitle!,
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.note != null) ...[
                      const SizedBox(height: 2),
                      Text(item.note!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? colors.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? colors.success : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhysicalTab(ThemePalette colors) {
    final list = _data?.physical ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No volunteer hours logged yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Give back by mentoring students or organizing events',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showLogHoursDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log Volunteer Hours'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final isVerified = item.status == 'VERIFIED';
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
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.timer_rounded, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.hours} Hours • ${item.type}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.description!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? colors.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? colors.success : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignsTab(ThemePalette colors) {
    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No active campaigns at this time',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'School campaigns will appear here when announced by coordinators',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _campaigns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final campaign = _campaigns[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              if (campaign.purpose != null) ...[
                const SizedBox(height: 4),
                Text(campaign.purpose!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ],
              if (campaign.description != null) ...[
                const SizedBox(height: 8),
                Text(campaign.description!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _showLogFinancialDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Contribute', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

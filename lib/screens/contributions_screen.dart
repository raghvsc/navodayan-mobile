import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/contribution.dart';
import '../providers/auth_provider.dart';
import '../services/contributions_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coordinator_contributions_view.dart';
import '../widgets/app_bar_actions.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> with SingleTickerProviderStateMixin {
  final ContributionsService _service = ContributionsService();
  TabController? _tabController;

  ContributionsData? _data;
  List<ContributionCampaign> _campaigns = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  void _initTabController(bool isCoordinator) {
    final length = isCoordinator ? 2 : 2;
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
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
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _data ??= const ContributionsData();
          _campaigns = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }

  // DIALOG: LOG MONEY (MEMBER)
  void _showLogMoneyDialog() {
    if (_campaigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open campaigns available right now. Ask your coordinator to create one.')),
      );
      return;
    }

    String selectedCampaignId = _campaigns.first.id;
    final amountController = TextEditingController();
    bool isCommitment = false;
    String selectedMode = 'UPI';
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController();
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
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        isCommitment ? 'Commit to Give Later' : 'Money Already Given',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCommitment
                        ? 'Record an amount you will give when this campaign needs it. Counted once transfer is verified.'
                        : 'Log money you have already sent to a campaign. The coordinator will verify it.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // TOGGLE: Money Already Given vs Commit to Give Later
                  Container(
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Money Sent')),
                            selected: !isCommitment,
                            onSelected: (val) {
                              if (val) setModalState(() => isCommitment = false);
                            },
                          ),
                        ),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Commit Later')),
                            selected: isCommitment,
                            onSelected: (val) {
                              if (val) setModalState(() => isCommitment = true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: selectedCampaignId,
                    decoration: const InputDecoration(labelText: 'Campaign *'),
                    items: _campaigns.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCampaignId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),

                  if (!isCommitment) ...[
                    DropdownButtonFormField<String>(
                      value: selectedMode,
                      decoration: const InputDecoration(labelText: 'Payment Mode *'),
                      items: const [
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMode = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sent Date: ${DateFormat('d MMM yyyy').format(selectedDate)}',
                            style: TextStyle(fontSize: 13, color: colors.textPrimary),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: const Text('Change Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Optional Note / Reference'),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final amount = double.tryParse(amountController.text.trim());
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
                                mode: isCommitment ? 'COMMITTED' : selectedMode,
                                note: noteController.text.trim(),
                                receivedAt: selectedDate.toIso8601String().substring(0, 10),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadMemberData();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isSubmitting ? 'Submitting...' : 'Submit Money Log'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DIALOG: LOG HOURS (MEMBER)
  void _showLogHoursDialog() {
    final titleController = TextEditingController();
    String selectedType = 'MENTORING';
    final hoursController = TextEditingController();
    String? selectedCampaignId;
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
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
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        'Record Volunteer Hours',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Record hours for mentoring, lectures, volunteering, hosting, goods, or app work.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Activity *',
                      hintText: 'e.g., Online Python workshop for Class 11',
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    items: volunteerTypes.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: hoursController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Hours Given *', hintText: 'e.g., 3.0'),
                  ),
                  const SizedBox(height: 12),

                  if (_campaigns.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedCampaignId,
                      decoration: const InputDecoration(labelText: 'Related Campaign (Optional)'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ..._campaigns.map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.title, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setModalState(() => selectedCampaignId = val),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${DateFormat('d MMM yyyy').format(selectedDate)}',
                          style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: const Text('Change Date'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Optional Note'),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final hours = double.tryParse(hoursController.text.trim());
                            final title = titleController.text.trim();
                            if (title.isEmpty || hours == null || hours <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter valid title and hours')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logPhysicalContribution(
                                type: selectedType,
                                hours: hours,
                                title: title,
                                campaignId: selectedCampaignId,
                                note: noteController.text.trim(),
                                contributedAt: selectedDate.toIso8601String().substring(0, 10),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadMemberData();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isSubmitting ? 'Submitting...' : 'Submit Volunteer Hours'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteFinancial(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this pending contribution log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteFinancialContribution(id);
        _loadMemberData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleDeletePhysical(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hours Log?'),
        content: const Text('Are you sure you want to delete this pending hours log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deletePhysicalContribution(id);
        _loadMemberData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final isCoordinator = auth.user?.role == 'COORDINATOR';

    _initTabController(isCoordinator);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(isCoordinator ? 'Contributions & Ledger' : 'My Contributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadMemberData();
            },
          ),
          const CommonAppBarActions(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: isCoordinator
              ? const [
                  Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: 'Coordinator Ledger'),
                  Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'My Personal'),
                ]
              : const [
                  Tab(icon: Icon(Icons.volunteer_activism_rounded, size: 20), text: 'My Contributions'),
                  Tab(icon: Icon(Icons.campaign_rounded, size: 20), text: 'Campaigns'),
                ],
        ),
      ),
      body: isCoordinator
          ? TabBarView(
              controller: _tabController,
              children: [
                CoordinatorContributionsView(
                  onDataChanged: _loadMemberData,
                ),
                _buildMemberContributionsView(colors),
              ],
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMemberContributionsView(colors),
                _buildCampaignsBrowserView(colors),
              ],
            ),
    );
  }

  // VIEW 1: MY CONTRIBUTIONS (EXACT ARCHITECTURE OF https://www.navodayan.org/contributions)
  Widget _buildMemberContributionsView(ThemePalette colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _data?.summary ?? const ContributionSummary();
    final financialLogs = _data?.financial ?? [];
    final physicalLogs = _data?.physical ?? [];

    return RefreshIndicator(
      onRefresh: _loadMemberData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Description
            Text(
              'My Contributions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Log money you already sent to a school or country campaign, or hours you gave. The coordinator for that campaign verifies both. Verified money shows on the campaign public totals.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMessage!, style: TextStyle(fontSize: 12.5, color: Colors.red.shade900)),
              ),
              const SizedBox(height: 16),
            ],

            // 5 STAT CARDS
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Verified Money',
                    value: _formatCurrency(summary.verifiedMoney),
                    colors: colors,
                    valueColor: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Pending Money',
                    value: _formatCurrency(summary.pendingMoney),
                    colors: colors,
                    valueColor: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Committed Money',
                    value: _formatCurrency(summary.committedMoney),
                    colors: colors,
                    valueColor: Colors.lightBlue.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Verified Hours',
                    value: '${summary.verifiedHours} hrs',
                    colors: colors,
                    valueColor: Colors.indigo.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Pending Hours',
                    value: '${summary.pendingHours} hrs',
                    colors: colors,
                    valueColor: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLogMoneyDialog,
                    icon: const Icon(Icons.currency_rupee_rounded, size: 16),
                    label: const Text('Log Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showLogHoursDialog,
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: const Text('Log Hours'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 1: MONEY LOGS
            Text(
              'Money Logs (${financialLogs.length})',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            if (financialLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Text('No money logs yet.', style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                ),
              )
            else
              ...financialLogs.map((item) {
                final isPending = item.status == 'PENDING';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_formatCurrency(item.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                const SizedBox(width: 8),
                                _buildStatusBadge(item.status),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.campaignTitle ?? "General"} · ${item.mode ?? "UPI"} · ${_formatDate(item.createdAt)}',
                              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                            ),
                            if (item.note != null && item.note!.isNotEmpty)
                              Text(item.note!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colors.textSecondary)),
                            if (item.rejectionReason != null && item.rejectionReason!.isNotEmpty)
                              Text('Reason: ${item.rejectionReason}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                          ],
                        ),
                      ),
                      if (isPending)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          onPressed: () => _handleDeleteFinancial(item.id),
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // SECTION 2: HOURS LOGS
            Text(
              'Hours Logs (${physicalLogs.length})',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            if (physicalLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Text('No hours logs yet.', style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                ),
              )
            else
              ...physicalLogs.map((item) {
                final isPending = item.status == 'PENDING';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${item.hours} hrs · ${volunteerTypes[item.type] ?? item.type}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                const SizedBox(width: 8),
                                _buildStatusBadge(item.status),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.description ?? "Volunteering"} · ${_formatDate(item.createdAt)}',
                              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isPending)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          onPressed: () => _handleDeletePhysical(item.id),
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // VIEW 2: BROWSE CAMPAIGNS FOR MEMBERS
  Widget _buildCampaignsBrowserView(ThemePalette colors) {
    if (_campaigns.isEmpty) {
      return Center(
        child: Text('No active campaigns found.', style: TextStyle(color: colors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final c = _campaigns[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(c.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.status == 'OPEN' ? Colors.green.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.status ?? 'OPEN',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: c.status == 'OPEN' ? Colors.green : Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${campaignPurposes[c.purpose] ?? c.purpose}${c.description != null ? " · ${c.description}" : ""}',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Raised: ${_formatCurrency(c.raisedAmount ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                  ElevatedButton(
                    onPressed: _showLogMoneyDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Contribute', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required ThemePalette colors,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = status ?? 'VERIFIED';

    if (label == 'VERIFIED') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (label == 'PENDING') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (label == 'REJECTED') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (label == 'COMMITTED') {
      bg = Colors.lightBlue.shade50;
      fg = Colors.lightBlue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

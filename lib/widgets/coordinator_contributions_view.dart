import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/coordinator_service.dart';
import '../theme/app_theme.dart';

const Map<String, String> campaignPurposes = {
  'ALUMNI': 'Alumni',
  'STUDENTS': 'Students',
  'STAFF': 'Staff',
  'SCHOOL': 'School / Navodaya',
  'OTHER': 'Other',
};

const Map<String, String> paymentModes = {
  'UPI': 'UPI',
  'BANK': 'Bank transfer',
  'CASH': 'Cash',
  'CHEQUE': 'Cheque',
  'OTHER': 'Other',
  'COMMITTED': 'Committed',
};

const Map<String, String> volunteerTypes = {
  'MENTORING': 'Mentoring',
  'GUEST_LECTURE': 'Guest lecture',
  'VOLUNTEERING': 'Volunteering',
  'HOSTING': 'Hosting / stay',
  'GOODS': 'Goods / materials',
  'COORDINATION': 'Coordination',
  'APP_DEV_MAINTENANCE': 'App Dev & Maintenance',
  'OTHER': 'Other',
};

class CoordinatorContributionsView extends StatefulWidget {
  final String? scopeLabel;
  final VoidCallback? onDataChanged;

  const CoordinatorContributionsView({
    super.key,
    this.scopeLabel,
    this.onDataChanged,
  });

  @override
  State<CoordinatorContributionsView> createState() => _CoordinatorContributionsViewState();
}

class _CoordinatorContributionsViewState extends State<CoordinatorContributionsView> {
  final CoordinatorService _service = CoordinatorService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _reviewsData;
  Map<String, dynamic>? _campaignsData;
  List<Map<String, dynamic>> _members = [];

  String? _selectedCampaignId;
  Map<String, dynamic>? _selectedCampaignDetail;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getContributionReviews(),
        _service.getCampaigns(),
        _service.getCampaignMembers(),
      ]);

      if (mounted) {
        setState(() {
          _reviewsData = results[0] as Map<String, dynamic>?;
          _campaignsData = results[1] as Map<String, dynamic>?;
          _members = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });

        final campaigns = (_campaignsData?['campaigns'] as List<dynamic>?) ?? [];
        if (_selectedCampaignId == null && campaigns.isNotEmpty) {
          _selectCampaign(campaigns.first['id'].toString());
        } else if (_selectedCampaignId != null) {
          _loadCampaignDetail(_selectedCampaignId!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCampaignDetail(String campaignId) async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _service.getCampaignDetail(campaignId);
      if (mounted) {
        setState(() {
          _selectedCampaignDetail = detail;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  void _selectCampaign(String campaignId) {
    setState(() {
      _selectedCampaignId = campaignId;
    });
    _loadCampaignDetail(campaignId);
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return formatter.format(val);
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

  Future<void> _handleReview(String kind, String id, bool approve) async {
    String? reason;
    if (!approve) {
      final reasonController = TextEditingController();
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reject Contribution'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Optional reason for member',
              hintText: 'Enter reason...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
      reason = reasonController.text.trim();
    }

    try {
      await _service.reviewContribution(kind, id, approve: approve, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Contribution verified' : 'Contribution rejected'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
      _loadAll();
      widget.onDataChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleToggleCampaign(String id, String currentStatus) async {
    try {
      await _service.toggleCampaignStatus(id, currentStatus);
      _loadAll();
      widget.onDataChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // DIALOG: LOG MEMBER HOURS
  void _showLogMemberHoursDialog() {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members available for this school')),
      );
      return;
    }

    String? selectedUserId = _members.first['userId']?.toString();
    final titleController = TextEditingController();
    String selectedType = volunteerTypes.keys.first;
    final hoursController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? selectedCampaignId;
    final campaigns = (_campaignsData?['campaigns'] as List<dynamic>?) ?? [];

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
                        'Log Hours for Member',
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
                    'Saved as verified for members. Hours credited to coordinator still go to admin for review.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedUserId,
                    decoration: const InputDecoration(labelText: 'Member *'),
                    items: _members.map((m) {
                      final name = m['fullName'] ?? m['name'] ?? m['email'] ?? 'Member';
                      final batch = m['batch'] != null ? ' · Batch ${m['batch']}' : '';
                      return DropdownMenuItem<String>(
                        value: m['userId'].toString(),
                        child: Text(
                          '$name$batch',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedUserId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Activity *',
                      hintText: 'e.g., Physics guest lecture',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
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
                    decoration: const InputDecoration(labelText: 'Hours *', hintText: 'e.g., 2.5'),
                  ),
                  const SizedBox(height: 12),
                  if (campaigns.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedCampaignId,
                      decoration: const InputDecoration(labelText: 'Related Campaign (Optional)'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ...campaigns.map((c) => DropdownMenuItem<String>(
                              value: c['id'].toString(),
                              child: Text(c['title'] ?? 'Campaign', overflow: TextOverflow.ellipsis, maxLines: 1),
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
                            if (selectedUserId == null || title.isEmpty || hours == null || hours <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields correctly')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logMemberPhysicalContribution({
                                'memberUserId': selectedUserId,
                                'type': selectedType,
                                'hours': hours,
                                'title': title,
                                'note': noteController.text.trim(),
                                'contributedAt': selectedDate.toIso8601String().substring(0, 10),
                                if (selectedCampaignId != null) 'campaignId': selectedCampaignId,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadAll();
                              widget.onDataChanged?.call();
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
                    child: Text(isSubmitting ? 'Saving...' : 'Add Verified Hours'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DIALOG: LOG MEMBER MONEY
  void _showLogMemberMoneyDialog() {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members available for this school')),
      );
      return;
    }

    final campaigns = ((_campaignsData?['campaigns'] as List<dynamic>?) ?? [])
        .where((c) => c['status'] == 'OPEN')
        .toList();

    if (campaigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or reopen a campaign before logging member money')),
      );
      return;
    }

    String? selectedUserId = _members.first['userId']?.toString();
    String? selectedCampaignId = campaigns.first['id']?.toString();
    final amountController = TextEditingController();
    String selectedMode = 'UPI';
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
                        'Log Money for Member',
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
                    'Saved as verified and counted on the campaign. Choose the member and campaign.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedUserId,
                    decoration: const InputDecoration(labelText: 'Member *'),
                    items: _members.map((m) {
                      final name = m['fullName'] ?? m['name'] ?? m['email'] ?? 'Member';
                      final batch = m['batch'] != null ? ' · Batch ${m['batch']}' : '';
                      return DropdownMenuItem<String>(
                        value: m['userId'].toString(),
                        child: Text(
                          '$name$batch',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedUserId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCampaignId,
                    decoration: const InputDecoration(labelText: 'Campaign *'),
                    items: campaigns.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['title'] ?? 'Campaign', overflow: TextOverflow.ellipsis, maxLines: 1),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedCampaignId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹) *',
                      prefixText: '₹ ',
                      hintText: '5000',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode *'),
                    items: paymentModes.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedMode = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Received Date: ${DateFormat('d MMM yyyy').format(selectedDate)}',
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
                            final amount = double.tryParse(amountController.text.trim());
                            if (selectedUserId == null || selectedCampaignId == null || amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields correctly')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logMemberMoneyContribution({
                                'memberUserId': selectedUserId,
                                'campaignId': selectedCampaignId,
                                'amount': amount,
                                'mode': selectedMode,
                                'note': noteController.text.trim(),
                                'receivedAt': selectedDate.toIso8601String().substring(0, 10),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadAll();
                              widget.onDataChanged?.call();
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
                    child: Text(isSubmitting ? 'Saving...' : 'Add Verified Money'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DIALOG: CREATE CAMPAIGN
  void _showCreateCampaignDialog() {
    final titleController = TextEditingController();
    String selectedPurpose = 'ALUMNI';
    final descController = TextEditingController();
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
                        'Create Campaign',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g., Alumni Meet 2026',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedPurpose,
                    decoration: const InputDecoration(labelText: 'For / Purpose *'),
                    items: campaignPurposes.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedPurpose = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Description',
                      hintText: 'Optional: hall, meals, scholarships...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter campaign title')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.createCampaign({
                                'title': title,
                                'purpose': selectedPurpose,
                                'description': descController.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadAll();
                              widget.onDataChanged?.call();
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
                    child: Text(isSubmitting ? 'Saving...' : 'Create Campaign'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DIALOG: LOG CAMPAIGN ENTRY (CONTRIBUTION) WITH DONOR AUTOCOMPLETE
  void _showAddCampaignContributionDialog(String campaignId, String campaignTitle) {
    final donorController = TextEditingController();
    String? selectedMemberUserId;
    final amountController = TextEditingController();
    String selectedMode = 'UPI';
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    List<Map<String, dynamic>> searchResults = [];
    Timer? debounce;
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
                      Expanded(
                        child: Text(
                          'Log Contribution · $campaignTitle',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: donorController,
                    decoration: const InputDecoration(
                      labelText: 'Donor Name *',
                      hintText: 'Type to search members or enter donor name',
                    ),
                    onChanged: (val) {
                      selectedMemberUserId = null;
                      debounce?.cancel();
                      if (val.trim().length >= 2) {
                        debounce = Timer(const Duration(milliseconds: 300), () async {
                          final results = await _service.searchDonors(val.trim());
                          if (ctx.mounted) {
                            setModalState(() => searchResults = results);
                          }
                        });
                      } else {
                        setModalState(() => searchResults = []);
                      }
                    },
                  ),
                  if (searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: colors.background,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: searchResults.map((s) {
                          return ListTile(
                            dense: true,
                            title: Text(s['fullName'] ?? s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(s['email'] ?? '', style: const TextStyle(fontSize: 11)),
                            onTap: () {
                              setModalState(() {
                                donorController.text = s['fullName'] ?? s['name'] ?? '';
                                selectedMemberUserId = s['userId']?.toString();
                                searchResults = [];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode *'),
                    items: paymentModes.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedMode = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Received Date: ${DateFormat('d MMM yyyy').format(selectedDate)}',
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
                            final donor = donorController.text.trim();
                            final amount = double.tryParse(amountController.text.trim());
                            if (donor.isEmpty || amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter valid donor name and amount')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logCampaignEntry(campaignId, {
                                'donorName': donor,
                                'memberUserId': selectedMemberUserId,
                                'amount': amount,
                                'mode': selectedMode,
                                'note': noteController.text.trim(),
                                'receivedAt': selectedDate.toIso8601String().substring(0, 10),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadCampaignDetail(campaignId);
                              _loadAll();
                              widget.onDataChanged?.call();
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
                    child: Text(isSubmitting ? 'Saving...' : 'Add Contribution'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DIALOG: LOG CAMPAIGN EXPENSE
  void _showAddCampaignExpenseDialog(String campaignId, String campaignTitle) {
    final payeeController = TextEditingController();
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
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
                      Expanded(
                        child: Text(
                          'Log Expense · $campaignTitle',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: payeeController,
                    decoration: const InputDecoration(labelText: 'Paid To *', hintText: 'Vendor or person name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(labelText: 'What For *', hintText: 'e.g. Tent rental, speaker memento'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Spent Date: ${DateFormat('d MMM yyyy').format(selectedDate)}',
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final payee = payeeController.text.trim();
                            final amount = double.tryParse(amountController.text.trim());
                            final desc = purposeController.text.trim();
                            if (payee.isEmpty || amount == null || amount <= 0 || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required expense fields')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.logCampaignExpense(campaignId, {
                                'payee': payee,
                                'amount': amount,
                                'description': desc,
                                'spentAt': selectedDate.toIso8601String().substring(0, 10),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadCampaignDetail(campaignId);
                              _loadAll();
                              widget.onDataChanged?.call();
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
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isSubmitting ? 'Saving...' : 'Add Expense'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteEntry(String campaignId, String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contribution?'),
        content: const Text('Are you sure you want to remove this contribution entry? This will update campaign totals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteCampaignEntry(campaignId, entryId);
        _loadCampaignDetail(campaignId);
        _loadAll();
        widget.onDataChanged?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteExpense(String campaignId, String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Expense?'),
        content: const Text('Are you sure you want to remove this expense entry? This will update campaign balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteCampaignExpense(campaignId, expenseId);
        _loadCampaignDetail(campaignId);
        _loadAll();
        widget.onDataChanged?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviews = _reviewsData ?? {};
    final financialReviews = (reviews['financial'] as List<dynamic>?) ?? [];
    final physicalReviews = (reviews['physical'] as List<dynamic>?) ?? [];
    final hoursVerified = _campaignsData?['hoursVerified'] ?? reviews['hoursVerified'] ?? 0;
    final alertMessage = _campaignsData?['message'] as String?;
    final campaigns = (_campaignsData?['campaigns'] as List<dynamic>?) ?? [];

    final scope = widget.scopeLabel ?? _campaignsData?['scopeLabel'] ?? _campaignsData?['jnvName'] ?? 'your school';

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP HEADER & INSTRUCTIONS
            Text(
              'Contributions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Record money already received or spent for $scope. Members can also log money and hours; only verified money counts toward campaign totals. This is a ledger for your assignment, not an online payment page.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 14),

            // VERIFIED HOURS BANNER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verified hours for this school: $hoursVerified',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            if (alertMessage != null && alertMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  alertMessage,
                  style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 12.5, color: Colors.red.shade900),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ACTION BUTTONS: LOG ON BEHALF OF MEMBER
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLogMemberMoneyDialog,
                    icon: const Icon(Icons.currency_rupee_rounded, size: 16),
                    label: const Text('Log Member Money', style: TextStyle(fontSize: 12)),
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
                    onPressed: _showLogMemberHoursDialog,
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: const Text('Log Member Hours', style: TextStyle(fontSize: 12)),
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

            // SECTION 1: PENDING MEMBER LOGS
            if (financialReviews.isNotEmpty || physicalReviews.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'PENDING MEMBER LOGS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${financialReviews.length + physicalReviews.length} Pending',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Verify after you confirm the transfer or the work. Coordinator hours are reviewed by admin, not here.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 12),

              if (financialReviews.isNotEmpty) ...[
                Text('Money Transfers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 8),
                ...financialReviews.map((f) => _buildPendingCard(
                      colors,
                      title: '${f['donorName'] ?? "Donor"} · ${_formatCurrency(f['amount'])} · ${paymentModes[f['mode']] ?? f['mode'] ?? ""}',
                      subtitle: '${f['campaignTitle'] ?? "Campaign"} · ${_formatDate(f['receivedAt'])}',
                      onVerify: () => _handleReview('financial', f['id'].toString(), true),
                      onReject: () => _handleReview('financial', f['id'].toString(), false),
                    )),
                const SizedBox(height: 12),
              ],

              if (physicalReviews.isNotEmpty) ...[
                Text('Volunteer Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 8),
                ...physicalReviews.map((p) => _buildPendingCard(
                      colors,
                      title: '${p['memberName'] ?? p['memberEmail'] ?? "Member"} · ${p['hours']} hrs · ${volunteerTypes[p['type']] ?? p['type'] ?? ""}',
                      subtitle: '${p['title'] ?? ""}${p['campaignTitle'] != null ? " · ${p['campaignTitle']}" : ""} · ${_formatDate(p['contributedAt'])}',
                      onVerify: () => _handleReview('physical', p['id'].toString(), true),
                      onReject: () => _handleReview('physical', p['id'].toString(), false),
                    )),
              ],
              const SizedBox(height: 24),
            ],

            // SECTION 2: CAMPAIGNS & LEDGER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CAMPAIGNS & LEDGER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: colors.textSecondary),
                ),
                TextButton.icon(
                  onPressed: _showCreateCampaignDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create Campaign'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (campaigns.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.campaign_outlined, size: 40, color: colors.textSecondary),
                      const SizedBox(height: 8),
                      Text('No contribution campaigns yet.', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Create a campaign to record alumni donations and track expenses.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _showCreateCampaignDialog,
                        child: const Text('Create Campaign'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // CAMPAIGN SELECTOR / CARDS
              ...campaigns.map((c) => _buildCampaignCard(colors, c)),

              const SizedBox(height: 20),

              // DETAILED LEDGER FOR SELECTED CAMPAIGN
              if (_selectedCampaignId != null) ...[
                _buildDetailedLedgerView(colors),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(
    ThemePalette colors, {
    required String title,
    required String subtitle,
    required VoidCallback onVerify,
    required VoidCallback onReject,
  }) {
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verify', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(ThemePalette colors, dynamic c) {
    final cid = c['id']?.toString() ?? '';
    final isSelected = cid == _selectedCampaignId;
    final title = c['title']?.toString() ?? 'Campaign';
    final purpose = campaignPurposes[c['purpose']] ?? c['purpose'] ?? 'General';
    final status = c['status']?.toString() ?? 'OPEN';
    final isOpen = status == 'OPEN';

    final totals = c['totals'] as Map<String, dynamic>? ?? {};
    final raised = totals['raised'] ?? c['received'] ?? c['totalRaised'] ?? 0;
    final spent = totals['spent'] ?? c['spent'] ?? c['totalSpent'] ?? 0;
    final committed = totals['committed'] ?? 0;
    final balance = totals['balance'] ?? ((raised is num && spent is num) ? (raised - spent) : 0);

    return InkWell(
      onTap: () => _selectCampaign(cid),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? colors.primary : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$purpose · ${isOpen ? "Open" : "Closed"}',
                        style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isOpen ? Colors.green : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // METRIC STRIP (Raised · Spent · Balance)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Raised', style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(_formatCurrency(raised), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                    ],
                  ),
                  Container(height: 20, width: 1, color: colors.border),
                  Column(
                    children: [
                      Text('Spent', style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(_formatCurrency(spent), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange.shade800)),
                    ],
                  ),
                  if (committed is num && committed > 0) ...[
                    Container(height: 20, width: 1, color: colors.border),
                    Column(
                      children: [
                        Text('Committed', style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(_formatCurrency(committed), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.lightBlue.shade800)),
                      ],
                    ),
                  ],
                  Container(height: 20, width: 1, color: colors.border),
                  Column(
                    children: [
                      Text('Balance', style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(_formatCurrency(balance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DETAILED CAMPAIGN LEDGER
  Widget _buildDetailedLedgerView(ThemePalette colors) {
    if (_isLoadingDetail) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    final detail = _selectedCampaignDetail;
    if (detail == null) return const SizedBox.shrink();

    final cid = detail['id']?.toString() ?? _selectedCampaignId ?? '';
    final title = detail['title']?.toString() ?? 'Campaign';
    final purpose = campaignPurposes[detail['purpose']] ?? detail['purpose'] ?? 'General';
    final desc = detail['description']?.toString() ?? '';
    final status = detail['status']?.toString() ?? 'OPEN';
    final isOpen = status == 'OPEN';

    final totals = detail['totals'] as Map<String, dynamic>? ?? {};
    final raised = totals['raised'] ?? 0;
    final committed = totals['committed'] ?? 0;
    final spent = totals['spent'] ?? 0;
    final balance = totals['balance'] ?? 0;

    final entries = (detail['entries'] as List<dynamic>?) ?? [];
    final expenses = (detail['expenses'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$purpose${desc.isNotEmpty ? " · $desc" : ""}',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _handleToggleCampaign(cid, status),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isOpen ? 'Close Campaign' : 'Reopen Campaign',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 STAT TILES: Raised, Committed, Spent, Balance
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Raised',
                  amount: _formatCurrency(raised),
                  bgColor: Colors.green.shade50,
                  textColor: Colors.green.shade900,
                  borderColor: Colors.green.shade200,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Committed',
                  amount: _formatCurrency(committed),
                  bgColor: Colors.lightBlue.shade50,
                  textColor: Colors.lightBlue.shade900,
                  borderColor: Colors.lightBlue.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Spent',
                  amount: _formatCurrency(spent),
                  bgColor: Colors.amber.shade50,
                  textColor: Colors.amber.shade900,
                  borderColor: Colors.amber.shade200,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Balance',
                  amount: _formatCurrency(balance),
                  bgColor: Colors.indigo.shade50,
                  textColor: Colors.indigo.shade900,
                  borderColor: Colors.indigo.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // IF CAMPAIGN IS OPEN: ADD BUTTONS
          if (isOpen) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Contribution', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddCampaignContributionDialog(cid, title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    label: const Text('Add Expense', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddCampaignExpenseDialog(cid, title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This campaign is closed. Reopen it to add or remove records.',
                style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // CONTRIBUTIONS TABLE
          Text(
            'Contributions (${entries.length})',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Text('No contributions yet.', style: TextStyle(fontSize: 12, color: colors.textSecondary))
          else
            ...entries.map((e) {
              final eid = e['id']?.toString() ?? '';
              final donor = e['donorName']?.toString() ?? 'Donor';
              final note = e['note']?.toString();
              final amt = _formatCurrency(e['amount']);
              final mode = paymentModes[e['mode']] ?? e['mode'] ?? '';
              final date = _formatDate(e['receivedAt']);
              final reviewStatus = e['reviewStatus']?.toString() ?? 'VERIFIED';
              final isCommitted = e['mode'] == 'COMMITTED';

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$donor · $amt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text(
                            '$mode · ${isCommitted ? "Committed" : reviewStatus} · $date',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary),
                          ),
                          if (note != null && note.isNotEmpty)
                            Text(note, style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: colors.textSecondary)),
                        ],
                      ),
                    ),
                    if (isOpen)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        onPressed: () => _handleDeleteEntry(cid, eid),
                        tooltip: 'Remove',
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          // EXPENSES TABLE
          Text(
            'Expenses (${expenses.length})',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          if (expenses.isEmpty)
            Text('No expenses yet.', style: TextStyle(fontSize: 12, color: colors.textSecondary))
          else
            ...expenses.map((ex) {
              final eid = ex['id']?.toString() ?? '';
              final payee = ex['payee']?.toString() ?? 'Payee';
              final desc = ex['description']?.toString() ?? '';
              final amt = _formatCurrency(ex['amount']);
              final date = _formatDate(ex['spentAt']);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$payee · $amt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text('$desc · $date', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                        ],
                      ),
                    ),
                    if (isOpen)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        onPressed: () => _handleDeleteExpense(cid, eid),
                        tooltip: 'Remove',
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String amount,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textColor)),
          const SizedBox(height: 2),
          Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}

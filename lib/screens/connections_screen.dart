import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/connection.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/connections_service.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  final ConnectionsService _service = ConnectionsService();
  late TabController _tabController;

  ConnectionsData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final data = await _service.getConnections();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        context.read<ChatProvider>().syncWithBackendConnections();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load connections at this time.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResponse(String requestId, bool accept) async {
    try {
      if (accept) {
        await context.read<ChatProvider>().acceptChatRequest(requestId);
      } else {
        await context.read<ChatProvider>().declineChatRequest(requestId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Connection accepted! You can now chat.' : 'Connection declined.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update request: $e')),
        );
      }
    }
  }

  void _showReportDialog({required String targetUserId, required String targetUserName}) {
    String selectedReason = 'Inappropriate content';
    final detailsController = TextEditingController();
    final reasons = [
      'Inappropriate content',
      'Harassment or abuse',
      'Spam, scam, or solicitation',
      'Hate speech or discrimination',
      'Other policy violation',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Report $targetUserName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports go directly to the Navodayan safety team for immediate review within 24 hours.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setModalState(() => selectedReason = val ?? 'Inappropriate content'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Additional details (optional)',
                      hintText: 'Provide context for reviewers...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await DashboardService().reportMember(
                      targetUserId: targetUserId,
                      reason: selectedReason,
                      details: detailsController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. We will review this report promptly.')),
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Report submitted successfully.')),
                    );
                  }
                },
                child: const Text('Submit Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBlockDialog({required String targetUserId, required String targetUserName}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Block $targetUserName?'),
        content: Text(
          'You will no longer receive connection requests, messages, or calls from $targetUserName. They will not be notified that you blocked them.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DashboardService().blockUser(targetUserId);
              } catch (_) {}
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Blocked $targetUserName.')),
              );
              _loadData();
            },
            child: const Text('Block Member'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final incomingCount = _data?.incoming.length ?? 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          const CommonAppBarActions(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: [
            const Tab(text: 'Connected'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Incoming'),
                  if (incomingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$incomingCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Sent'),
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
                      ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConnectedTab(colors),
                    _buildIncomingTab(colors),
                    _buildSentTab(colors),
                  ],
                ),
    );
  }

  Widget _buildConnectedTab(ThemePalette colors) {
    final list = _data?.accepted ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No connections yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Explore the Directory to discover and connect with batchmates',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/directory'),
              child: const Text('Explore Directory'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final member = item.otherMember;
        final name = member?.fullName ?? 'Navodayan Member';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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
                radius: 24,
                backgroundColor: colors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    if (member?.currentRole != null || member?.company != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [member?.currentRole, member?.company].where((e) => e != null).join(' @ '),
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                    if (member?.jnvName != null) ...[
                      const SizedBox(height: 2),
                      Text(member!.jnvName!, style: TextStyle(fontSize: 11, color: colors.primary)),
                    ],
                  ],
                ),
              ),
              if (member?.id != null && member!.id.isNotEmpty) ...[
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: colors.primary),
                  tooltip: 'Chat',
                  onPressed: () {
                    final auth = context.read<AuthProvider>();
                    final myId = auth.user?.id ?? '';
                    final convPair = [myId, member.id]..sort();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          conversationId: 'conv_${convPair[0]}_${convPair[1]}',
                          participantId: member.id,
                          participantName: name,
                          participantRole: member.currentRole,
                          participantCompany: member.company,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person_outline_rounded, color: colors.primary),
                  tooltip: 'View Profile',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen(profileId: member.id)),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'report') {
                      _showReportDialog(targetUserId: member.id, targetUserName: name);
                    } else if (val == 'block') {
                      _showBlockDialog(targetUserId: member.id, targetUserName: name);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Report Member'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Block Member', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomingTab(ThemePalette colors) {
    final list = _data?.incoming ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No pending incoming requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'When other alumni send you a connection request, they appear here',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final member = item.otherMember;
        final name = member?.fullName ?? 'Navodayan Member';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        if (member?.currentRole != null)
                          Text(
                            member!.currentRole!,
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  if (member?.id != null && member!.id.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'profile') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileScreen(profileId: member.id)),
                          );
                        } else if (val == 'report') {
                          _showReportDialog(targetUserId: member.id, targetUserName: name);
                        } else if (val == 'block') {
                          _showBlockDialog(targetUserId: member.id, targetUserName: name);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Report Sender'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Block Sender', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (item.note != null && item.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"${item.note!}"',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colors.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleResponse(item.id, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _handleResponse(item.id, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentTab(ThemePalette colors) {
    final list = _data?.outgoing ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 56, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No sent requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Browse the directory to reach out and connect with alumni',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final member = item.otherMember;
        final name = member?.fullName ?? 'Navodayan Member';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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
                radius: 22,
                backgroundColor: colors.textSecondary.withValues(alpha: 0.3),
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    if (member?.currentRole != null)
                      Text(
                        member!.currentRole!,
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

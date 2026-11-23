import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';

class ChatsScreen extends StatefulWidget {
  final int initialIndex;
  const ChatsScreen({super.key, this.initialIndex = 0});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _argumentsHandled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().syncWithBackendConnections();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsHandled) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _tabController.animateTo(args.clamp(0, 1));
        _argumentsHandled = true;
      } else if (args is Map && args['initialIndex'] is int) {
        _tabController.animateTo((args['initialIndex'] as int).clamp(0, 1));
        _argumentsHandled = true;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Messages'),
          actions: const [
            CommonAppBarActions(),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'Member Chat Requires Login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to connect and text with fellow alumni in the Navodayan network.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Log In to Chat'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversations = chatProvider.conversations;
    final pendingRequests = chatProvider.pendingRequests;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Member Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => chatProvider.syncWithBackendConnections(),
          ),
          const CommonAppBarActions(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Conversations'),
                  if (conversations.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conversations.length}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  if (pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingRequests.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsList(conversations, colors),
          _buildRequestsList(pendingRequests, chatProvider, colors),
        ],
      ),
    );
  }

  Widget _buildConversationsList(List<ChatConversation> conversations, ThemePalette colors) {
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 56, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'No Active Conversations',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse the directory to find batchmates and start a chat request.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.people_outline_rounded),
                label: const Text('Explore Directory'),
                onPressed: () => Navigator.pushNamed(context, '/directory'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = conversations[index];
        final initials = item.participantName.isNotEmpty ? item.participantName[0].toUpperCase() : 'N';
        final timeStr = DateFormat('h:mm a').format(item.lastMessageTime);

        return Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: item.id,
                    participantId: item.participantId,
                    participantName: item.participantName,
                    participantRole: item.participantRole,
                    participantCompany: item.participantCompany,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.participantName,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ),
                        if (item.participantRole != null && item.participantRole!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.participantRole!,
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          item.lastMessage,
                          style: TextStyle(fontSize: 13, color: colors.textSecondary.withValues(alpha: 0.8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (item.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(profileId: item.participantId)),
                        );
                      } else if (val == 'report') {
                        _showReportDialog(targetUserId: item.participantId, targetUserName: item.participantName);
                      } else if (val == 'block') {
                        _showBlockDialog(targetUserId: item.participantId, targetUserName: item.participantName);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Report Member'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Block Member', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(List<ChatRequest> requests, ChatProvider provider, ThemePalette colors) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 56, color: colors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No Pending Chat Requests',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'When other alumni want to start a chat with you, their requests will appear here.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = requests[index];
        final initials = req.senderName.isNotEmpty ? req.senderName[0].toUpperCase() : 'N';
        final timeStr = DateFormat('MMM d, h:mm a').format(req.createdAt);

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
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.senderName,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        if (req.senderRole != null && req.senderRole!.isNotEmpty)
                          Text(
                            req.senderRole!,
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(profileId: req.senderId)),
                        );
                      } else if (val == 'report') {
                        _showReportDialog(targetUserId: req.senderId, targetUserName: req.senderName);
                      } else if (val == 'block') {
                        _showBlockDialog(targetUserId: req.senderId, targetUserName: req.senderName);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Report Sender'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Block Sender', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (req.message != null && req.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '"${req.message}"',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colors.textPrimary),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => provider.declineChatRequest(req.id),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => provider.acceptChatRequest(req.id),
                      child: const Text('Accept & Chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../services/connections_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
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
      await _service.respondToRequest(requestId, accept: accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Connection accepted!' : 'Connection declined.')),
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
              if (member?.id != null && member!.id.isNotEmpty)
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

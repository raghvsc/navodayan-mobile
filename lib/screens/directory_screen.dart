import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/batch.dart';
import '../models/chat_models.dart';
import '../models/profile.dart';
import '../models/school.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_client.dart';
import '../services/schools_batches_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';
import 'send_chat_request_dialog.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final ApiClient _apiClient = ApiClient();
  final SchoolsBatchesService _schoolsBatchesService = SchoolsBatchesService();
  final _searchController = TextEditingController();

  List<Profile> _profiles = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  // Filters
  String? _selectedLocation;
  String? _selectedCountry;
  String? _selectedAssociation;
  String? _selectedBatchYear;
  String? _selectedJnvSchool;
  bool _openToMentorOnly = false;

  List<School> _schools = [];
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
    _fetchDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    try {
      final results = await Future.wait([
        _schoolsBatchesService.getSchools(),
        _schoolsBatchesService.getBatches(),
      ]);
      if (mounted) {
        setState(() {
          _schools = results[0] as List<School>;
          _batches = results[1] as List<Batch>;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDirectory({int page = 1, bool append = false}) async {
    if (page == 1) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': auth.isAuthenticated ? '12' : '10',
      };

      final query = _searchController.text.trim();
      if (query.isNotEmpty) queryParams['search'] = query;
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        queryParams['location'] = _selectedLocation!;
      }
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
        queryParams['country'] = _selectedCountry!;
      }
      if (_selectedAssociation != null && _selectedAssociation!.isNotEmpty) {
        queryParams['association'] = _selectedAssociation!;
      }
      if (_selectedBatchYear != null && _selectedBatchYear!.isNotEmpty) {
        queryParams['batchYear'] = _selectedBatchYear!;
      }
      if (_selectedJnvSchool != null && _selectedJnvSchool!.isNotEmpty) {
        queryParams['jnvSchool'] = _selectedJnvSchool!;
      }
      if (_openToMentorOnly) {
        queryParams['openToMentor'] = 'true';
      }

      final response = await _apiClient.get(
        '/directory/search',
        token: token,
        queryParams: queryParams,
      );

      final dynamic data = response['data'] ?? response;
      List<Profile> fetched = [];
      if (data is List) {
        fetched = data.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
      }

      final meta = response['meta'] is Map<String, dynamic>
          ? response['meta'] as Map<String, dynamic>
          : null;

      if (mounted) {
        setState(() {
          if (append) {
            _profiles.addAll(fetched);
          } else {
            _profiles = fetched;
          }
          _currentPage = meta?['currentPage'] ?? page;
          _totalPages = meta?['totalPages'] ?? 1;
          _totalCount = meta?['total'] ?? _profiles.length;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _loading = false;
          _loadingMore = false;
          if (_profiles.isEmpty) {
            _errorMessage = cleanMsg;
          }
        });
        if (_profiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cleanMsg),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _fetchDirectory(page: _currentPage),
              ),
            ),
          );
        }
      }
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _FilterBottomSheet(
          schools: _schools,
          batches: _batches,
          initialLocation: _selectedLocation,
          initialCountry: _selectedCountry,
          initialAssociation: _selectedAssociation,
          initialBatchYear: _selectedBatchYear,
          initialJnvSchool: _selectedJnvSchool,
          initialOpenToMentor: _openToMentorOnly,
          onApply: (loc, ctry, assoc, batch, school, mentor) {
            setState(() {
              _selectedLocation = loc;
              _selectedCountry = ctry;
              _selectedAssociation = assoc;
              _selectedBatchYear = batch;
              _selectedJnvSchool = school;
              _openToMentorOnly = mentor;
            });
            _fetchDirectory(page: 1);
          },
          onReset: () {
            setState(() {
              _selectedLocation = null;
              _selectedCountry = null;
              _selectedAssociation = null;
              _selectedBatchYear = null;
              _selectedJnvSchool = null;
              _openToMentorOnly = false;
            });
            _fetchDirectory(page: 1);
          },
        );
      },
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) count++;
    if (_selectedCountry != null && _selectedCountry!.isNotEmpty) count++;
    if (_selectedAssociation != null && _selectedAssociation!.isNotEmpty) count++;
    if (_selectedBatchYear != null && _selectedBatchYear!.isNotEmpty) count++;
    if (_selectedJnvSchool != null && _selectedJnvSchool!.isNotEmpty) count++;
    if (_openToMentorOnly) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Navodayan Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchDirectory(page: 1),
          ),
          const CommonAppBarActions(),
        ],
      ),
      body: Column(
        children: [
          // Header / Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name, role, company...',
                        hintStyle: TextStyle(color: colors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: colors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchDirectory(page: 1);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _fetchDirectory(page: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0 ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _activeFilterCount > 0 ? colors.primary : colors.border,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: _activeFilterCount > 0 ? Colors.white : colors.textPrimary,
                        ),
                        onPressed: _showFilterModal,
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Total Count / Active Filters summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_loading ? '...' : _totalCount} Navodayans found',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_openToMentorOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'Mentors Only',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Horizontal Quick Filter Chips (matches directory_redesigned/code.html)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickChip(
                  context,
                  label: 'All',
                  isSelected: _selectedLocation == null &&
                      _selectedBatchYear == null &&
                      !_openToMentorOnly &&
                      _selectedCountry == null &&
                      _selectedAssociation == null &&
                      _selectedJnvSchool == null,
                  onTap: () {
                    setState(() {
                      _selectedLocation = null;
                      _selectedBatchYear = null;
                      _openToMentorOnly = false;
                      _selectedCountry = null;
                      _selectedAssociation = null;
                      _selectedJnvSchool = null;
                    });
                    _fetchDirectory(page: 1);
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  context,
                  label: 'My State',
                  isSelected: _selectedLocation != null,
                  onTap: () {
                    final userLoc = auth.user?.profile?.location;
                    if (userLoc != null && userLoc.isNotEmpty) {
                      setState(() {
                        if (_selectedLocation == userLoc) {
                          _selectedLocation = null;
                        } else {
                          _selectedLocation = userLoc;
                        }
                      });
                      _fetchDirectory(page: 1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please set your location in profile')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  context,
                  label: 'Open to Mentor',
                  isSelected: _openToMentorOnly,
                  onTap: () {
                    setState(() {
                      _openToMentorOnly = !_openToMentorOnly;
                    });
                    _fetchDirectory(page: 1);
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  context,
                  label: 'Batchmates',
                  isSelected: _selectedBatchYear != null,
                  onTap: () {
                    final batchId = auth.user?.profile?.batchId;
                    if (batchId != null) {
                      final match = _batches.where((b) => b.id == batchId).firstOrNull;
                      final yearStr = match != null ? match.startYear.toString() : batchId.toString();
                      setState(() {
                        if (_selectedBatchYear == yearStr) {
                          _selectedBatchYear = null;
                        } else {
                          _selectedBatchYear = yearStr;
                        }
                      });
                      _fetchDirectory(page: 1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please set your batch in profile')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: _buildBody(auth),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AuthProvider auth) {
    final colors = AppColors.of(context);

    if (_loading && _profiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchDirectory(page: 1),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 64, color: colors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No Profiles Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Try clearing filters or searching for different keywords.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedLocation = null;
                    _selectedCountry = null;
                    _selectedAssociation = null;
                    _selectedBatchYear = null;
                    _selectedJnvSchool = null;
                    _openToMentorOnly = false;
                  });
                  _fetchDirectory(page: 1);
                },
                child: const Text('Reset All Filters'),
              ),
            ],
          ),
        ),
      );
    }

    final displayProfiles = !auth.isAuthenticated && _profiles.length > 10
        ? _profiles.sublist(0, 10)
        : _profiles;

    final showPrompt = !auth.isAuthenticated && _totalCount > 10;
    final showLoadMore = auth.isAuthenticated && _currentPage < _totalPages;

    return RefreshIndicator(
      onRefresh: () => _fetchDirectory(page: 1),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: displayProfiles.length + (showPrompt || showLoadMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          if (i == displayProfiles.length) {
            if (showPrompt) {
              return _buildLoginPromptCard(colors);
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: () => _fetchDirectory(page: _currentPage + 1, append: true),
                        icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                        label: const Text('Load More'),
                      ),
              ),
            );
          }
          return _buildProfileCard(displayProfiles[i]);
        },
      ),
    );
  }

  Widget _buildQuickChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPromptCard(ThemePalette colors) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Showing 10 of $_totalCount Members',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please log in to browse the complete directory, contact alumni, and explore all batches.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Log In to View More', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: const Color(0xFF0E1C38),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Profile profile) {
    final colors = AppColors.of(context);
    final initials = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'N';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 48x48 avatar circle with #132E5B background
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF132E5B),
                  backgroundImage: (profile.imageUrl != null && profile.imageUrl!.isNotEmpty)
                      ? NetworkImage(profile.imageUrl!)
                      : null,
                  child: (profile.imageUrl == null || profile.imageUrl!.isEmpty)
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.openToMentor)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Mentor',
                                    style: TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.subtitle.isNotEmpty
                            ? profile.subtitle
                            : (profile.currentRole ?? 'Alumnus'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.schoolAndBatch.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('🎓', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                profile.schoolAndBatch,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
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
          // Hairline separator
          Divider(height: 1, thickness: 1, color: colors.border.withValues(alpha: 0.6)),
          // Bottom action row matching HTML
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    final auth = context.read<AuthProvider>();
                    if (!auth.isAuthenticated) {
                      Navigator.pushNamed(context, '/login');
                    } else {
                      final chatProvider = context.read<ChatProvider>();
                      final targetId = profile.effectiveUserId;
                      final existingConv = chatProvider.conversations.firstWhere(
                        (c) =>
                            c.participantId == targetId ||
                            c.participantId == profile.id,
                        orElse: () => ChatConversation(
                          id: '',
                          participantId: '',
                          participantName: '',
                          lastMessage: '',
                          lastMessageTime: DateTime.now(),
                        ),
                      );
                      if (existingConv.id.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              conversationId: existingConv.id,
                              participantId: existingConv.participantId,
                              participantName: existingConv.participantName,
                              participantRole: existingConv.participantRole,
                              participantCompany: existingConv.participantCompany,
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
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          initialProfile: profile,
                          profileId: profile.id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👤', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final List<School> schools;
  final List<Batch> batches;
  final String? initialLocation;
  final String? initialCountry;
  final String? initialAssociation;
  final String? initialBatchYear;
  final String? initialJnvSchool;
  final bool initialOpenToMentor;

  final Function(
    String? location,
    String? country,
    String? association,
    String? batchYear,
    String? jnvSchool,
    bool openToMentor,
  ) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.schools,
    required this.batches,
    this.initialLocation,
    this.initialCountry,
    this.initialAssociation,
    this.initialBatchYear,
    this.initialJnvSchool,
    required this.initialOpenToMentor,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TextEditingController _locationController;
  late TextEditingController _countryController;
  String? _association;
  String? _batchYear;
  String? _jnvSchool;
  bool _openToMentor = false;

  final List<String> _associations = [
    'Alumni',
    'Student',
    'Teacher',
    'Staff',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation ?? '');
    _countryController = TextEditingController(text: widget.initialCountry ?? '');
    _association = widget.initialAssociation;
    _batchYear = widget.initialBatchYear;
    _jnvSchool = widget.initialJnvSchool;
    _openToMentor = widget.initialOpenToMentor;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Drag Indicator Handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Reset All',
                    style: TextStyle(
                      color: Color(0xFF132E5B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'City / State',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                prefixIcon: Icon(Icons.public_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _association,
              dropdownColor: colors.surface,
              decoration: const InputDecoration(
                labelText: 'Association',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: _associations.map((a) {
                return DropdownMenuItem<String>(value: a, child: Text(a));
              }).toList(),
              onChanged: (val) => setState(() => _association = val),
              hint: const Text('All Associations'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _batchYear,
              dropdownColor: colors.surface,
              decoration: const InputDecoration(
                labelText: 'Batch Year',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: widget.batches.map((b) {
                return DropdownMenuItem<String>(
                  value: b.startYear.toString(),
                  child: Text(b.displayName),
                );
              }).toList(),
              onChanged: (val) => setState(() => _batchYear = val),
              hint: const Text('All Batches'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _jnvSchool,
              dropdownColor: colors.surface,
              decoration: const InputDecoration(
                labelText: 'JNV School',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: widget.schools.take(100).map((s) {
                return DropdownMenuItem<String>(
                  value: s.jnvId,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() => _jnvSchool = val),
              hint: const Text('All Schools'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Open to Mentor only',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              value: _openToMentor,
              onChanged: (val) => setState(() => _openToMentor = val),
              activeColor: const Color(0xFF132E5B),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF132E5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onApply(
                    _locationController.text.trim().isNotEmpty
                        ? _locationController.text.trim()
                        : null,
                    _countryController.text.trim().isNotEmpty
                        ? _countryController.text.trim()
                        : null,
                    _association,
                    _batchYear,
                    _jnvSchool,
                    _openToMentor,
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

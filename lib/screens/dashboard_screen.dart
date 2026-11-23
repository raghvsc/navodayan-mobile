import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';
import 'connections_screen.dart';
import 'coordinator_dashboard_screen.dart';
import 'directory_screen.dart';
import 'offerings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _coordinators;
  Map<String, dynamic>? _circleData;
  Map<String, dynamic>? _thanksData;
  Map<String, dynamic>? _offeringsData;

  int _appreciationTab = 0;

  // Proof submission state
  bool _submittingProof = false;
  final TextEditingController _proofNoteController = TextEditingController();
  XFile? _selectedProofFile;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _proofNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getDashboardOverview(),
        _service.getMyCoordinators(),
        _service.getCircleInfo(),
        _service.getThanksSummary(),
        _service.getMyOfferings(),
      ]);

      if (mounted) {
        setState(() {
          _overview = results[0];
          _coordinators = results[1];
          _circleData = results[2];
          _thanksData = results[3];
          _offeringsData = results[4];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickProofImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() {
          _selectedProofFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    }
  }

  Future<void> _submitProof() async {
    if (_proofNoteController.text.trim().isEmpty && _selectedProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a note or select a document')),
      );
      return;
    }

    setState(() => _submittingProof = true);
    try {
      List<int>? bytes;
      String? fileName;
      if (_selectedProofFile != null) {
        bytes = await _selectedProofFile!.readAsBytes();
        fileName = _selectedProofFile!.name;
      }

      await _service.submitJnvProof(
        note: _proofNoteController.text.trim(),
        fileBytes: bytes != null ? Uint8List.fromList(bytes) : null,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof submitted successfully for verification')),
        );
        _proofNoteController.clear();
        setState(() => _selectedProofFile = null);
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingProof = false);
    }
  }

  Future<void> _confirmSuggestedCircle() async {
    try {
      await _service.confirmCircle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Circle confirmed!')),
        );
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm circle: $e')),
        );
      }
    }
  }

  void _showChangeCircleDialog(List<dynamic> circles) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select a Circle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: circles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final circle = circles[index];
                    final name = circle['name']?.toString() ?? '';
                    final desc = circle['description']?.toString() ?? '';
                    final key = circle['key']?.toString() ?? '';

                    return ListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: desc.isNotEmpty ? Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await _service.changeCircle(key);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Joined $name')),
                            );
                            _loadAll();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update circle: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = context.watch<AuthProvider>();

    final user = auth.user;
    final userName = user?.profile?.fullName ?? user?.email ?? 'Navodayan';
    final profileImg = user?.profile?.imageUrl;
    final hasProfileImg = profileImg != null && profileImg.isNotEmpty;
    final incoming = _overview?['incomingConnections'] ?? 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My Desk'),
        actions: const [
          CommonAppBarActions(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome & Greeting
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colors.primary,
                          backgroundImage: hasProfileImg ? NetworkImage(profileImg) : null,
                          child: !hasProfileImg
                              ? Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'N',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                () {
                                  final profile = _overview?['profile'] as Map<String, dynamic>?;
                                  final schoolName = profile?['schoolName']?.toString();
                                  final batchLabel = profile?['batchLabel']?.toString();
                                  if (schoolName != null && schoolName.isNotEmpty) {
                                    return batchLabel != null && batchLabel.isNotEmpty
                                        ? '$schoolName · $batchLabel'
                                        : schoolName;
                                  }
                                  return 'Welcome to your Navodayan member desk';
                                }(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Incoming connections banner
                    if (incoming is num && incoming > 0) ...[
                      Material(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_add_rounded, color: colors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$incoming connection ${incoming == 1 ? "request is" : "requests are"} waiting for you',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: colors.error, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 1. Account & Verification Card
                    _buildAccountCard(colors, user),
                    const SizedBox(height: 16),

                    // 2. Engagement Points & Profile Completeness Card
                    _buildPointsAndCompletenessCard(colors),
                    const SizedBox(height: 16),

                    // 3. My School & Coordinators Card
                    _buildSchoolCoordinatorsCard(colors),
                    const SizedBox(height: 16),

                    // 4. Your Batch Card
                    _buildBatchCard(colors),
                    const SizedBox(height: 16),

                    // 5. Your Circle Card
                    _buildCircleCard(colors),
                    const SizedBox(height: 16),

                    // 6. Appreciation Card (Received & Given)
                    _buildAppreciationCard(colors),
                    const SizedBox(height: 16),

                    // 7. Offerings Card
                    _buildOfferingsCard(colors),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // --- 1. Account Card ---
  Widget _buildAccountCard(ThemePalette colors, AuthUser? user) {
    final account = _overview?['account'] is Map ? _overview!['account'] as Map<String, dynamic> : {};
    final approvalStatus = (account['approvalStatus'] ?? user?.approvalStatus ?? user?.profile?.approvalStatus ?? 'PENDING_VERIFICATION').toString().toUpperCase();
    final verified = account['verified'] == true || user?.profile?.jnvVerified == true || user?.jnvVerified == true;
    final needsSchool = account['needsSchool'] == true;
    final note = account['note']?.toString();

    Color badgeColor;
    Color badgeTextColor;
    String statusLabel;

    if (verified || approvalStatus == 'ACTIVE') {
      badgeColor = colors.successBg;
      badgeTextColor = colors.success;
      statusLabel = 'Active';
    } else if (approvalStatus == 'REJECTED') {
      badgeColor = colors.errorBg;
      badgeTextColor = colors.error;
      statusLabel = 'Rejected';
    } else {
      badgeColor = Colors.orange.withValues(alpha: 0.12);
      badgeTextColor = Colors.orange.shade800;
      statusLabel = 'Pending Verification';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (verified)
              Text(
                'JNV association is verified by a coordinator or admin.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              )
            else if (needsSchool)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your JNV and batch so a coordinator or admin can verify your association.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile').then((_) => _loadAll());
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit profile'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              )
            else if (approvalStatus == 'REJECTED')
              Text(
                'Membership was not approved. Contact your JNV or batch coordinator for approval.',
                style: TextStyle(fontSize: 13, color: colors.error),
              )
            else
              Text(
                note ?? 'Your account is under verification by your JNV coordinator.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Proof of association section
            Text(
              'Proof of association with your JNV',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share how you are connected to this JNV. Add a short note, a document, or both. A document can be an email from the school, certificate, or record of your connection.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _proofNoteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a short note about your batch or house...',
                hintStyle: TextStyle(fontSize: 13, color: colors.textSecondary.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickProofImage(ImageSource.gallery),
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(_selectedProofFile == null ? 'Attach Document' : 'File Selected'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (_selectedProofFile != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _selectedProofFile = null),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: _submittingProof ? null : _submitProof,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _submittingProof
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Proof'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Photos are reduced to under 1 MB automatically.',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
            if (account['jnvVerification'] is Map && account['jnvVerification']['hasProof'] == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 16, color: colors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Document proof submitted for verification.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 2. Engagement Points & Profile Completeness Card ---
  Widget _buildPointsAndCompletenessCard(ThemePalette colors) {
    final activity = _overview?['activity'] as Map<String, dynamic>? ?? {};
    final profile = _overview?['profile'] as Map<String, dynamic>? ?? {};
    final points = activity['points'] ?? 0;
    final completeness = profile['completeness'] ?? 0;
    final checks = profile['checks'] as List? ?? [];
    final missing = checks
        .where((c) => c is Map && c['filled'] == false)
        .map((c) => c['label']?.toString().toLowerCase() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$points%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showPointsBreakdownDialog(colors, activity),
                          child: Icon(Icons.info_outline_rounded, size: 16, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile').then((_) => _loadAll());
                  },
                  child: const Text('Edit profile'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (completeness is num ? completeness.toDouble() : 0.0) / 100.0,
                minHeight: 8,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              missing.isNotEmpty
                  ? 'Profile is $completeness% complete. Still to add: ${missing.join(", ")}.'
                  : 'Profile is $completeness% complete. Every check is filled in.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointsBreakdownDialog(ThemePalette colors, Map<String, dynamic> activity) {
    final onSite = activity['onSite'] ?? 0;
    final signedIn = activity['signedIn'] ?? 0;
    final profile = activity['profile'] ?? 0;
    final help = activity['help'] ?? 0;
    final verifiedHours = activity['verifiedHours'] ?? 0;
    final money = activity['money'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How this percentage is calculated'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPointRow('On the site, $onSite of 15.', 'Added when your account is approved and your main JNV and batch are saved.', colors),
              const SizedBox(height: 12),
              _buildPointRow('Signed in, $signedIn of 15.', 'Added after you sign in at least once, once you are on the site.', colors),
              const SizedBox(height: 12),
              _buildPointRow('Profile, $profile of 20.', 'Complete earns 20; half-complete earns 10.', colors),
              const SizedBox(height: 12),
              _buildPointRow('Physical / Time contribution, $help of 40.', 'You have $verifiedHours verified hours at your JNV. 20 hours earns 40; 10 hours earns 20.', colors),
              const SizedBox(height: 12),
              _buildPointRow('Financial contribution, $money of 10.', 'Added for a verified payment. A pledge does not add points.', colors),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPointRow(String title, String desc, ThemePalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
      ],
    );
  }

  // --- 2. My School & Coordinators Card ---
  Widget _buildSchoolCoordinatorsCard(ThemePalette colors) {
    final schoolName = _overview?['profile']?['schoolName']?.toString() ?? 'Jawahar Navodaya Vidyalaya';
    final jnvCoords = _coordinators?['jnvCoordinators'] as List? ?? [];
    final batchCoords = _coordinators?['batchCoordinators'] as List? ?? [];
    final batchMessage = _coordinators?['batchMessage']?.toString();
    final canRequest = _coordinators?['canRequest'] == true || _coordinators?['canRequestBatch'] == true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    schoolName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // JNV Coordinator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JNV coordinator: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                Expanded(
                  child: Text(
                    jnvCoords.isNotEmpty
                        ? jnvCoords.map((c) => c['name'] ?? 'Alumnus').join(', ')
                        : 'No JNV coordinator for this school yet.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Batch Coordinator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch coordinator: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                Expanded(
                  child: Text(
                    batchCoords.isNotEmpty
                        ? batchCoords.map((c) => c['name'] ?? 'Alumnus').join(', ')
                        : 'No batch coordinator yet.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
              ],
            ),

            if (batchMessage != null && batchMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  batchMessage,
                  style: TextStyle(fontSize: 12, color: colors.textPrimary, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoordinatorDashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.people_outline_rounded, size: 16),
                  label: const Text('See coordinators'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                if (canRequest) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoordinatorDashboardScreen()),
                      );
                    },
                    child: const Text('Request to coordinate'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Your Batch Card ---
  Widget _buildBatchCard(ThemePalette colors) {
    final batch = _overview?['batch'] is Map ? _overview!['batch'] as Map<String, dynamic> : {};
    final activePercent = batch['activePercent'] ?? 0;
    final activeCount = batch['activeCount'] ?? 0;
    final totalCount = batch['totalCount'] ?? batch['peak'] ?? 80;
    final usingDefaultPeak = batch['usingDefaultPeak'] == true;

    final profile = _overview?['profile'] as Map<String, dynamic>?;
    final batchLabel = profile?['batchLabel']?.toString() ?? 'Your Batch';
    final jnvId = profile?['jnvId'];
    final batchId = profile?['batchId'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Batch: $batchLabel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$activePercent% Active',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Batchmates on this site: $activeCount / $totalCount',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (activePercent is num ? activePercent.toDouble() : 0.0) / 100.0,
                minHeight: 8,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(height: 6),

            if (usingDefaultPeak)
              Text(
                '80 is used as the highest count until a coordinator saves one.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DirectoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.groups_outlined, size: 16),
              label: const Text('See batchmates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Your Circle Card ---
  Widget _buildCircleCard(ThemePalette colors) {
    final circle = _circleData?['circle'] as Map<String, dynamic>?;
    final suggested = _circleData?['suggestedCircle'] as Map<String, dynamic>?;
    final available = _circleData?['availableCircles'] as List? ?? [];
    final needsProfession = _circleData?['needsProfession'] == true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: colors.secondary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Your Circle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (needsProfession) ...[
              Text(
                'Add a profession on your profile so we can suggest a community circle.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile').then((_) => _loadAll());
                },
                child: const Text('Edit profile to add profession'),
              ),
            ] else if (circle != null) ...[
              Text(
                'Confirmed circle:',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                circle['name']?.toString() ?? 'Community Circle',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              if (circle['description'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  circle['description'].toString(),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ] else if (suggested != null) ...[
              Text(
                'Suggested circle for your profession:',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                suggested['name']?.toString() ?? 'Suggested Circle',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.primary),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _confirmSuggestedCircle,
                child: const Text('Confirm Circle'),
              ),
            ] else ...[
              Text(
                'No circle is suggested for your profession yet. You can still pick one below.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],

            if (available.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _showChangeCircleDialog(available),
                child: Text(circle != null ? 'Change circle' : 'Select a circle'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 6. Appreciation Card (Received & Given) ---
  Widget _buildAppreciationCard(ThemePalette colors) {
    final received = _thanksData?['received'] is Map ? _thanksData!['received'] as Map<String, dynamic> : {};
    final given = _thanksData?['given'] is Map ? _thanksData!['given'] as Map<String, dynamic> : {};
    final receivedPoints = received['points'] ?? _thanksData?['totalPoints'] ?? 0;
    final receivedCount = received['count'] ?? _thanksData?['totalCount'] ?? 0;
    final givenCount = given['count'] ?? 0;
    final recentReceived = (received['recent'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final recentGiven = (given['recent'] as List? ?? []).whereType<Map<String, dynamic>>().toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: colors.secondary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Appreciation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented switch for Received / Given
            Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _appreciationTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _appreciationTab == 0 ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'Received ($receivedCount)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _appreciationTab == 0 ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _appreciationTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _appreciationTab == 1 ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'Given ($givenCount)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _appreciationTab == 1 ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_appreciationTab == 0) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$receivedPoints recognition points',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.secondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '·  $receivedCount appreciation${receivedCount == 1 ? "" : "s"}',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (recentReceived.isEmpty)
                Text(
                  'When another Navodayan appreciates you from your profile, it shows here.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                )
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReceived.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = recentReceived[idx];
                    final fromUser = item['fromUser'] as Map<String, dynamic>?;
                    final fromName = fromUser?['fullName'] ?? fromUser?['email'] ?? 'Member';
                    final category = item['categoryName'] ?? 'Appreciation';
                    final pts = item['pointsAwarded'] ?? 10;
                    final note = item['note']?.toString() ?? '';

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(fromName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                              Text(' · $category · ', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              Text('+$pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.primary)),
                            ],
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ] else ...[
              Text(
                '$givenCount appreciation${givenCount == 1 ? "" : "s"} sent',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 10),
              if (recentGiven.isEmpty)
                Text(
                  'Appreciations you send to other members will show here.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                )
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentGiven.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = recentGiven[idx];
                    final toUser = item['toUser'] as Map<String, dynamic>?;
                    final toName = toUser?['fullName'] ?? toUser?['email'] ?? 'Member';
                    final category = item['categoryName'] ?? 'Appreciation';
                    final pts = item['pointsAwarded'] ?? 10;
                    final note = item['note']?.toString() ?? '';

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(toName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                              Text(' · $category · ', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              Text('+$pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.primary)),
                            ],
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],

            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DirectoryScreen()),
                );
              },
              icon: const Icon(Icons.favorite_border_rounded, size: 16),
              label: const Text('Open another member to appreciate'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. Offerings Card ---
  Widget _buildOfferingsCard(ThemePalette colors) {
    final offerings = _offeringsData?['offering'] as List? ?? [];
    final hasOfferings = offerings.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Your Offerings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (hasOfferings) ...[
              Text(
                'You have ${offerings.length} published offering${offerings.length == 1 ? "" : "s"}.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ] else ...[
              Text(
                'You have not published an offering yet.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OfferingsScreen()),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Open offerings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


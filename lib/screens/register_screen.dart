import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/batch.dart';
import '../models/school.dart';
import '../providers/auth_provider.dart';
import '../services/schools_batches_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final SchoolsBatchesService _schoolsBatchesService = SchoolsBatchesService();

  List<School> _schools = [];
  List<Batch> _batches = [];
  bool _loadingMeta = true;

  School? _selectedSchool;
  Batch? _selectedBatch;
  bool _openToMentor = false;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _registrationSuccess = false;
  String? _registeredEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() => _loadingMeta = true);
    try {
      final results = await Future.wait([
        _schoolsBatchesService.getSchools(),
        _schoolsBatchesService.getBatches(),
      ]);
      if (mounted) {
        setState(() {
          _schools = results[0] as List<School>;
          _batches = results[1] as List<Batch>;
          _loadingMeta = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMeta = false);
      }
    }
  }

  void _showSchoolSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return _SchoolSearchDialog(
          schools: _schools,
          onSchoolSelected: (school) {
            setState(() {
              _selectedSchool = school;
            });
          },
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSchool == null) {
      setState(() => _errorMessage = 'Please select your JNV school');
      return;
    }

    if (_selectedBatch == null) {
      setState(() => _errorMessage = 'Please select your batch year');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      await auth.register({
        'fullName': _nameController.text.trim(),
        'email': email,
        'password': _passwordController.text,
        'jnvSchool': _selectedSchool!.jnvId,
        'batchId': _selectedBatch!.id,
        'openToMentor': _openToMentor,
      });

      if (mounted) {
        setState(() {
          _registeredEmail = email;
          _registrationSuccess = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Join Navodayan Community'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _registrationSuccess ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final colors = AppColors.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: colors.success,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a verification link to $_registeredEmail. Please verify your email before logging in.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'After verification, an admin will review your profile before full directory access is enabled.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Go to Login'),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: isDark ? const EdgeInsets.all(10) : EdgeInsets.zero,
            decoration: isDark
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Image.asset(
              'assets/navodayan_logo.png',
              height: 64,
              width: 64,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Join the Navodayan Community',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Connect with fellow Navodayans and grow together.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: colors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'rahul@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _loadingMeta ? null : _showSchoolSearchDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined, color: colors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedSchool?.displayName ??
                              (_loadingMeta ? 'Loading schools...' : 'Select JNV School'),
                          style: TextStyle(
                            color: _selectedSchool != null
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Batch>(
                initialValue: _selectedBatch,
                dropdownColor: colors.surface,
                decoration: const InputDecoration(
                  labelText: 'Batch Year',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: _batches.map((batch) {
                  return DropdownMenuItem<Batch>(
                    value: batch,
                    child: Text(batch.displayName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedBatch = val),
                hint: Text(_loadingMeta ? 'Loading batches...' : 'Select batch year'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I am open to mentoring other Navodayans',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  value: _openToMentor,
                  onChanged: (val) => setState(() => _openToMentor = val),
                  activeThumbColor: colors.primary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _handleRegister,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Join Network'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already a Navodayan? ",
              style: TextStyle(color: colors.textSecondary),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Login',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SchoolSearchDialog extends StatefulWidget {
  final List<School> schools;
  final ValueChanged<School> onSchoolSelected;

  const _SchoolSearchDialog({
    required this.schools,
    required this.onSchoolSelected,
  });

  @override
  State<_SchoolSearchDialog> createState() => _SchoolSearchDialogState();
}

class _SchoolSearchDialogState extends State<_SchoolSearchDialog> {
  final _searchController = TextEditingController();
  List<School> _filteredSchools = [];

  @override
  void initState() {
    super.initState();
    _filteredSchools = widget.schools;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSchools = widget.schools.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.distt.toLowerCase().contains(query) ||
            (s.state?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Select JNV School',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by school, district, state...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredSchools.isEmpty
                    ? Center(
                        child: Text(
                          'No schools found',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSchools.length,
                        itemBuilder: (ctx, i) {
                          final school = _filteredSchools[i];
                          return ListTile(
                            title: Text(school.name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${school.distt}${school.state != null ? ', ${school.state!.name}' : ''}',
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            onTap: () {
                              widget.onSchoolSelected(school);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

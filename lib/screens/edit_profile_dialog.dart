import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class EditProfileDialog extends StatefulWidget {
  final Profile currentProfile;
  final VoidCallback onSaved;

  const EditProfileDialog({
    super.key,
    required this.currentProfile,
    required this.onSaved,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final ProfileService _profileService = ProfileService();

  late TextEditingController _roleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _countryController;
  late TextEditingController _industryController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late bool _openToMentor;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _roleController = TextEditingController(text: p.currentRole ?? '');
    _companyController = TextEditingController(text: p.company ?? '');
    _locationController = TextEditingController(text: p.location ?? '');
    _countryController = TextEditingController(text: p.country ?? '');
    _industryController = TextEditingController(text: p.industry ?? '');
    _experienceController = TextEditingController(text: p.experience ?? '');
    _bioController = TextEditingController(text: p.bio ?? '');
    _skillsController = TextEditingController(text: p.skills.map((s) => s.name).join(', '));
    _openToMentor = p.openToMentor;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _countryController.dispose();
    _industryController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final rawSkills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final payload = <String, dynamic>{
        'currentRole': _roleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'country': _countryController.text.trim(),
        'industry': _industryController.text.trim(),
        'experience': _experienceController.text.trim(),
        'bio': _bioController.text.trim(),
        'openToMentor': _openToMentor,
        'skills': rawSkills,
      };

      await _profileService.updateProfile(payload, token: auth.token!);
      await auth.fetchCurrentUser();

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppColors.of(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField('Current Role / Job Title', _roleController, 'e.g. Software Engineer', colors),
                    const SizedBox(height: 12),
                    _buildTextField('Company / Organization', _companyController, 'e.g. Google, TCS, Startup', colors),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('City / Location', _locationController, 'e.g. Bengaluru', colors),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField('Country', _countryController, 'e.g. India', colors),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Industry / Domain', _industryController, 'e.g. Technology, Healthcare', colors),
                    const SizedBox(height: 12),
                    _buildTextField('Years of Experience', _experienceController, 'e.g. 5+ Years', colors),
                    const SizedBox(height: 12),
                    _buildTextField('About / Bio', _bioController, 'Tell fellow alumni about yourself...', colors, maxLines: 3),
                    const SizedBox(height: 12),
                    _buildTextField('Skills (comma-separated)', _skillsController, 'e.g. Flutter, React, Cloud, Finance', colors),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.school_rounded, color: colors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Open to Mentoring',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Help students and alumni with guidance',
                                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _openToMentor,
                            activeThumbColor: colors.primary,
                            activeTrackColor: colors.primary.withValues(alpha: 0.3),
                            onChanged: (val) => setState(() => _openToMentor = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    ThemePalette colors, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

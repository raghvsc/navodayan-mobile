import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_crop_dialog.dart';

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
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _roleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _countryController;
  late TextEditingController _industryController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late bool _openToMentor;

  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  bool _uploadingPhoto = false;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _uploadedImageUrl = p.imageUrl;
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

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      // Show interactive cropping preview dialog
      final cropped = await ImageCropDialog.show(context, bytes);
      if (cropped == null) return;

      setState(() {
        _selectedImageBytes = cropped;
        _uploadingPhoto = true;
      });

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        final newUrl = await _profileService.uploadProfilePhoto(cropped, token: auth.token!);
        if (mounted) {
          final successColor = AppColors.of(context).success;
          setState(() {
            _uploadedImageUrl = newUrl;
            _uploadingPhoto = false;
          });
          await auth.fetchCurrentUser();
          widget.onSaved();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile photo updated successfully! (<= 10 KB)'),
                backgroundColor: successColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
          _errorMessage = 'Failed to upload photo: $e';
        });
      }
    }
  }

  void _showImageSourceSheet() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: colors.primary),
                  ),
                  title: Text('Take Photo', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Capture new photo with Camera', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndCropImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_rounded, color: colors.secondary),
                  ),
                  title: Text('Choose from Gallery', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Pick an existing photo from Gallery', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndCropImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
                    // Profile Photo section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _uploadingPhoto ? null : _showImageSourceSheet,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colors.primary, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 44,
                                    backgroundColor: colors.primary.withValues(alpha: 0.15),
                                    backgroundImage: _selectedImageBytes != null
                                        ? MemoryImage(_selectedImageBytes!)
                                        : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                                            ? NetworkImage(_uploadedImageUrl!) as ImageProvider
                                            : null,
                                    child: (_selectedImageBytes == null && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty))
                                        ? Text(
                                            widget.currentProfile.fullName.isNotEmpty
                                                ? widget.currentProfile.fullName[0].toUpperCase()
                                                : 'N',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _uploadingPhoto ? null : _showImageSourceSheet,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colors.surface, width: 2),
                                    ),
                                    child: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _uploadingPhoto ? null : _showImageSourceSheet,
                            icon: const Icon(Icons.photo_camera_rounded, size: 16),
                            label: Text(
                              _uploadingPhoto ? 'Optimizing & Uploading (max 10 KB)...' : 'Change Profile Picture',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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

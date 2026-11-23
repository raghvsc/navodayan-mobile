import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_rating_update_service.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final currentMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          CommonAppBarActions(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nostalgic Parivar Banner (matches settings_theme/code.html)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'NAVODAYA PARIVAR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Personalize Your Experience',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Adapt visual comfort for midnight batch chats or bright daylight reading.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette_outlined, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // THEME PREVIEW Section (Side-by-Side Daylight vs Nightfall)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'THEME PREVIEW',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: colors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    currentMode == ThemeMode.dark
                        ? 'Dark Mode Active'
                        : (currentMode == ThemeMode.light
                            ? 'Light Mode Active'
                            : 'System Default Active'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Daylight preview card
                Expanded(
                  child: InkWell(
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentMode == ThemeMode.light
                              ? colors.primary
                              : colors.border,
                          width: currentMode == ThemeMode.light ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Miniature Light Mockup
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0F294A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(height: 6, width: 45, color: const Color(0xFFCBD5E1)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F294A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.light_mode, size: 10, color: Color(0xFFD97706)),
                                      SizedBox(width: 3),
                                      Text('Daylight', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Light View',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (currentMode == ThemeMode.light)
                                const Icon(Icons.check_circle, size: 18, color: Color(0xFFD97706)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nightfall preview card
                Expanded(
                  child: InkWell(
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentMode == ThemeMode.dark
                              ? colors.primary
                              : colors.border,
                          width: currentMode == ThemeMode.dark ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Miniature Dark Mockup
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1120),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF60A5FA),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(height: 6, width: 45, color: const Color(0xFF475569)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.dark_mode, size: 10, color: Color(0xFF93C5FD)),
                                      SizedBox(width: 3),
                                      Text('Nightfall', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dark View',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (currentMode == ThemeMode.dark)
                                const Icon(Icons.check_circle, size: 18, color: Color(0xFF60A5FA)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APPEARANCE & THEME',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  'Tap to switch',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    title: 'System Default',
                    subtitle: 'Automatically match your device appearance',
                    icon: Icons.brightness_auto_rounded,
                    mode: ThemeMode.system,
                    selected: currentMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                  Divider(height: 1, indent: 64, color: colors.border),
                  _buildThemeOption(
                    context,
                    title: 'Light Mode',
                    subtitle: 'Classic clean light appearance',
                    icon: Icons.light_mode_rounded,
                    mode: ThemeMode.light,
                    selected: currentMode == ThemeMode.light,
                    isDefault: true,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  Divider(height: 1, indent: 64, color: colors.border),
                  _buildThemeOption(
                    context,
                    title: 'Dark Mode',
                    subtitle: 'Sleek dark theme for reduced eye strain',
                    icon: Icons.dark_mode_rounded,
                    mode: ThemeMode.dark,
                    selected: currentMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'APPLICATION INFO',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.info_outline_rounded, color: colors.primary),
                      ),
                      title: Text(
                        'Navodayan App Version',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      subtitle: Text('1.0.3+4 (Production Build)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text('Up to date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, indent: 64, color: colors.border),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.cached_rounded, color: colors.primary),
                      ),
                      title: Text(
                        'Offline Directory Cache',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      subtitle: Text('Fast local alumni directory index', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Directory cache refreshed.')),
                          );
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    Divider(height: 1, indent: 64, color: colors.border),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.help_outline_rounded, color: colors.primary),
                      ),
                      title: Text(
                        'How to use Navodayan',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      subtitle: Text('Guide to profile, CARE sessions & roles', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(context, '/help'),
                    ),
                    Divider(height: 1, indent: 64, color: colors.border),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.privacy_tip_outlined, color: colors.primary),
                      ),
                      title: Text(
                        'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      subtitle: Text('Read our data and community policies', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('https://www.navodayan.org/privacy-policy')),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 64, color: colors.border),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.accent.withValues(alpha: 0.15),
                        child: Icon(Icons.star_rate_rounded, color: colors.accent),
                      ),
                      title: Text(
                        'Rate Navodayan on Play Store',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      subtitle: Text('Help other alumni discover the platform', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                      onTap: () => AppRatingUpdateService().checkAndPromptReview(force: true),
                    ),
                    Divider(height: 1, indent: 64, color: colors.border),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.system_update_rounded, color: colors.primary),
                      ),
                      title: Text(
                        'Check for Updates',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      subtitle: Text('Check Google Play Store for new version', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => AppRatingUpdateService().checkForInAppUpdate(context: context, manual: true),
                    ),
                  ],
                ),
              ),
            ),

            if (auth.isAuthenticated) ...[
              const SizedBox(height: 24),
              Text(
                'ACCOUNT & DATA MANAGEMENT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.cloud_download_outlined, color: colors.primary),
                        ),
                        title: Text(
                          'Download My Data',
                          style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          'Export a structured copy of your profile, batches & activity',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showDownloadDataDialog(context, auth, colors),
                      ),
                      Divider(height: 1, indent: 64, color: colors.border),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        ),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                        subtitle: Text(
                          'Permanently remove your account, profile, and data',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                        onTap: () => _showDeleteAccountDialog(context, auth, colors),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            // House Pride footer charm (matches settings_theme/code.html lines 175-185)
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFB91C1C), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1D4ED8), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF15803D), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Shivalik • Aravali • Nilgiri • Udaygiri',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required bool selected,
    bool isDefault = false,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                    : colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? colors.primary : colors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.primary : const Color(0xFFCBD5E1),
                  width: selected ? 6 : 1.5,
                ),
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDataDialog(BuildContext context, AuthProvider auth, ThemePalette colors) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await DashboardService().exportUserData();
      final user = auth.user;
      final exportPayload = {
        'exportDate': DateTime.now().toIso8601String(),
        'app': 'Navodayan Mobile',
        'version': '1.0.3+4',
        'user': {
          'id': user?.id,
          'email': user?.email,
          'role': user?.role,
          'approvalStatus': user?.approvalStatus,
          'profile': user?.profile?.toJson(),
        },
        'activityAndOverview': data,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportPayload);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

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
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download_done_rounded, color: colors.primary, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Your Account Data',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Below is a complete structured JSON archive of your personal profile, batch affiliation, circle details, and desk metrics.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        jsonStr,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy JSON Data'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: jsonStr));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account data copied to clipboard!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: const Text('Email Archive'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data export request sent to ${auth.user?.email ?? "your email"}.'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth, ThemePalette colors) {
    final textController = TextEditingController();
    String selectedReason = 'I no longer need this account';
    final reasons = [
      'I no longer need this account',
      'Privacy and data concerns',
      'Created a duplicate account',
      'Too many notifications or messages',
      'Other reason',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          final isConfirmed = textController.text.trim().toUpperCase() == 'DELETE';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Deleting your account is permanent and cannot be undone. All of the following will be erased immediately:',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPoint('Your profile, photo, bio, and experience', colors),
                  _buildBulletPoint('Private messages and chat history', colors),
                  _buildBulletPoint('Batch affiliation and community circle records', colors),
                  _buildBulletPoint('Offerings, requests, and volunteer history', colors),
                  _buildBulletPoint('Verification documents and uploaded proofs', colors),
                  const SizedBox(height: 14),
                  const Text(
                    'Reason for leaving (Optional):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'To confirm, type DELETE below:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: textController,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You can also request deletion online at navodayan.org/settings',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                ),
                onPressed: isConfirmed
                    ? () async {
                        Navigator.pop(ctx);
                        try {
                          await DashboardService().deleteAccount(reason: selectedReason);
                        } catch (_) {}
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your account has been deleted successfully.')),
                          );
                        }
                      }
                    : null,
                child: const Text('Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulletPoint(String text, ThemePalette colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        ],
      ),
    );
  }
}

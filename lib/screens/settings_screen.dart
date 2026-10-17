import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'APPEARANCE & THEME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) themeProvider.setThemeMode(mode);
                },
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
            ),
            const SizedBox(height: 28),
            Text(
              'APPLICATION INFO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.info_outline_rounded, color: colors.primary),
                ),
                title: Text(
                  'Navodayan App Version',
                  style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                subtitle: Text('1.0.1+2 (Production Build)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ),
            ),
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
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.background,
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<ThemeMode>(
              value: mode,
              activeColor: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: isDark ? const EdgeInsets.all(12) : EdgeInsets.zero,
                    decoration: isDark
                        ? BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Image.asset(
                      'assets/navodayan_logo.png',
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'WHO WE ARE',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connecting Navodayans Across the Globe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The premier alumni network for Jawahar Navodaya Vidyalaya graduates, dedicated to fostering lifelong connections, professional growth, and giving back.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 32),

                // Mission Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: colors.brandGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark ? Border.all(color: colors.border) : null,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: isDark ? 0.15 : 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Our Core Mission',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'To empower Navodayans worldwide by providing a secure and accessible platform for alumni networking, mentorship, career acceleration, and community initiatives.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Ecosystem Section
                Text(
                  'Our Ecosystem',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPillarCard(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Students',
                  desc: 'Access guidance from seniors across different professions, guidance for competitive exams, and career pathways.',
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                _buildPillarCard(
                  context,
                  icon: Icons.groups_rounded,
                  title: 'Alumni',
                  desc: 'Reconnect with batchmates, discover alumni in your city, collaborate professionally, and mentor junior graduates.',
                  color: colors.secondary,
                ),
                const SizedBox(height: 12),
                _buildPillarCard(
                  context,
                  icon: Icons.favorite_rounded,
                  title: 'Teachers & Staff',
                  desc: 'Stay connected with former students and witness the far-reaching impact of your mentorship and teachings.',
                  color: colors.accent,
                ),
                const SizedBox(height: 40),

                // Join callout
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ready to Reconnect?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your profile today and find alumni living and working near you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text('Join Navodayan Network'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillarCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.4,
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

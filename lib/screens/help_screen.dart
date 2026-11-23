import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Help & Guide'),
        actions: const [
          CommonAppBarActions(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOR NEW MEMBERS & ALUMNI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How to use Navodayan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Step-by-step guidance on setting up your profile, connecting with batchmates, CARE knowledge sessions, mentorship, and coordinator roles.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              number: '1',
              title: 'Join and get in',
              content: [
                'Create an account with your active email address.',
                'Use the 6-digit verification code or email link to verify your email.',
                'Log in securely with your password. Your session remains saved on this device.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '2',
              title: 'Finish your profile',
              content: [
                'Select your JNV school and 12th passing batch year so batchmates can find you.',
                'Add your current profession and location to receive tailored circle suggestions and mentorship matches.',
                'Upload a short note or document on "My Desk" for JNV verification by your school coordinator.',
                'Adjust contact visibility (Email & Phone) under Settings to protect your privacy.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '3',
              title: 'Find people',
              content: [
                'Open Directory to browse verified Navodayans across 660+ JNV schools worldwide.',
                'Filter by School, Batch year, State, or Professional field.',
                'Send connection requests to batchmates and seniors.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '4',
              title: 'Connect and find a mentor',
              content: [
                'Once another member accepts your connection request, 1-on-1 private messaging unlocks.',
                'Browse the Mentorship section to find alumni available for competitive exam guidance, resume reviews, and career counseling.',
                'Send a personalized mentorship introduction note explaining what you want to achieve.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '5',
              title: 'Events & Reunions',
              content: [
                'Stay updated on national conventions, regional chapter meets, and virtual webinars.',
                'Join the Community Lounge for informal audio/video batch catchups and discussions.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '6',
              title: 'Navodayan CARE sessions',
              content: [
                'CARE (Careers And Real Experience) offers year-round knowledge sessions on competitive exams (UPSC, JEE, NEET, CA, Patwari) and industry skills.',
                'Request a topic you want to learn, or volunteer to lead a session for students and juniors.',
                'Mark your interest to be notified as soon as date and session coordinator are scheduled.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '7',
              title: 'Offerings and contributions',
              content: [
                'Offerings: Verified members can post up to 5 offerings (business services, hiring, freelancing, or mentorship programs).',
                'Contributions: Record money or volunteering hours given to a school welfare campaign. School coordinators verify each submission before it counts toward campaign totals.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '8',
              title: 'Coordinators',
              content: [
                'Batch Coordinator: Looks after one batch at one JNV.',
                'JNV Coordinator: Looks after school events, approvals, and fund campaigns for the entire school.',
                'State / National / International Coordinators: Support cross-regional alumni chapters.',
                'If your school has no JNV coordinator, tap "Request to coordinate" on your Desk or Coordinators page.',
              ],
              colors: colors,
            ),
            const SizedBox(height: 24),

            // Contact support footer
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.border),
              ),
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Icon(Icons.headset_mic_outlined, size: 36, color: colors.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Need help with your account?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get in touch with the Navodayan volunteer coordination team.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/contact'),
                      child: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required List<String> content,
    required ThemePalette colors,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: ExpansionTile(
        initiallyExpanded: number == '1' || number == '6',
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primary),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        children: content.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


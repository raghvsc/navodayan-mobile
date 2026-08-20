import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/meeting_screen.dart';

class CommunityLoungeButton extends StatelessWidget {
  final Color? iconColor;

  const CommunityLoungeButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return IconButton(
      tooltip: 'Community Lounge',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.videocam_rounded,
            size: 24,
            color: iconColor ?? Theme.of(context).appBarTheme.foregroundColor,
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      onPressed: () {
        if (!auth.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to join Community Lounge')),
          );
          Navigator.pushNamed(context, '/login');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MeetingScreen(),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';

/// Standard Notification Bell action button with real-time unread badge.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final unread = notifProvider.unreadCount;

    return IconButton(
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
    );
  }
}

/// Standard User Profile Avatar menu button.
/// Displays user avatar and popup menu when authenticated, or login action when guest.
class UserProfileMenuButton extends StatelessWidget {
  const UserProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return TextButton(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(40, 36),
        ),
        child: Text(
          'Login',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
      );
    }

    final user = auth.user;
    final fullName = user?.profile?.fullName?.trim();
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (user?.email.isNotEmpty == true ? user!.email : 'Navodayan Member');

    final initial = (fullName != null && fullName.isNotEmpty)
        ? fullName[0].toUpperCase()
        : (user?.email.isNotEmpty == true ? user!.email[0].toUpperCase() : 'U');

    final imageUrl = user?.profile?.imageUrl;

    return PopupMenuButton<String>(
      tooltip: 'User Profile & Menu',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.surface,
      icon: CircleAvatar(
        radius: 17,
        backgroundColor: colors.primary,
        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? Text(
                initial,
                style: TextStyle(
                  color: isDark ? const Color(0xFF0B1120) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              )
            : null,
      ),
      itemBuilder: (ctx) {
        return [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (user?.email != null && user!.email.isNotEmpty && user.email != displayName)
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text('Profile', style: TextStyle(color: colors.textPrimary)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'connections',
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text('My Connections', style: TextStyle(color: colors.textPrimary)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'contributions',
            child: Row(
              children: [
                Icon(Icons.volunteer_activism_outlined, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text('Contributions', style: TextStyle(color: colors.textPrimary)),
              ],
            ),
          ),
          if (user?.isCoordinator == true || user?.isAdmin == true)
            PopupMenuItem(
              value: 'coordinator',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Coordinator Portal', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'chat_requests',
            child: Row(
              children: [
                Icon(Icons.mark_chat_unread_outlined, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text('Chat Requests', style: TextStyle(color: colors.textPrimary)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text('Settings & Theme', style: TextStyle(color: colors.textPrimary)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: colors.error, size: 18),
                const SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: colors.error)),
              ],
            ),
          ),
        ];
      },
      onSelected: (val) {
        if (val == 'logout') {
          auth.logout();
        } else if (val == 'profile') {
          Navigator.pushNamed(context, '/profile');
        } else if (val == 'connections') {
          Navigator.pushNamed(context, '/connections');
        } else if (val == 'contributions') {
          Navigator.pushNamed(context, '/contributions');
        } else if (val == 'coordinator') {
          Navigator.pushNamed(context, '/coordinator');
        } else if (val == 'chat_requests') {
          Navigator.pushNamed(context, '/chats', arguments: 1);
        } else if (val == 'settings') {
          Navigator.pushNamed(context, '/settings');
        }
      },
    );
  }
}

/// Convenience composite widget placing NotificationBell and UserProfile menu side-by-side.
class CommonAppBarActions extends StatelessWidget {
  const CommonAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationBellButton(),
        UserProfileMenuButton(),
        SizedBox(width: 8),
      ],
    );
  }
}

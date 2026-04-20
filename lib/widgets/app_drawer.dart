// flutter_app/lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kredai/screens/auth_screen.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(AppConstants.primaryColorValue),
            ),
            accountName: Text(
              authState.user?.displayName ?? 'Guest User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              authState.user?.email ?? 'No email',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _getInitials(
                    authState.user?.displayName, authState.user?.email),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.dashboard,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    // Already on dashboard, so no navigation needed
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.settings,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & Support coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout at bottom (direct logout, no dialog)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Color(AppConstants.dangerColorValue),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(AppConstants.dangerColorValue),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    // Close drawer immediately
                    Navigator.pop(context);

                    // Capture NavigatorState before any await so we can safely check mounted later
                    final NavigatorState parentNavigator = Navigator.of(context);

                    // Call signOut (returns bool success)
                    final bool success = await ref.read(authProvider.notifier).signOut();

                    // Only navigate if the navigator is still mounted
                    if (!parentNavigator.mounted) return;

                    if (success) {
                      parentNavigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (c) => const AuthScreen()),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      // If sign out failed, show a simple SnackBar (safe because parentNavigator is mounted)
                      ScaffoldMessenger.of(parentNavigator.context).showSnackBar(
                        const SnackBar(content: Text('Logout failed. Please try again.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.substring(0, 1).toUpperCase();
    } else if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    return 'G';
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KredAI - Credit Risk Assessment'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text(
              'An AI-powered credit risk assessment system designed for the underbanked population in India.',
            ),
            SizedBox(height: 8),
            Text('Built with Federated Learning and Explainable AI.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// flutter_app/lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing),
        children: [
          // Profile Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(AppConstants.primaryColorValue),
                child: Text(
                  _getInitials(authState.user?.displayName, authState.user?.email),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                authState.user?.displayName ?? 'Anonymous User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(authState.user?.email ?? 'No Email'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile edit feature coming soon!'),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: spacing * 2),

          // App Settings
          _buildSettingsSection(
            context,
            "App Settings",
            [
              _buildSettingsTile(
                context,
                Icons.language,
                "Language",
                "English",
                () => _showLanguageDialog(context),
              ),
              _buildSettingsTile(
                context,
                Icons.dark_mode,
                "Theme",
                "Light",
                () => _showThemeDialog(context),
              ),
              _buildSettingsTile(
                context,
                Icons.notifications,
                "Notifications",
                "On",
                () => _showNotificationSettings(context),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Security Settings
          _buildSettingsSection(
            context,
            "Security",
            [
              _buildSettingsTile(
                context,
                Icons.fingerprint,
                "Biometric Login",
                "Off",
                () => _showBiometricSettings(context),
              ),
              _buildSettingsTile(
                context,
                Icons.lock,
                "Change Password",
                "",
                () => _changePassword(context),
              ),
              _buildSettingsTile(
                context,
                Icons.security,
                "Two-Factor Authentication",
                "Off",
                () => _show2FASettings(context),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Data & Privacy
          _buildSettingsSection(
            context,
            "Data & Privacy",
            [
              _buildSettingsTile(
                context,
                Icons.privacy_tip,
                "Privacy Policy",
                "",
                () => _showPrivacyPolicy(context),
              ),
              _buildSettingsTile(
                context,
                Icons.description,
                "Terms of Service",
                "",
                () => _showTermsOfService(context),
              ),
              _buildSettingsTile(
                context,
                Icons.delete_outline,
                "Delete Account",
                "",
                () => _showDeleteAccountDialog(context, ref),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Support
          _buildSettingsSection(
            context,
            "Support",
            [
              _buildSettingsTile(
                context,
                Icons.help_outline,
                "Help Center",
                "",
                () => _showHelp(context),
              ),
              _buildSettingsTile(
                context,
                Icons.feedback,
                "Send Feedback",
                "",
                () => _sendFeedback(context),
              ),
              _buildSettingsTile(
                context,
                Icons.info_outline,
                "About App",
                "Version 1.0.0",
                () => _showAbout(context),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(AppConstants.primaryColorValue),
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(AppConstants.primaryColorValue)),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              leading: Radio(
                  value: 'en', groupValue: 'en', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text("Hindi"),
              leading: Radio(
                  value: 'hi', groupValue: 'en', onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Theme"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Light"),
              leading: Radio(
                  value: 'light', groupValue: 'light', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text("Dark"),
              leading: Radio(
                  value: 'dark', groupValue: 'light', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text("System Default"),
              leading: Radio(
                  value: 'system', groupValue: 'light', onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification settings coming soon!")),
    );
  }

  void _showBiometricSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Biometric settings coming soon!")),
    );
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password change feature coming soon!")),
    );
  }

  void _show2FASettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("2FA settings coming soon!")),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Privacy Policy coming soon!")),
    );
  }

  void _showTermsOfService(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Terms of Service coming soon!")),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account deletion feature coming soon!"),
                ),
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Color(AppConstants.dangerColorValue)),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Help Center coming soon!")),
    );
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback feature coming soon!")),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About App"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KredAI - Credit Risk Assessment'),
            SizedBox(height: 8),
            Text("Version: 1.0.0"),
            SizedBox(height: 8),
            Text(
              "An AI-powered credit risk assessment system designed for the underbanked population in India.",
            ),
            SizedBox(height: 8),
            Text("Built with Federated Learning and Explainable AI."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

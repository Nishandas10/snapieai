import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/ai_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  void _loadApiKey() {
    final apiKey = StorageService.getApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // API Key Section
          _SettingsSection(
            title: 'AI Configuration',
            children: [
              _SettingsTile(
                icon: Icons.key,
                title: 'OpenAI API Key',
                subtitle: _apiKeyController.text.isEmpty
                    ? 'Not configured'
                    : '••••••••••${_apiKeyController.text.substring(_apiKeyController.text.length - 4)}',
                onTap: () => _showApiKeyDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Account Section
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingsTile(
                icon: Icons.person,
                title: 'Edit Profile',
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              _SettingsTile(
                icon: Icons.flag,
                title: 'Goals & Targets',
                onTap: () {
                  // TODO: Navigate to goals
                },
              ),
              _SettingsTile(
                icon: Icons.health_and_safety,
                title: 'Health Conditions',
                onTap: () {
                  // TODO: Navigate to health conditions
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notifications Section
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsToggle(
                icon: Icons.notifications,
                title: 'Meal Reminders',
                value: true,
                onChanged: (value) {
                  // TODO: Toggle notifications
                },
              ),
              _SettingsToggle(
                icon: Icons.water_drop,
                title: 'Water Reminders',
                value: false,
                onChanged: (value) {
                  // TODO: Toggle water reminders
                },
              ),
              _SettingsToggle(
                icon: Icons.insights,
                title: 'Weekly Summary',
                value: true,
                onChanged: (value) {
                  // TODO: Toggle weekly summary
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // App Section
          _SettingsSection(
            title: 'App',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Appearance',
                subtitle: 'System default',
                onTap: () {
                  // TODO: Show appearance dialog
                },
              ),
              _SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  // TODO: Show language dialog
                },
              ),
              _SettingsTile(
                icon: Icons.straighten,
                title: 'Units',
                subtitle: 'Metric (kg, cm)',
                onTap: () {
                  // TODO: Show units dialog
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data Section
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                icon: Icons.download,
                title: 'Export Data',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export feature coming soon!'),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                titleColor: AppColors.error,
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // About Section
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              _SettingsTile(
                icon: Icons.article,
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Logout button
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Implement logout
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenAI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your OpenAI API key to enable AI features like food analysis, meal planning, and chat.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: !_showApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // API Key is now irrelevant as we use Cloud Functions
              Navigator.pop(context);

              // final aiService = ref.read(aiServiceProvider);
              // aiService.setApiKey(_apiKeyController.text);
              // Navigator.pop(context);
              // ScaffoldMessenger.of(
              //   context,
              // ).showSnackBar(const SnackBar(content: Text('API key saved!')));
              // setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all your food logs, profile data, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await StorageService.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/onboarding');
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: titleColor ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

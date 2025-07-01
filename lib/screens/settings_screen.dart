// screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsSection('Connection', [
              _buildSettingsItem(
                Icons.device_hub,
                'Mesh Network',
                'Configure mesh settings',
              ),
              _buildSettingsItem(
                Icons.router,
                'Local Server',
                'Server connection settings',
              ),
              _buildSettingsItem(
                Icons.wifi,
                'Network Preferences',
                'Connection priority',
              ),
            ]),
            _buildSettingsSection('Profile', [
              _buildSettingsItem(
                Icons.person,
                'User Role',
                'Change your community role',
              ),
              _buildSettingsItem(
                Icons.language,
                'Language',
                'App language settings',
              ),
              _buildSettingsItem(
                Icons.mosque,
                'Community',
                'Local mosque/community settings',
              ),
            ]),
            _buildSettingsSection('Emergency', [
              _buildSettingsItem(
                Icons.contact_emergency,
                'Emergency Contacts',
                'Manage emergency contacts',
              ),
              _buildSettingsItem(
                Icons.location_on,
                'Location Sharing',
                'Location privacy settings',
              ),
              _buildSettingsItem(
                Icons.notifications,
                'Alert Settings',
                'Notification preferences',
              ),
            ]),
            _buildSettingsSection('About', [
              _buildSettingsItem(Icons.info, 'App Info', 'Version and credits'),
              _buildSettingsItem(
                Icons.help,
                'Help & Support',
                'User guide and support',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        ...items,
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF2E7D32)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to specific settings page
        },
      ),
    );
  }
}

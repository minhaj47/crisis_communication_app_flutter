// screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:new_project/models/app_models.dart';
import 'package:new_project/utils/app_constants.dart';

class RoleSelectionScreen extends StatefulWidget {
  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Role'),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select your role in the community:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This helps us prioritize messages and provide relevant features.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: UserRole.values.map(_buildRoleOption).toList(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedRole != null ? _proceedToHome : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(UserRole role) {
    return Card(
      child: RadioListTile<UserRole>(
        title: Text(AppConstants.roleLabels[role]!),
        subtitle: Text(_getRoleDescription(role)),
        value: role,
        groupValue: _selectedRole,
        onChanged: (value) => setState(() => _selectedRole = value),
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.imam:
        return 'Religious leader, can send prayer and community updates';
      case UserRole.communityLeader:
        return 'Community organizer with coordination privileges';
      case UserRole.medicalPersonnel:
        return 'Medical professional with emergency response access';
      case UserRole.emergencyCoordinator:
        return 'Emergency response coordinator';
      case UserRole.volunteer:
        return 'Community volunteer helper';
      case UserRole.resident:
        return 'Community member';
    }
  }

  void _proceedToHome() {
    // TODO: Save selected role to storage
    Navigator.pushReplacementNamed(context, '/home');
  }
}

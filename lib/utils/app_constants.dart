// utils/app_constants.dart
import 'package:new_project/models/app_models.dart';

class AppConstants {
  static const String appName = 'Ummah Connect';
  static const String appTagline =
      'Crisis Communication for Muslim Communities';

  static const Map<UserRole, String> roleLabels = {
    UserRole.imam: 'Imam/Religious Leader',
    UserRole.communityLeader: 'Community Leader',
    UserRole.medicalPersonnel: 'Medical Personnel',
    UserRole.emergencyCoordinator: 'Emergency Coordinator',
    UserRole.volunteer: 'Volunteer',
    UserRole.resident: 'Community Resident',
  };

  static const Map<MessageType, String> messageTypeLabels = {
    MessageType.emergency: 'Emergency Alert',
    MessageType.prayer: 'Prayer/Religious',
    MessageType.medical: 'Medical Request',
    MessageType.resources: 'Resources',
    MessageType.coordination: 'Coordination',
    MessageType.community: 'Community Update',
  };
}

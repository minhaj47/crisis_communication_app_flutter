// services/connection_service.dart
import 'package:new_project/models/app_models.dart';
import 'package:new_project/providers/sdk_provider.dart';

class ConnectionService {
  static Future<ConnectionStatus> checkConnections() async {
    try {
      final sdkProvider = SdkProvider();
      await sdkProvider.initialize();
      await sdkProvider.checkPermissions();
      return ConnectionStatus(
        availableConnections: [ConnectionType.mesh, ConnectionType.localServer],
        canInitializeMesh: true,
        localServerReachable: false,
        internetAvailable: false,
      );
    } catch (e) {
      return ConnectionStatus(
        availableConnections: [ConnectionType.mesh, ConnectionType.localServer],
        canInitializeMesh: false,
        localServerReachable: false,
        internetAvailable: false,
      );
    }
  }
}

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class StatusBar extends StatelessWidget {
  final MeshConnectionStatus connectionStatus;
  final int connectedPeersCount;
  final String currentUserName;
  final String errorMessage;

  const StatusBar({
    Key? key,
    required this.connectionStatus,
    required this.connectedPeersCount,
    required this.currentUserName,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: connectionStatus == MeshConnectionStatus.connected
          ? Colors.green[100]
          : connectionStatus == MeshConnectionStatus.connecting
              ? Colors.orange[100]
              : Colors.red[100],
      child: Row(
        children: [
          Icon(
            connectionStatus == MeshConnectionStatus.connected
                ? Icons.check_circle
                : connectionStatus == MeshConnectionStatus.connecting
                    ? Icons.access_time
                    : Icons.error,
            size: 16,
            color: connectionStatus == MeshConnectionStatus.connected
                ? Colors.green[800]
                : connectionStatus == MeshConnectionStatus.connecting
                    ? Colors.orange[800]
                    : Colors.red[800],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              connectionStatus == MeshConnectionStatus.connected
                  ? 'Connected • $connectedPeersCount peer(s) • $currentUserName'
                  : connectionStatus == MeshConnectionStatus.connecting
                      ? 'Connecting...'
                      : errorMessage.isNotEmpty
                          ? errorMessage
                          : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: connectionStatus == MeshConnectionStatus.connected
                    ? Colors.green[800]
                    : connectionStatus == MeshConnectionStatus.connecting
                        ? Colors.orange[800]
                        : Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

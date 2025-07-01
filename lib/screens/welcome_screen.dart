// screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:new_project/models/app_models.dart';
import 'package:new_project/services/connection_service.dart';
import 'package:new_project/utils/app_constants.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isChecking = true;
  ConnectionStatus? _connectionStatus;
  String _statusMessage = 'Checking connections...';

  @override
  void initState() {
    super.initState();
    _checkSystemStatus();
  }

  Future<void> _checkSystemStatus() async {
    setState(() {
      _statusMessage = 'Checking local server...';
    });

    final connectionStatus = await ConnectionService.checkConnections();

    setState(() {
      _connectionStatus = connectionStatus;
      _statusMessage = _getStatusMessage(connectionStatus);
    });

    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isChecking = false;
    });
  }

  String _getStatusMessage(ConnectionStatus status) {
    if (status.localServerReachable && status.canInitializeMesh) {
      return 'All systems ready';
    } else if (status.localServerReachable) {
      return 'Local server connected';
    } else if (status.canInitializeMesh) {
      return 'Mesh network ready';
    } else {
      return 'Limited connectivity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logs',
                  child: Text('View Logs'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.mosque, size: 80, color: Color(0xFF2E7D32)),
              ),
              SizedBox(height: 32),

              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              Text(
                AppConstants.appTagline,
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 64),

              if (_isChecking) ...[
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(_statusMessage, style: TextStyle(color: Colors.white)),
              ] else ...[
                _buildConnectionStatus(),
                SizedBox(height: 32),
                _buildContinueButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildStatusItem(
              'Local Server',
              _connectionStatus!.localServerReachable,
              Icons.router,
            ),
            _buildStatusItem(
              'Mesh Network',
              _connectionStatus!.canInitializeMesh,
              Icons.device_hub,
            ),
            _buildStatusItem(
              'Internet',
              _connectionStatus!.internetAvailable,
              Icons.wifi,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isAvailable, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isAvailable ? Colors.green : Colors.red),
          SizedBox(width: 16),
          Expanded(child: Text(label)),
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    bool canProceed = _connectionStatus!.localServerReachable ||
        _connectionStatus!.canInitializeMesh;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canProceed ? _proceedToNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF2E7D32),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            canProceed ? 'CONTINUE' : 'RETRY CONNECTION',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _proceedToNext() {
    if (_connectionStatus!.internetAvailable ||
        _connectionStatus!.localServerReachable) {
      Navigator.pushReplacementNamed(context, '/role-selection');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}

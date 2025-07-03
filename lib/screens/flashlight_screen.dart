// screens/flashlight_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashlight_service.dart';
import '../providers/sdk_provider.dart';

class FlashlightScreen extends StatefulWidget {
  @override
  _FlashlightScreenState createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  final FlashlightService _flashlightService = FlashlightService();
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _flashlightService.initialize(context);
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Initialization failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlashlight() async {
    final provider = Provider.of<SdkProvider>(context, listen: false);
    
    if (!provider.isStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bridgefy mesh is not connected. Please connect to mesh network first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _flashlightService.toggle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAlarm() async {
    final provider = Provider.of<SdkProvider>(context, listen: false);
    
    if (!provider.isStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bridgefy mesh is not connected. Please connect to mesh network first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _flashlightService.toggleAlarm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashlight & Alarm Tool'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isInitialized
          ? Consumer<SdkProvider>(
              builder: (context, provider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Connection Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: provider.isStarted 
                              ? Colors.green.shade100 
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: provider.isStarted 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              provider.isStarted 
                                  ? Icons.wifi 
                                  : Icons.wifi_off,
                              color: provider.isStarted 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.isStarted 
                                  ? 'Connected (${provider.connectedPeersCount} peers)'
                                  : 'Not connected to mesh',
                              style: TextStyle(
                                color: provider.isStarted 
                                    ? Colors.green.shade800 
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Flashlight Control Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _flashlightService.isFlashlightOn,
                          builder: (context, isOn, _) => Column(
                            children: [
                              Text(
                                'FLASHLIGHT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOn 
                                      ? Colors.yellow.shade100 
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: isOn 
                                        ? Colors.yellow.shade700 
                                        : Colors.grey.shade400,
                                    width: 3,
                                  ),
                                  boxShadow: isOn 
                                      ? [
                                          BoxShadow(
                                            color: Colors.yellow.shade300,
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isOn ? Icons.flashlight_on : Icons.flashlight_off,
                                  size: 50,
                                  color: isOn 
                                      ? Colors.yellow.shade700 
                                      : Colors.grey.shade600,
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              ElevatedButton.icon(
                                icon: Icon(isOn ? Icons.flash_off : Icons.flash_on),
                                label: Text(
                                  isOn ? 'Turn Off' : 'Turn On',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOn 
                                      ? Colors.red.shade600 
                                      : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(180, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: provider.isStarted 
                                    ? _toggleFlashlight 
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Alarm Control Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _flashlightService.isAlarmActive,
                          builder: (context, isActive, _) => Column(
                            children: [
                              Text(
                                'ALARM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive 
                                      ? Colors.red.shade100 
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: isActive 
                                        ? Colors.red.shade700 
                                        : Colors.grey.shade400,
                                    width: 3,
                                  ),
                                  boxShadow: isActive 
                                      ? [
                                          BoxShadow(
                                            color: Colors.red.shade300,
                                            blurRadius: 15,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    isActive ? Icons.notification_important : Icons.notifications_off,
                                    key: ValueKey(isActive),
                                    size: 50,
                                    color: isActive 
                                        ? Colors.red.shade700 
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              ElevatedButton.icon(
                                icon: Icon(isActive ? Icons.stop : Icons.campaign),
                                label: Text(
                                  isActive ? 'Stop Alarm' : 'Start Alarm',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive 
                                      ? Colors.grey.shade600 
                                      : Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(180, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: provider.isStarted 
                                    ? _toggleAlarm 
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Info Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Both flashlight and alarm controls will synchronize across all mesh-connected devices. Use these tools for emergency situations or group coordination.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                                height: 1.4,
                              ),
                            ),
                            if (!provider.isStarted) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Connect to the mesh network first to synchronize with other devices.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the service here as it's a singleton
    super.dispose();
  }
}
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashlight Tool'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isInitialized
          ? Consumer<SdkProvider>(
              builder: (context, provider, child) {
                return Padding(
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
                      
                      // Flashlight Control
                      ValueListenableBuilder<bool>(
                        valueListenable: _flashlightService.isFlashlightOn,
                        builder: (context, isOn, _) => Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
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
                                size: 60,
                                color: isOn 
                                    ? Colors.yellow.shade700 
                                    : Colors.grey.shade600,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            ElevatedButton.icon(
                              icon: Icon(isOn ? Icons.flash_off : Icons.flash_on),
                              label: Text(
                                isOn ? 'Turn Off' : 'Turn On',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOn 
                                    ? Colors.red.shade600 
                                    : Colors.green.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(200, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 8,
                              ),
                              onPressed: provider.isStarted 
                                  ? _toggleFlashlight 
                                  : null,
                            ),
                          ],
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
                              'Toggling the flashlight here will send a command to all mesh-connected devices.',
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
                                'Connect to the mesh network first to synchronize flashlights.',
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
// screens/flashlight_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashlight_service.dart';
import '../providers/sdk_provider.dart';
import '../screens/settings_screen.dart';

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
    return Consumer<SdkProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Emergency Tools'),
            actions: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isStarted ? Icons.wifi : Icons.wifi_off,
                      color: provider.isStarted ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text('${provider.connectedPeersCount}'),
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                color: provider.isStarted
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                child: Text(
                  provider.isStarted 
                      ? 'Connected - Tools will sync across mesh'
                      : 'Not connected - Connect to mesh network first',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),

              // Main content
              Expanded(
                child: _isInitialized
                    ? ValueListenableBuilder<bool>(
                        valueListenable: _flashlightService.isFlashlightOn,
                        builder: (context, isFlashlightOn, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _flashlightService.isAlarmActive,
                            builder: (context, isAlarmActive, _) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Flashlight Control
                                    GestureDetector(
                                      onTap: provider.isStarted ? _toggleFlashlight : null,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        margin: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isFlashlightOn 
                                              ? Colors.yellow.shade100 
                                              : Colors.grey.shade100,
                                          border: Border.all(
                                            color: isFlashlightOn 
                                                ? Colors.yellow.shade700 
                                                : Colors.grey.shade400,
                                            width: 3,
                                          ),
                                          boxShadow: isFlashlightOn 
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.yellow.shade300,
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.grey.shade300,
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                        ),
                                        child: Icon(
                                          isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off,
                                          size: 60,
                                          color: isFlashlightOn 
                                              ? Colors.yellow.shade700 
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    
                                    Text(
                                      isFlashlightOn ? 'Flashlight ON' : 'Flashlight OFF',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isFlashlightOn 
                                            ? Colors.yellow.shade700 
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    
                                    SizedBox(height: 40),
                                    
                                    // Alarm Control
                                    GestureDetector(
                                      onTap: provider.isStarted ? _toggleAlarm : null,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        margin: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isAlarmActive 
                                              ? Colors.red.shade100 
                                              : Colors.grey.shade100,
                                          border: Border.all(
                                            color: isAlarmActive 
                                                ? Colors.red.shade700 
                                                : Colors.grey.shade400,
                                            width: 3,
                                          ),
                                          boxShadow: isAlarmActive 
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.red.shade300,
                                                    blurRadius: 15,
                                                    spreadRadius: 3,
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.grey.shade300,
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: Icon(
                                            isAlarmActive ? Icons.notification_important : Icons.notifications_off,
                                            key: ValueKey(isAlarmActive),
                                            size: 60,
                                            color: isAlarmActive 
                                                ? Colors.red.shade700 
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    Text(
                                      isAlarmActive ? 'Alarm ACTIVE' : 'Alarm OFF',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isAlarmActive 
                                            ? Colors.red.shade700 
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    
                                    SizedBox(height: 40),
                                    
                                    // Instructions
                                    Container(
                                      margin: EdgeInsets.symmetric(horizontal: 40),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        'Tap the icons to control flashlight and alarm.\nControls sync across all connected devices.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
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
              // Compact Status Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: provider.isStarted
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      provider.isStarted ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: provider.isStarted ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      provider.isStarted ? 'MESH CONNECTED' : 'MESH DISCONNECTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: provider.isStarted ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Emergency Controls
              Expanded(
                child: _isInitialized
                    ? ValueListenableBuilder<bool>(
                        valueListenable: _flashlightService.isFlashlightOn,
                        builder: (context, isFlashlightOn, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _flashlightService.isAlarmActive,
                            builder: (context, isAlarmActive, _) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Column(
                                  children: [
                                    // Large Emergency Buttons Row
                                    Expanded(
                                      flex: 5,
                                      child: Row(
                                        children: [
                                          // FLASHLIGHT - Large button
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: provider.isStarted ? _toggleFlashlight : null,
                                              child: Container(
                                                margin: EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: isFlashlightOn 
                                                      ? Colors.yellow.shade300 
                                                      : Colors.grey.shade200,
                                                  border: Border.all(
                                                    color: isFlashlightOn 
                                                        ? Colors.yellow.shade700 
                                                        : Colors.grey.shade400,
                                                    width: 4,
                                                  ),
                                                  boxShadow: isFlashlightOn 
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.yellow.shade400,
                                                            blurRadius: 20,
                                                            spreadRadius: 0,
                                                          ),
                                                        ]
                                                      : [
                                                          BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 8,
                                                            spreadRadius: 0,
                                                          ),
                                                        ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off,
                                                      size: 80,
                                                      color: isFlashlightOn 
                                                          ? Colors.yellow.shade900 
                                                          : Colors.grey.shade600,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'FLASHLIGHT',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: isFlashlightOn 
                                                            ? Colors.yellow.shade900 
                                                            : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      isFlashlightOn ? 'ON' : 'OFF',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: isFlashlightOn 
                                                            ? Colors.yellow.shade900 
                                                            : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          // ALARM - Large button
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: provider.isStarted ? _toggleAlarm : null,
                                              child: Container(
                                                margin: EdgeInsets.only(left: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: isAlarmActive 
                                                      ? Colors.red.shade400 
                                                      : Colors.grey.shade200,
                                                  border: Border.all(
                                                    color: isAlarmActive 
                                                        ? Colors.red.shade700 
                                                        : Colors.grey.shade400,
                                                    width: 4,
                                                  ),
                                                  boxShadow: isAlarmActive 
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.red.shade300,
                                                            blurRadius: 20,
                                                            spreadRadius: 0,
                                                          ),
                                                        ]
                                                      : [
                                                          BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 8,
                                                            spreadRadius: 0,
                                                          ),
                                                        ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    AnimatedSwitcher(
                                                      duration: const Duration(milliseconds: 300),
                                                      child: Icon(
                                                        isAlarmActive ? Icons.warning : Icons.notifications_off,
                                                        key: ValueKey(isAlarmActive),
                                                        size: 80,
                                                        color: isAlarmActive 
                                                            ? Colors.red.shade900 
                                                            : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'ALARM',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: isAlarmActive 
                                                            ? Colors.red.shade900 
                                                            : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      isAlarmActive ? 'ACTIVE' : 'OFF',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: isAlarmActive 
                                                            ? Colors.red.shade900 
                                                            : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    SizedBox(height: 16),
                                    
                                    // Emergency Instructions - Compact
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.blue.shade700,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'TAP buttons to control. Syncs across mesh network.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    SizedBox(height: 8),
                                    
                                    // Quick Status Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: provider.isStarted 
                                                ? Colors.green.shade100 
                                                : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: provider.isStarted 
                                                  ? Colors.green.shade400 
                                                  : Colors.red.shade400,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.people,
                                                size: 16,
                                                color: provider.isStarted 
                                                    ? Colors.green.shade700 
                                                    : Colors.red.shade700,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${provider.connectedPeersCount} Connected',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: provider.isStarted 
                                                      ? Colors.green.shade700 
                                                      : Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                            CircularProgressIndicator(
                              strokeWidth: 6,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            SizedBox(height: 16),
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
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
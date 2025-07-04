// screens/sos_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/sdk_provider.dart';

class SOSScreen extends StatefulWidget {
  @override
  _SOSScreenState createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isPanicMode = false;
  bool _isLocationPermissionGranted = false;
  Position? _currentLocation;
  String _statusMessage = '';
  bool _isGettingLocation = false;
  List<Map<String, dynamic>> _sosMessages = [];
  
  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _subscribeToSOSMessages();
  }

  Future<void> _checkLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Location permissions permanently denied';
        });
        return;
      }
      
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'Location permissions denied';
        });
        return;
      }
      
      setState(() {
        _isLocationPermissionGranted = true;
        _statusMessage = 'Location permissions granted';
      });
      
      // Get current location in background
      _getCurrentLocation();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking location permissions: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) return;
    
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'Location services are disabled';
          _isGettingLocation = false;
        });
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      setState(() {
        _currentLocation = position;
        _statusMessage = 'Location acquired';
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting location: $e';
        _isGettingLocation = false;
      });
    }
  }

  void _subscribeToSOSMessages() {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    
    // Subscribe to SOS topic to receive SOS messages from other devices
    sdkProvider.subscribeToTopic('sos_emergency', (data, messageId) {
      _handleIncomingSOSMessage(data, messageId);
    });
  }

  void _handleIncomingSOSMessage(Uint8List data, String messageId) {
    try {
      final jsonString = utf8.decode(data);
      final sosData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final senderName = sosData['senderName'] ?? 'Unknown';
      final location = sosData['location'] as Map<String, dynamic>?;
      final timestamp = sosData['timestamp'] as int?;
      
      // Add to SOS messages list
      setState(() {
        _sosMessages.insert(0, {
          'senderName': senderName,
          'location': location,
          'timestamp': timestamp,
          'messageId': messageId,
        });
      });
      
      // Show incoming SOS alert
      _showIncomingSOSAlert(senderName, location, timestamp);
      
      // Vibrate to alert user
      HapticFeedback.vibrate();
      
    } catch (e) {
      print('Error parsing incoming SOS message: $e');
    }
  }

  void _showIncomingSOSAlert(String senderName, Map<String, dynamic>? location, int? timestamp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text('EMERGENCY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: $senderName', style: TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(height: 6),
            if (location != null) ...[
              SizedBox(height: 6),
              Text('Location:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Lat: ${location['latitude']?.toStringAsFixed(6)}', style: TextStyle(color: Colors.white, fontSize: 12)),
              Text('Lng: ${location['longitude']?.toStringAsFixed(6)}', style: TextStyle(color: Colors.white, fontSize: 12)),
              Text('Accuracy: ${location['accuracy']?.toStringAsFixed(1)}m', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
            if (timestamp != null) ...[
              SizedBox(height: 6),
              Text('Time: ${DateTime.fromMillisecondsSinceEpoch(timestamp).toString()}', 
                   style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ACKNOWLEDGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _getLocationString() {
    if (_isGettingLocation) return 'Getting location...';
    if (_currentLocation != null) {
      return 'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, Lng: ${_currentLocation!.longitude.toStringAsFixed(4)} (±${_currentLocation!.accuracy.toStringAsFixed(0)}m)';
    }
    if (!_isLocationPermissionGranted) return 'Location disabled';
    return 'No location';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SdkProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: _isPanicMode ? Colors.red : null,
          appBar: AppBar(
            backgroundColor: _isPanicMode ? Colors.red : null,
            foregroundColor: _isPanicMode ? Colors.white : null,
            title: Text('Emergency SOS'),
            actions: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isStarted ? Icons.wifi : Icons.wifi_off,
                      color: _isPanicMode ? Colors.white : (provider.isStarted ? Colors.green : Colors.red),
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text('${provider.connectedPeersCount}'),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_isGettingLocation ? Icons.location_searching : Icons.refresh),
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      tooltip: 'Refresh Location',
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Location status bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                color: _isPanicMode 
                    ? Colors.red.shade700 
                    : (_isLocationPermissionGranted 
                        ? Colors.green.shade100 
                        : Colors.orange.shade100),
                child: Row(
                  children: [
                    Icon(
                      _isGettingLocation 
                          ? Icons.location_searching 
                          : (_currentLocation != null 
                              ? Icons.my_location 
                              : Icons.location_off),
                      size: 16,
                      color: _isPanicMode ? Colors.white : null,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getLocationString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPanicMode ? Colors.white : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: _isPanicMode
                    ? _buildPanicModeContent()
                    : _buildNormalContent(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNormalContent(SdkProvider provider) {
  return Column(
    children: [
      // SOS Messages list or Central SOS UI
      Expanded(
        child: _sosMessages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Instruction above the button
                    Text(
                      'Press and hold the SOS button to send\nemergency alert to all nearby devices',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Large SOS Button
                    GestureDetector(
                      onLongPressStart: (_) => _activateSOS(),
                      onLongPressEnd: (_) => _deactivateSOS(),
                      onLongPressCancel: _deactivateSOS,
                      onTapCancel: _deactivateSOS,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          
                            Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Additional Instruction Below Button
                    Text(
                      'Hold to activate SOS',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _sosMessages.length,
                itemBuilder: (context, index) {
                  final message = _sosMessages[index];
                  return _buildSOSMessageCard(message);
                },
              ),
      ),

      // Connection status
      if (!provider.isStarted)
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.orange.shade100,
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Not connected to mesh network. SOS messages cannot be sent.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}


 Widget _buildPanicModeContent() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Message above the button
        Text(
          'Emergency message sent to all nearby devices',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        SizedBox(height: 20),

        // Large SOS Button with warning icon inside
        GestureDetector(
          onLongPressStart: (_) => _activateSOS(),
          onLongPressEnd: (_) => _deactivateSOS(),
          onLongPressCancel: _deactivateSOS,
          onTapCancel: _deactivateSOS,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.red,
                width: 6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 60, color: Colors.red),
                SizedBox(height: 10),
                Text(
                  'TAP TO STOP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 32),

        // SOS ACTIVATED Text
        Text(
          'SOS ACTIVATED',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}



  Widget _buildSOSMessageCard(Map<String, dynamic> message) {
    final senderName = message['senderName'] ?? 'Unknown';
    final location = message['location'] as Map<String, dynamic>?;
    final timestamp = message['timestamp'] as int?;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'EMERGENCY ALERT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Spacer(),
                if (timestamp != null)
                  Text(
                    _formatTime(DateTime.fromMillisecondsSinceEpoch(timestamp)),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'From: $senderName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (location != null) ...[
              SizedBox(height: 8),
              Text(
                'Location: ${location['latitude']?.toStringAsFixed(6)}, ${location['longitude']?.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                'Accuracy: ±${location['accuracy']?.toStringAsFixed(1)}m',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _activateSOS() {
    setState(() {
      _isPanicMode = true;
    });
    
    // Vibrate to provide feedback
    HapticFeedback.heavyImpact();
    
    // Send SOS message
    _sendSOSMessage();
  }

  void _deactivateSOS() {
    // Only deactivate if currently in panic mode
    if (_isPanicMode) {
      setState(() {
        _isPanicMode = false;
      });
    }
  }

  Future<void> _sendSOSMessage() async {
    try {
      final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
      
      if (!sdkProvider.isStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not connected to mesh network')),
        );
        return;
      }
      
      // Get user name
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Unknown User';
      
      // Prepare SOS message data
      final sosData = {
        'messageType': 'sos_emergency',
        'senderName': userName,
        'senderId': sdkProvider.currentUserId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'emergencyType': 'General Emergency',
        'message': 'EMERGENCY: $userName needs immediate assistance!',
      };
      
      // Add location if available
      if (_currentLocation != null) {
        sosData['location'] = {
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          'accuracy': _currentLocation!.accuracy,
          'altitude': _currentLocation!.altitude,
          'speed': _currentLocation!.speed,
          'heading': _currentLocation!.heading,
          'timestamp': _currentLocation!.timestamp?.millisecondsSinceEpoch,
        };
      } else {
        // Try to get location one more time
        if (_isLocationPermissionGranted) {
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            );
            sosData['location'] = {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'altitude': position.altitude,
              'speed': position.speed,
              'heading': position.heading,
              'timestamp': position.timestamp?.millisecondsSinceEpoch,
            };
          } catch (e) {
            print('Could not get location for SOS: $e');
          }
        }
      }
      
      // Convert to bytes
      final jsonString = jsonEncode(sosData);
      final data = Uint8List.fromList(utf8.encode(jsonString));
      
      // Send via mesh network using topic-based messaging
      await sdkProvider.sendTopicMessage(data, 'sos_emergency');
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS message sent to ${sdkProvider.connectedPeersCount} nearby devices'),
          backgroundColor: Colors.orange,
        ),
      );
      
    } catch (e) {
      print('Error sending SOS message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS message: $e')),
      );
    }
  }

  @override
  void dispose() {
    // Unsubscribe from SOS messages
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    sdkProvider.unsubscribeFromTopic('sos_emergency');
    super.dispose();
  }
}
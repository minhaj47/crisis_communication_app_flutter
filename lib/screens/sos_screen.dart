// screens/sos_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/sdk_provider.dart';
import '../providers/broadcast_message_provider.dart';
import '../models/app_models.dart';

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

  // Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
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
      
      // Create a CrisisMessage for the broadcast provider
      final crisisMessage = CrisisMessage(
        id: messageId,
        title: 'SOS EMERGENCY',
        content: 'EMERGENCY: $senderName needs immediate assistance!',
        type: MessageType.emergency,
        priority: MessagePriority.high,
        timestamp: timestamp != null 
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : DateTime.now(),
        latitude: location?['latitude']?.toDouble() ?? 0.0,
        longitude: location?['longitude']?.toDouble() ?? 0.0,
        senderRole: UserRole.resident,
        radiusKm: 5.0,
        sentVia: ConnectionType.mesh,
      );
      
      // Add to broadcast provider instead of local storage
      final broadcastProvider = Provider.of<BroadcastMessageProvider>(context, listen: false);
      broadcastProvider.addMessage(crisisMessage);
      
      // Show incoming SOS alert
      _showIncomingSOSAlert(senderName, location, timestamp);
      
      // Vibrate to alert user
      HapticFeedback.vibrate();
      
    } catch (e) {
      print('Error parsing incoming SOS message: $e');
    }
  }

  void _showIncomingSOSAlert(String senderName, Map<String, dynamic>? location, int? timestamp) {
    // Calculate distance if both locations are available
    double? distanceKm;
    if (location != null && _currentLocation != null) {
      final senderLat = location['latitude']?.toDouble();
      final senderLon = location['longitude']?.toDouble();
      
      if (senderLat != null && senderLon != null) {
        distanceKm = _calculateDistance(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          senderLat,
          senderLon,
        );
      }
    }

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
            
            // Distance information (prominent display)
            if (distanceKm != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.near_me, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Distance: ${_formatDistance(distanceKm)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ] else if (_currentLocation == null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Distance: Unknown (location disabled)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            
            // Location details
            if (location != null) ...[
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to broadcast page to see all messages
              Navigator.of(context).pushReplacementNamed('/broadcast');
            },
            child: Text('VIEW ALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
        // Central SOS UI
        Expanded(
          child: Center(
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
                SizedBox(height: 32),

                // View Messages Button
                Consumer<BroadcastMessageProvider>(
                  builder: (context, broadcastProvider, child) {
                    final sosMessages = broadcastProvider.messages
                        .where((msg) => msg.type == MessageType.emergency && msg.title == 'SOS EMERGENCY')
                        .toList();
                    
                    if (sosMessages.isNotEmpty) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/broadcast');
                        },
                        icon: Icon(Icons.message),
                        label: Text('View Emergency Messages (${sosMessages.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
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
      
      // Also store the sent message in broadcast provider
      final broadcastProvider = Provider.of<BroadcastMessageProvider>(context, listen: false);
      final location = sosData['location'] as Map<String, dynamic>?;
      final sentMessage = CrisisMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'SOS EMERGENCY (SENT)',
        content: 'You sent an emergency alert to all nearby devices',
        type: MessageType.emergency,
        priority: MessagePriority.high,
        timestamp: DateTime.now(),
        latitude: location?['latitude']?.toDouble() ?? 0.0,
        longitude: location?['longitude']?.toDouble() ?? 0.0,
        senderRole: UserRole.resident,
        radiusKm: 5.0,
        sentVia: ConnectionType.mesh,
      );
      
      broadcastProvider.addMessage(sentMessage);
      
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
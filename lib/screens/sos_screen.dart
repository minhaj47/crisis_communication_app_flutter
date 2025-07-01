// screens/sos_screen.dart
import 'package:flutter/material.dart';

class SOSScreen extends StatefulWidget {
  @override
  _SOSScreenState createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isPanicMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isPanicMode ? Colors.red : null,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isPanicMode) ...[
              Icon(Icons.sos, size: 100, color: Colors.red),
              SizedBox(height: 24),
              Text(
                'Emergency SOS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Press and hold the button below to send emergency SOS to all nearby devices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ] else ...[
              Icon(Icons.warning, size: 100, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'SOS ACTIVATED',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Emergency message sent to all nearby devices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],

            SizedBox(height: 48),

            // SOS Button
            GestureDetector(
              onLongPress: _activateSOS,
              onLongPressEnd: (_) => _deactivateSOS(),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPanicMode ? Colors.white : Colors.red,
                  border: Border.all(
                    color: _isPanicMode ? Colors.red : Colors.white,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _isPanicMode ? Colors.red : Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),
            Text(
              _isPanicMode ? 'Release to stop' : 'Hold to activate SOS',
              style: TextStyle(
                fontSize: 16,
                color: _isPanicMode ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _activateSOS() {
    setState(() {
      _isPanicMode = true;
    });
    // TODO: Send SOS message to all connected devices
  }

  void _deactivateSOS() {
    setState(() {
      _isPanicMode = false;
    });
  }
}

// screens/flashlight_screen.dart
import 'package:flutter/material.dart';

class FlashlightScreen extends StatefulWidget {
  @override
  _FlashlightScreenState createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  bool _isFlashlightOn = false;
  bool _isAlarmOn = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Emergency Tools',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 48),

          // Flashlight Control
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isFlashlightOn ? Colors.yellow : Colors.grey[300],
              boxShadow:
                  _isFlashlightOn
                      ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ]
                      : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _toggleFlashlight,
                child: Center(
                  child: Icon(
                    Icons.flashlight_on,
                    size: 80,
                    color: _isFlashlightOn ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
          Text(
            _isFlashlightOn ? 'Flashlight ON' : 'Tap to turn on flashlight',
            style: TextStyle(fontSize: 16),
          ),

          SizedBox(height: 48),

          // Alarm Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _toggleAlarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAlarmOn ? Colors.red : Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isAlarmOn ? 'STOP ALARM' : 'START EMERGENCY ALARM',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlashlight() {
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });
    // TODO: Implement actual flashlight control
  }

  void _toggleAlarm() {
    setState(() {
      _isAlarmOn = !_isAlarmOn;
    });
    // TODO: Implement alarm sound
  }
}

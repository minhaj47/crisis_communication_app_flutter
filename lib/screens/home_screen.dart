// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:new_project/screens/broadcast_screen.dart';
import 'package:new_project/screens/chat_screen.dart';
import 'package:new_project/screens/flashlight_screen.dart';
import 'package:new_project/screens/map_screen.dart';
import 'package:new_project/screens/settings_screen.dart';
import 'package:new_project/screens/sos_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Ummah Connect'),
      //   backgroundColor: Color(0xFF2E7D32),
      //   foregroundColor: Colors.white,
      //   actions: [
      //     Icon(Icons.signal_cellular_4_bar), // Connection indicator
      //     SizedBox(width: 16),
      //   ],
      // ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Broadcast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flashlight_on),
            label: 'Tools',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sos), label: 'SOS'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return MeshChatPage();
      case 1:
        return const BroadcastScreen();
      case 2:
        return FlashlightScreen();
      case 3:
        return SOSScreen();
      case 4:
        return SettingsScreen();
      case 5:
        return MapScreen();
      default:
        return MeshChatPage();
    }
  }
}

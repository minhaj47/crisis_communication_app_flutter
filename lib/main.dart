// main.dart
import 'package:flutter/material.dart';
import 'package:new_project/providers/sdk_provider.dart';
import 'package:provider/provider.dart';

import 'screens/broadcast_screen.dart';
import 'screens/flashlight_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(CrisisCommApp());
}

class CrisisCommApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<SdkProvider>(create: (_) => SdkProvider()),
        ],
        child: MaterialApp(
          title: 'Ummah Connect - Crisis Communication',
          theme: ThemeData(
            primarySwatch: Colors.green, // Islamic theme
            fontFamily: 'Arial',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFF2E7D32), // Islamic green
            ),
          ),
          home: WelcomeScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/welcome': (context) => WelcomeScreen(),
            '/role-selection': (context) => RoleSelectionScreen(),
            '/home': (context) => HomeScreen(),
            '/broadcast': (context) => BroadcastScreen(),
            '/flashlight': (context) => FlashlightScreen(),
            '/sos': (context) => SOSScreen(),
            '/settings': (context) => SettingsScreen(),
            '/map': (context) => MapScreen(),
          },
        ));
  }
}

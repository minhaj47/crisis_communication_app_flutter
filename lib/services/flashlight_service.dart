// services/flashlight_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:provider/provider.dart';
import '../providers/sdk_provider.dart';

/// Shared service to handle flashlight logic across the app.
class FlashlightService {
  static final FlashlightService _instance = FlashlightService._internal();
  factory FlashlightService() => _instance;
  FlashlightService._internal();

  final ValueNotifier<bool> isFlashlightOn = ValueNotifier(false);
  final String _commandTopic = 'flashlight_commands';
  SdkProvider? _sdkProvider;
  bool _isInitialized = false;
  bool _isHandlingRemoteCommand = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    try {
      // Check if device has torch capability
      final hasFlash = await TorchLight.isTorchAvailable();
      if (!hasFlash) {
        throw Exception('Device does not have torch capability');
      }

      _sdkProvider = Provider.of<SdkProvider>(context, listen: false);
      
      // Wait for Bridgefy to be ready if it's not already
      if (!_sdkProvider!.isInitialized) {
        print('Bridgefy not initialized, waiting...');
        // You might want to add a timeout here
        int attempts = 0;
        while (!_sdkProvider!.isInitialized && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
        
        if (!_sdkProvider!.isInitialized) {
          throw Exception('Bridgefy initialization timeout');
        }
      }

      // Subscribe to mesh commands
      await _sdkProvider!.subscribeToTopic(_commandTopic, _handleMeshCommand);
      
      _isInitialized = true;
      print('FlashlightService initialized successfully');
    } catch (e) {
      print('Error initializing FlashlightService: $e');
      throw Exception('Failed to initialize flashlight service: ${e.toString()}');
    }
  }

  void _handleMeshCommand(Uint8List data, String messageId) {
    if (_isHandlingRemoteCommand) {
      print('Already handling a remote command, ignoring duplicate');
      return;
    }
    
    try {
      final commandString = utf8.decode(data);
      print('Received mesh command: $commandString');
      
      // Parse the command JSON
      final Map<String, dynamic> command = jsonDecode(commandString);
      
      // Validate command structure
      if (command['type'] != 'flashlight') {
        print('Invalid command type: ${command['type']}');
        return;
      }
      
      final String action = command['action'];
      if (action != 'on' && action != 'off') {
        print('Invalid action: $action');
        return;
      }
      
      // Handle the remote command without broadcasting
      _handleFlashlightCommand(action, fromRemote: true);
    } catch (e) {
      print('Error handling mesh command: $e');
    }
  }

  /// Handle flashlight command from mesh or local action
  Future<void> _handleFlashlightCommand(String action, {bool fromRemote = false}) async {
    if (fromRemote) {
      _isHandlingRemoteCommand = true;
    }
    
    try {
      if (action == 'on') {
        await _turnOnFlashlight(broadcast: !fromRemote);
      } else if (action == 'off') {
        await _turnOffFlashlight(broadcast: !fromRemote);
      }
    } finally {
      if (fromRemote) {
        _isHandlingRemoteCommand = false;
      }
    }
  }

  /// Turn on flashlight
  Future<void> turnOn() async {
    await _turnOnFlashlight(broadcast: true);
  }

  /// Turn off flashlight
  Future<void> turnOff() async {
    await _turnOffFlashlight(broadcast: true);
  }

  /// Toggle flashlight state
  Future<void> toggle() async {
    if (isFlashlightOn.value) {
      await turnOff();
    } else {
      await turnOn();
    }
  }

  Future<void> _turnOnFlashlight({required bool broadcast}) async {
    try {
      if (!isFlashlightOn.value) {
        await TorchLight.enableTorch();
        isFlashlightOn.value = true;
        print('Flashlight turned ON');
      }
      
      if (broadcast) {
        await _broadcastCommand('on');
      }
    } catch (e) {
      print('Error turning on flashlight: $e');
      throw Exception('Failed to turn on flashlight: ${e.toString()}');
    }
  }

  Future<void> _turnOffFlashlight({required bool broadcast}) async {
    try {
      if (isFlashlightOn.value) {
        await TorchLight.disableTorch();
        isFlashlightOn.value = false;
        print('Flashlight turned OFF');
      }
      
      if (broadcast) {
        await _broadcastCommand('off');
      }
    } catch (e) {
      print('Error turning off flashlight: $e');
      throw Exception('Failed to turn off flashlight: ${e.toString()}');
    }
  }

  Future<void> _broadcastCommand(String action) async {
    try {
      if (_sdkProvider == null || !_sdkProvider!.isStarted) {
        print('Bridgefy not started, cannot broadcast command');
        return;
      }

      final command = {
        'type': 'flashlight',
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final commandString = jsonEncode(command);
      final data = Uint8List.fromList(utf8.encode(commandString));
      
      await _sdkProvider!.sendTopicMessage(data, _commandTopic);
      print('Broadcasted flashlight command: $action');
    } catch (e) {
      print('Error broadcasting command: $e');
    }
  }

  /// Get current flashlight state
  bool get isOn => isFlashlightOn.value;

  /// Dispose resources
  void dispose() {
    if (isFlashlightOn.value) {
      TorchLight.disableTorch().catchError((e) {
        print('Error disabling torch during dispose: $e');
      });
    }
    isFlashlightOn.dispose();
    _isInitialized = false;
  }
}
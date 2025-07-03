// services/flashlight_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/sdk_provider.dart';

/// Shared service to handle flashlight and alarm logic across the app.
class FlashlightService {
  static final FlashlightService _instance = FlashlightService._internal();
  factory FlashlightService() => _instance;
  FlashlightService._internal();

  final ValueNotifier<bool> isFlashlightOn = ValueNotifier(false);
  final ValueNotifier<bool> isAlarmActive = ValueNotifier(false);
  final String _commandTopic = 'flashlight_commands';

  SdkProvider? _sdkProvider;
  bool _isInitialized = false;
  bool _isHandlingRemoteCommand = false;
  bool _hasVibrator = false;
  Timer? _alarmTimer;
  Timer? _vibrationTimer;
  FlutterRingtonePlayer? _ringtonePlayer;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      // Check if device has torch capability
      final hasFlash = await TorchLight.isTorchAvailable();
      if (!hasFlash) {
        throw Exception('Device does not have torch capability');
      }

      // Check if device has vibrator
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      print('Device has vibrator: $_hasVibrator');

      // Initialize ringtone player
      _ringtonePlayer = FlutterRingtonePlayer();

      _sdkProvider = Provider.of<SdkProvider>(context, listen: false);

      // Wait for Bridgefy to be ready if it's not already
      if (!_sdkProvider!.isInitialized) {
        print('Bridgefy not initialized, waiting...');
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
      throw Exception(
          'Failed to initialize flashlight service: ${e.toString()}');
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
      if (command['type'] != 'flashlight' && command['type'] != 'alarm') {
        print('Invalid command type: ${command['type']}');
        return;
      }

      final String action = command['action'];
      final String commandType = command['type'];

      // Handle different command types
      if (commandType == 'flashlight') {
        if (action != 'on' && action != 'off') {
          print('Invalid flashlight action: $action');
          return;
        }
        _handleFlashlightCommand(action, fromRemote: true);
      } else if (commandType == 'alarm') {
        if (action != 'start' && action != 'stop') {
          print('Invalid alarm action: $action');
          return;
        }
        _handleAlarmCommand(action, fromRemote: true);
      }
    } catch (e) {
      print('Error handling mesh command: $e');
    }
  }

  /// Handle flashlight command from mesh or local action
  Future<void> _handleFlashlightCommand(String action,
      {bool fromRemote = false}) async {
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

  /// Handle alarm command from mesh or local action
  Future<void> _handleAlarmCommand(String action,
      {bool fromRemote = false}) async {
    if (fromRemote) {
      _isHandlingRemoteCommand = true;
    }

    try {
      if (action == 'start') {
        await _startAlarm(broadcast: !fromRemote);
      } else if (action == 'stop') {
        await _stopAlarm(broadcast: !fromRemote);
      }
    } finally {
      if (fromRemote) {
        _isHandlingRemoteCommand = false;
      }
    }
  }

  // FLASHLIGHT FUNCTIONALITY (UNCHANGED)

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
        await _broadcastCommand('flashlight', 'on');
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
        await _broadcastCommand('flashlight', 'off');
      }
    } catch (e) {
      print('Error turning off flashlight: $e');
      throw Exception('Failed to turn off flashlight: ${e.toString()}');
    }
  }

  // ENHANCED ALARM FUNCTIONALITY

  /// Start alarm
  Future<void> startAlarm() async {
    await _startAlarm(broadcast: true);
  }

  /// Stop alarm
  Future<void> stopAlarm() async {
    await _stopAlarm(broadcast: true);
  }

  /// Toggle alarm state
  Future<void> toggleAlarm() async {
    if (isAlarmActive.value) {
      await stopAlarm();
    } else {
      await startAlarm();
    }
  }

  Future<void> _startAlarm({required bool broadcast}) async {
    try {
      if (!isAlarmActive.value) {
        isAlarmActive.value = true;

        // Keep screen awake during alarm
        await WakelockPlus.enable();

        // Start alarm sound
        await _startAlarmSound();

        // Start vibration pattern
        await _startVibrationPattern();

        print('Alarm started');
      }

      if (broadcast) {
        await _broadcastCommand('alarm', 'start');
      }
    } catch (e) {
      print('Error starting alarm: $e');
      throw Exception('Failed to start alarm: ${e.toString()}');
    }
  }

  Future<void> _stopAlarm({required bool broadcast}) async {
    try {
      if (isAlarmActive.value) {
        isAlarmActive.value = false;

        // Stop all timers
        _alarmTimer?.cancel();
        _vibrationTimer?.cancel();

        // Stop alarm sound
        await _stopAlarmSound();

        // Stop vibration
        await Vibration.cancel();

        // Disable wakelock
        await WakelockPlus.disable();

        print('Alarm stopped');
      }

      if (broadcast) {
        await _broadcastCommand('alarm', 'stop');
      }
    } catch (e) {
      print('Error stopping alarm: $e');
      throw Exception('Failed to stop alarm: ${e.toString()}');
    }
  }

  Future<void> _startAlarmSound() async {
    try {
      // Use the instance method instead of static method
      await _ringtonePlayer!.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
      );
    } catch (e) {
      print('Error starting alarm sound: $e');
      // Fallback to system sound
      try {
        await SystemSound.play(SystemSoundType.alert);
        // Set up a timer to repeat the system sound
        _alarmTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (!isAlarmActive.value) {
            timer.cancel();
            return;
          }
          SystemSound.play(SystemSoundType.alert);
        });
      } catch (e2) {
        print('Error with fallback alarm sound: $e2');
      }
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      await _ringtonePlayer!.stop();
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }

    _alarmTimer?.cancel();
  }

  Future<void> _startVibrationPattern() async {
    if (!_hasVibrator) {
      print('Device does not have vibrator');
      return;
    }

    try {
      // Start continuous vibration pattern
      _vibrationTimer =
          Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
        if (!isAlarmActive.value) {
          timer.cancel();
          return;
        }

        try {
          // Create an alarm-like vibration pattern: long-short-short-long
          await Vibration.vibrate(
            pattern: [0, 800, 200, 300, 200, 300, 200, 800],
            repeat: 0, // Play once per timer tick
          );
        } catch (e) {
          print('Error in vibration pattern: $e');
          // Fallback to simple vibration
          try {
            await Vibration.vibrate(duration: 500);
          } catch (e2) {
            print('Error with simple vibration: $e2');
            // Final fallback to haptic feedback
            await HapticFeedback.heavyImpact();
          }
        }
      });
    } catch (e) {
      print('Error starting vibration pattern: $e');
      // Fallback to basic haptic feedback
      _vibrationTimer =
          Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
        if (!isAlarmActive.value) {
          timer.cancel();
          return;
        }
        try {
          await HapticFeedback.heavyImpact();
        } catch (e) {
          print('Error with haptic feedback: $e');
        }
      });
    }
  }

  // SHARED FUNCTIONALITY

  Future<void> _broadcastCommand(String type, String action) async {
    try {
      if (_sdkProvider == null || !_sdkProvider!.isStarted) {
        print('Bridgefy not started, cannot broadcast command');
        return;
      }

      final command = {
        'type': type,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final commandString = jsonEncode(command);
      final data = Uint8List.fromList(utf8.encode(commandString));

      await _sdkProvider!.sendTopicMessage(data, _commandTopic);
      print('Broadcasted $type command: $action');
    } catch (e) {
      print('Error broadcasting command: $e');
    }
  }

  /// Get current flashlight state
  bool get isOn => isFlashlightOn.value;

  /// Get current alarm state
  bool get isAlarmOn => isAlarmActive.value;

  /// Dispose resources
  void dispose() {
    // Stop alarm if active
    if (isAlarmActive.value) {
      _stopAlarm(broadcast: false).catchError((e) {
        print('Error stopping alarm during dispose: $e');
      });
    }

    // Turn off flashlight if on
    if (isFlashlightOn.value) {
      TorchLight.disableTorch().catchError((e) {
        print('Error disabling torch during dispose: $e');
      });
    }

    // Cancel timers
    _alarmTimer?.cancel();
    _vibrationTimer?.cancel();

    // Disable wakelock
    WakelockPlus.disable().catchError((e) {
      print('Error disabling wakelock during dispose: $e');
    });

    // Dispose notifiers
    isFlashlightOn.dispose();
    isAlarmActive.dispose();

    _isInitialized = false;
  }
}

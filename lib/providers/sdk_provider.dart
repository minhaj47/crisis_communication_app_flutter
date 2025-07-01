// lib/providers/sdk_provider.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:bridgefy/bridgefy.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';

class SdkProvider extends ChangeNotifier implements BridgefyDelegate {
  final _bridgefy = Bridgefy();

  // State management
  bool isInitialized = false;
  bool isStarted = false;
  bool permissionsGranted = false;
  String currentUserId = '';
  String statusMessage = 'Disconnected';
  int connectedPeersCount = 0;

  // Chat data
  final List<ChatMessage> messages = [];

  Future<bool> checkPermissions() async {
    final permissions = [
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ];

    final status = await permissions.request();
    permissionsGranted = status.values.every((s) => s.isGranted);

    if (!permissionsGranted) {
      statusMessage = 'Permissions required';
      notifyListeners();
    }

    return permissionsGranted;
  }

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      statusMessage = 'Initializing...';
      notifyListeners();

      currentUserId = const Uuid().v4();

      await _bridgefy.initialize(
        apiKey: "3b431d37-6394-4dad-8ce5-a1785cfd9a5c",
        delegate: this,
        verboseLogging: false,
      );

      isInitialized = await _bridgefy.isInitialized;

      if (isInitialized) {
        await start();
      } else {
        statusMessage = 'Initialization failed';
      }

      notifyListeners();
    } catch (e) {
      statusMessage = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (!isInitialized || !permissionsGranted) {
      if (!permissionsGranted) {
        permissionsGranted = await checkPermissions();
        if (!permissionsGranted) return;
      }
      if (!isInitialized) {
        await initialize();
        return;
      }
    }

    try {
      await _bridgefy.start();
    } catch (e) {
      statusMessage = 'Failed to start: $e';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (!isInitialized || !isStarted) return;

    try {
      await _bridgefy.stop();
    } catch (e) {
      statusMessage = 'Failed to stop: $e';
      notifyListeners();
    }
  }

  Future<List<String>> get connectedPeers async {
    try {
      return await _bridgefy.connectedPeers;
    } catch (e) {
      return [];
    }
  }

  Future<void> sendMessage(ChatMessage message) async {
    if (!isStarted) throw Exception('Not connected');

    final messageData = {
      'id': message.id,
      'content': message.content,
      'senderId': message.senderId,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    };

    final data = Uint8List.fromList(utf8.encode(jsonEncode(messageData)));

    await _bridgefy.send(
      data: data,
      transmissionMode: BridgefyTransmissionMode(
        type: BridgefyTransmissionModeType.broadcast,
        uuid: currentUserId,
      ),
    );
  }

  void addMessage(ChatMessage message) {
    if (!messages.any((msg) => msg.id == message.id)) {
      messages.add(message);
      notifyListeners();
    }
  }

  void updateMessageStatus(String messageId, MessageStatus status) {
    final index = messages.indexWhere((msg) => msg.id == messageId);
    if (index >= 0) {
      messages[index] = messages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  ChatMessage _parseReceivedMessage(Uint8List data, String messageId) {
    try {
      final jsonString = utf8.decode(data);
      final messageData = jsonDecode(jsonString) as Map<String, dynamic>;

      return ChatMessage(
        id: messageData['id'] ?? messageId,
        content: messageData['content'] ?? 'Unknown message',
        senderId: messageData['senderId'] ?? 'Unknown',
        timestamp: messageData['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(messageData['timestamp'])
            : DateTime.now(),
        isFromMe: false,
        status: MessageStatus.sent,
      );
    } catch (e) {
      return ChatMessage(
        id: messageId,
        content: utf8.decode(data),
        senderId: 'Unknown',
        timestamp: DateTime.now(),
        isFromMe: false,
        status: MessageStatus.sent,
      );
    }
  }

  // Bridgefy Delegate Methods
  @override
  void bridgefyDidStart({required String currentUserID}) {
    isStarted = true;
    currentUserId = currentUserID;
    statusMessage = 'Connected to mesh network';
    notifyListeners();
  }

  @override
  void bridgefyDidFailToStart({BridgefyError? error}) {
    isStarted = false;
    statusMessage = 'Failed to start: ${error?.message ?? 'Unknown error'}';
    notifyListeners();
  }

  @override
  void bridgefyDidStop() {
    isStarted = false;
    connectedPeersCount = 0;
    statusMessage = 'Disconnected';
    notifyListeners();
  }

  @override
  void bridgefyDidConnect({required String userID}) {
    connectedPeersCount++;
    statusMessage = 'Connected ($connectedPeersCount peers)';
    notifyListeners();
  }

  @override
  void bridgefyDidDisconnect({required String userID}) {
    connectedPeersCount = (connectedPeersCount - 1).clamp(0, 999);
    statusMessage = connectedPeersCount > 0
        ? 'Connected ($connectedPeersCount peers)'
        : 'No peers connected';
    notifyListeners();
  }

  @override
  void bridgefyDidReceiveData({
    required Uint8List data,
    required String messageId,
    required BridgefyTransmissionMode transmissionMode,
  }) {
    final message = _parseReceivedMessage(data, messageId);
    addMessage(message);
  }

  @override
  void bridgefyDidSendMessage({required String messageID}) {
    updateMessageStatus(messageID, MessageStatus.sent);
  }

  @override
  void bridgefyDidFailSendingMessage({
    required String messageID,
    BridgefyError? error,
  }) {
    updateMessageStatus(messageID, MessageStatus.failed);
  }

  // Minimal implementations for other required methods
  @override
  void bridgefyDidFailToStop({BridgefyError? error}) {}

  @override
  void bridgefyDidUpdateState({required String state}) {}

  @override
  void bridgefyDidDestroySession() {}

  @override
  void bridgefyDidEstablishSecureConnection({required String userID}) {}

  @override
  void bridgefyDidFailToDestroySession() {}

  @override
  void bridgefyDidFailToEstablishSecureConnection({
    required String userID,
    BridgefyError? error,
  }) {}

  @override
  void bridgefyDidReceiveDataFromUser({
    required Uint8List data,
    required String messageId,
    required String userID,
  }) {
    bridgefyDidReceiveData(
      data: data,
      messageId: messageId,
      transmissionMode: BridgefyTransmissionMode(
        type: BridgefyTransmissionModeType.p2p,
        uuid: userID,
      ),
    );
  }

  @override
  void bridgefyDidSendDataProgress({
    required String messageID,
    required int position,
    required int of,
  }) {}

  @override
  void dispose() {
    if (isStarted) {
      _bridgefy.stop();
    }
    super.dispose();
  }
}

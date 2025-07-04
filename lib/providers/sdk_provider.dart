// providers/sdk_provider.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:bridgefy/bridgefy.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Command handling for different topics
  final Map<String, Function(Uint8List, String)> _topicHandlers = {};

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

  /// Subscribe to a topic and provide a handler for incoming commands
  Future<void> subscribeToTopic(String topic, Function(Uint8List, String) handler) async {
    print('Subscribing to topic: $topic');
    _topicHandlers[topic] = handler;
  }

  /// Unsubscribe from a topic
  void unsubscribeFromTopic(String topic) {
    print('Unsubscribing from topic: $topic');
    _topicHandlers.remove(topic);
  }

  /// Send raw data to a specific topic
  Future<void> sendTopicMessage(Uint8List data, String topic) async {
    if (!isStarted) {
      throw Exception('Bridgefy not started');
    }

    print('Sending message to topic: $topic, data length: ${data.length}');

    // Create a wrapper that includes topic information in the data payload
    final wrappedData = {
      'topic': topic,
      'payload': base64Encode(data),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final encodedData = Uint8List.fromList(utf8.encode(jsonEncode(wrappedData)));

    await _bridgefy.send(
      data: encodedData,
      transmissionMode: BridgefyTransmissionMode(
        type: BridgefyTransmissionModeType.broadcast,
        uuid: currentUserId,
      ),
    );
  }

  /// Handle incoming data with topic routing
  void _handleTopicMessage(Uint8List data, String messageId, String topic) {
    print('Handling topic message - Topic: $topic, MessageID: $messageId');
    
    final handler = _topicHandlers[topic];
    if (handler != null) {
      try {
        handler(data, messageId);
      } catch (e) {
        print('Error in topic handler for $topic: $e');
      }
    } else {
      print('No handler found for topic: $topic');
    }
  }

  /// Try to parse received data as a topic message
  bool _tryParseTopicMessage(Uint8List data, String messageId) {
    try {
      final jsonString = utf8.decode(data);
      final messageData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check if this is a topic message
      if (messageData.containsKey('topic') && messageData.containsKey('payload')) {
        final topic = messageData['topic'] as String;
        final payloadBase64 = messageData['payload'] as String;
        final payload = base64Decode(payloadBase64);
        
        _handleTopicMessage(payload, messageId, topic);
        return true;
      }
    } catch (e) {
      // Not a topic message, continue with regular parsing
      print('Not a topic message or parsing failed: $e');
    }
    return false;
  }

  Future<void> initialize() async {
    if (isInitialized) {
      print('SDK already initialized');
      return;
    }

    try {
      statusMessage = 'Initializing...';
      notifyListeners();

      currentUserId = const Uuid().v4();
      print('Initializing Bridgefy with user ID: $currentUserId');

      await _bridgefy.initialize(
        apiKey: "3b431d37-6394-4dad-8ce5-a1785cfd9a5c",
        delegate: this,
        verboseLogging: true, // Enable for debugging
      );

      isInitialized = await _bridgefy.isInitialized;
      print('Bridgefy initialized: $isInitialized');

      if (isInitialized) {
        await start();
      } else {
        statusMessage = 'Initialization failed';
      }

      notifyListeners();
    } catch (e) {
      print('Error during initialization: $e');
      statusMessage = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (!isInitialized || !permissionsGranted) {
      if (!permissionsGranted) {
        permissionsGranted = await checkPermissions();
        if (!permissionsGranted) {
          print('Permissions not granted, cannot start');
          return;
        }
      }
      if (!isInitialized) {
        print('Not initialized, initializing first');
        await initialize();
        return;
      }
    }

    try {
      print('Starting Bridgefy...');
      statusMessage = 'Starting...';
      notifyListeners();
      
      await _bridgefy.start();
    } catch (e) {
      print('Error starting Bridgefy: $e');
      statusMessage = 'Failed to start: $e';
      notifyListeners();
    }
  }
  Future<String> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'Unknown User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Unknown User';
    }
  }
  Future<void> stop() async {
    if (!isInitialized || !isStarted) {
      print('Cannot stop - not initialized or not started');
      return;
    }

    try {
      print('Stopping Bridgefy...');
      await _bridgefy.stop();
    } catch (e) {
      print('Error stopping Bridgefy: $e');
      statusMessage = 'Failed to stop: $e';
      notifyListeners();
    }
  }

  Future<List<String>> get connectedPeers async {
    try {
      if (!isStarted) return [];
      return await _bridgefy.connectedPeers;
    } catch (e) {
      print('Error getting connected peers: $e');
      return [];
    }
  }

  /// Send a chat message
  Future<void> sendMessage(ChatMessage message) async {
    if (!isStarted) throw Exception('Not connected');

    final userName = await _getUserName();
    
    final messageData = {
      'id': message.id,
      'content': message.content,
      'senderId': message.senderId,
      'senderName': userName, // Add sender name
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'type': 'chat',
    };

    final data = Uint8List.fromList(utf8.encode(jsonEncode(messageData)));

    await _bridgefy.send(
      data: data,
      transmissionMode: BridgefyTransmissionMode(
        type: BridgefyTransmissionModeType.broadcast,
        uuid: currentUserId,
      ),
    );
  }  void addMessage(ChatMessage message) {
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
        senderName: messageData['senderName'] ?? 'Unknown User', // Add this line
        timestamp: messageData['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(messageData['timestamp'])
            : DateTime.now(),
        isFromMe: false,
        status: MessageStatus.sent,
      );
    } catch (e) {
      print('Error parsing message, treating as plain text: $e');
      return ChatMessage(
        id: messageId,
        content: utf8.decode(data),
        senderId: 'Unknown',
        senderName: 'Unknown User', // Add this line
        timestamp: DateTime.now(),
        isFromMe: false,
        status: MessageStatus.sent,
      );
    }
  }
  // Bridgefy Delegate Methods
  @override
  void bridgefyDidStart({required String currentUserID}) {
    print('Bridgefy started with user ID: $currentUserID');
    isStarted = true;
    currentUserId = currentUserID;
    statusMessage = 'Connected to mesh network';
    notifyListeners();
  }

  @override
  void bridgefyDidFailToStart({BridgefyError? error}) {
    print('Bridgefy failed to start: ${error?.message}');
    isStarted = false;
    statusMessage = 'Failed to start: ${error?.message ?? 'Unknown error'}';
    notifyListeners();
  }

  @override
  void bridgefyDidStop() {
    print('Bridgefy stopped');
    isStarted = false;
    connectedPeersCount = 0;
    statusMessage = 'Disconnected';
    notifyListeners();
  }

  @override
  void bridgefyDidConnect({required String userID}) {
    print('User connected: $userID');
    connectedPeersCount++;
    statusMessage = 'Connected ($connectedPeersCount peers)';
    notifyListeners();
  }

  @override
  void bridgefyDidDisconnect({required String userID}) {
    print('User disconnected: $userID');
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
    String? topic,
  }) {
    print('Received data - MessageID: $messageId, Topic: $topic, Data length: ${data.length}');
    
    try {
      // First try to parse as topic message
      if (_tryParseTopicMessage(data, messageId)) {
        return;
      }

      // Handle regular chat messages
      final message = _parseReceivedMessage(data, messageId);
      addMessage(message);
    } catch (e) {
      print('Error handling received data: $e');
    }
  }

  @override
  void bridgefyDidReceiveDataFromUser({
    required Uint8List data,
    required String messageId,
    required String userID,
    String? topic,
  }) {
    print('Received data from user: $userID, MessageID: $messageId, Topic: $topic');
    
    try {
      // First try to parse as topic message
      if (_tryParseTopicMessage(data, messageId)) {
        return;
      }

      // Handle regular chat messages
      final message = _parseReceivedMessage(data, messageId);
      addMessage(message);
    } catch (e) {
      print('Error handling received data from user: $e');
    }
  }

  @override
  void bridgefyDidSendMessage({required String messageID}) {
    print('Message sent successfully: $messageID');
    updateMessageStatus(messageID, MessageStatus.sent);
  }

  @override
  void bridgefyDidFailSendingMessage({
    required String messageID,
    BridgefyError? error,
  }) {
    print('Failed to send message: $messageID, Error: ${error?.message}');
    updateMessageStatus(messageID, MessageStatus.failed);
  }

  // Other required delegate methods with minimal implementations
  @override
  void bridgefyDidFailToStop({BridgefyError? error}) {
    print('Failed to stop Bridgefy: ${error?.message}');
  }

  @override
  void bridgefyDidUpdateState({required String state}) {
    print('Bridgefy state updated: $state');
  }

  @override
  void bridgefyDidDestroySession() {
    print('Bridgefy session destroyed');
  }

  @override
  void bridgefyDidEstablishSecureConnection({required String userID}) {
    print('Secure connection established with: $userID');
  }

  @override
  void bridgefyDidFailToDestroySession() {
    print('Failed to destroy Bridgefy session');
  }

  @override
  void bridgefyDidFailToEstablishSecureConnection({
    required String userID,
    BridgefyError? error,
  }) {
    print('Failed to establish secure connection with $userID: ${error?.message}');
  }

  @override
  void bridgefyDidSendDataProgress({
    required String messageID,
    required int position,
    required int of,
  }) {
    print('Send progress for message $messageID: $position/$of');
  }

  @override
  void dispose() {
    print('Disposing SdkProvider');
    if (isStarted) {
      _bridgefy.stop().catchError((e) {
        print('Error stopping Bridgefy during dispose: $e');
      });
    }
    super.dispose();
  }
}
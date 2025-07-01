import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:new_project/providers/sdk_provider.dart';

// Enums
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
}

// Models
class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final bool isFromMe;
  final MessageStatus status;
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    required this.isFromMe,
    this.status = MessageStatus.sent,
    this.senderName,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFromMe': isFromMe,
      'status': status.index,
      'senderName': senderName,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isFromMe: json['isFromMe'] as bool,
      status: MessageStatus.values[json['status'] as int],
      senderName: json['senderName'] as String?,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    DateTime? timestamp,
    bool? isFromMe,
    MessageStatus? status,
    String? senderName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      status: status ?? this.status,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, senderId: $senderId, timestamp: $timestamp, isFromMe: $isFromMe, status: $status, senderName: $senderName)';
  }
}

class ConnectedPeer {
  final String id;
  final String displayName;
  final DateTime connectedAt;
  final bool isSecureConnection;

  const ConnectedPeer({
    required this.id,
    required this.displayName,
    required this.connectedAt,
    this.isSecureConnection = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'connectedAt': connectedAt.millisecondsSinceEpoch,
      'isSecureConnection': isSecureConnection,
    };
  }

  factory ConnectedPeer.fromJson(Map<String, dynamic> json) {
    return ConnectedPeer(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      connectedAt:
          DateTime.fromMillisecondsSinceEpoch(json['connectedAt'] as int),
      isSecureConnection: json['isSecureConnection'] as bool? ?? false,
    );
  }

  ConnectedPeer copyWith({
    String? id,
    String? displayName,
    DateTime? connectedAt,
    bool? isSecureConnection,
  }) {
    return ConnectedPeer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      connectedAt: connectedAt ?? this.connectedAt,
      isSecureConnection: isSecureConnection ?? this.isSecureConnection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectedPeer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConnectedPeer(id: $id, displayName: $displayName, connectedAt: $connectedAt, isSecureConnection: $isSecureConnection)';
  }
}

// Chat Provider
class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ConnectedPeer> _connectedPeers = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _currentUserId;
  String? _errorMessage;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ConnectedPeer> get connectedPeers => List.unmodifiable(_connectedPeers);
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get currentUserId => _currentUserId;
  String? get errorMessage => _errorMessage;

  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  int get messageCount => _messages.length;
  int get peerCount => _connectedPeers.length;

  SdkProvider? _sdkProvider;
  String userId = '';
  void setSDK(SdkProvider sdkProvider) {
    _sdkProvider = sdkProvider;
    userId = _sdkProvider!.userId;
    final newMessage = _sdkProvider?.newMessage;
    if (newMessage != null) {
      _sdkProvider!.resetNewMessage();
    }
  }

  // Message methods
  void addMessage(ChatMessage message) {
    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }

  void updateMessageStatus(String messageId, MessageStatus newStatus) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  ChatMessage? getMessageById(String messageId) {
    return _messages.firstWhereOrNull((msg) => msg.id == messageId);
  }

  List<ChatMessage> getMessagesByPeer(String peerId) {
    return _messages.where((msg) => msg.senderId == peerId).toList();
  }

  List<ChatMessage> getUndeliveredMessages() {
    return _messages
        .where((msg) => msg.status == MessageStatus.failed)
        .toList();
  }

  // Peer methods
  void addPeer(ConnectedPeer peer) {
    if (!_connectedPeers.any((p) => p.id == peer.id)) {
      _connectedPeers.add(peer);
      notifyListeners();
    }
  }

  void removePeer(String peerId) {
    _connectedPeers.removeWhere((peer) => peer.id == peerId);
    notifyListeners();
  }

  void updatePeer(ConnectedPeer updatedPeer) {
    final index =
        _connectedPeers.indexWhere((peer) => peer.id == updatedPeer.id);
    if (index != -1) {
      _connectedPeers[index] = updatedPeer;
      notifyListeners();
    }
  }

  void clearPeers() {
    _connectedPeers.clear();
    notifyListeners();
  }

  ConnectedPeer? getPeerById(String peerId) {
    return _connectedPeers.firstWhereOrNull((peer) => peer.id == peerId);
  }

  bool isPeerConnected(String peerId) {
    return _connectedPeers.any((peer) => peer.id == peerId);
  }

  // Connection methods
  void setConnectionStatus(ConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;

      // Clear error when connecting or connected
      if (status == ConnectionStatus.connecting ||
          status == ConnectionStatus.connected) {
        _errorMessage = null;
      }

      // Clear peers when disconnected
      if (status == ConnectionStatus.disconnected) {
        _connectedPeers.clear();
      }

      notifyListeners();
    }
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _connectionStatus = ConnectionStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_connectionStatus == ConnectionStatus.error) {
      _connectionStatus = ConnectionStatus.disconnected;
    }
    notifyListeners();
  }

  // Utility methods
  void disconnect() {
    setConnectionStatus(ConnectionStatus.disconnected);
    clearPeers();
    clearError();
  }

  void reset() {
    _messages.clear();
    _connectedPeers.clear();
    _connectionStatus = ConnectionStatus.disconnected;
    _currentUserId = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Bulk operations
  void addMessages(List<ChatMessage> messages) {
    _messages.addAll(messages);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }

  void addPeers(List<ConnectedPeer> peers) {
    for (final peer in peers) {
      if (!_connectedPeers.any((p) => p.id == peer.id)) {
        _connectedPeers.add(peer);
      }
    }
    notifyListeners();
  }

  // JSON serialization for persistence
  Map<String, dynamic> toJson() {
    return {
      'messages': _messages.map((msg) => msg.toJson()).toList(),
      'connectedPeers': _connectedPeers.map((peer) => peer.toJson()).toList(),
      'connectionStatus': _connectionStatus.index,
      'currentUserId': _currentUserId,
      'errorMessage': _errorMessage,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _messages = (json['messages'] as List<dynamic>?)
            ?.map((msgJson) =>
                ChatMessage.fromJson(msgJson as Map<String, dynamic>))
            .toList() ??
        [];

    _connectedPeers = (json['connectedPeers'] as List<dynamic>?)
            ?.map((peerJson) =>
                ConnectedPeer.fromJson(peerJson as Map<String, dynamic>))
            .toList() ??
        [];

    _connectionStatus =
        ConnectionStatus.values[json['connectionStatus'] as int? ?? 0];
    _currentUserId = json['currentUserId'] as String?;
    _errorMessage = json['errorMessage'] as String?;

    notifyListeners();
  }
}

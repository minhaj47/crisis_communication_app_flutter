// models/app_models.dart
enum ConnectionType { mesh, lora, starlink, localServer, internet, offline }

enum UserRole {
  imam,
  communityLeader,
  medicalPersonnel,
  emergencyCoordinator,
  volunteer,
  resident,
}

enum MessageType {
  emergency,
  prayer,
  medical,
  resources,
  coordination,
  community,
}

enum MessagePriority { critical, high, normal, low }

enum MeshConnectionStatus {
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

class ConnectionStatus {
  final List<ConnectionType> availableConnections;
  final bool canInitializeMesh;
  final bool localServerReachable;
  final bool internetAvailable;

  ConnectionStatus({
    required this.availableConnections,
    required this.canInitializeMesh,
    required this.localServerReachable,
    required this.internetAvailable,
  });
}

class CrisisMessage {
  final String id;
  final String title;
  final String content;
  final MessageType type;
  final MessagePriority priority;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final UserRole senderRole;
  final int hopCount;
  final double radiusKm;
  final ConnectionType sentVia;

  CrisisMessage({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.senderRole,
    this.hopCount = 0,
    required this.radiusKm,
    required this.sentVia,
  });

  // Convert CrisisMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'senderRole': senderRole.name,
      'hopCount': hopCount,
      'radiusKm': radiusKm,
      'sentVia': sentVia.name,
    };
  }

  // Create CrisisMessage from JSON
  factory CrisisMessage.fromJson(Map<String, dynamic> json) {
    return CrisisMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      content: json['content'] ?? 'Unknown Content',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.emergency,
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => MessagePriority.high,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      senderRole: UserRole.values.firstWhere(
        (e) => e.name == json['senderRole'],
        orElse: () => UserRole.resident,
      ),
      hopCount: json['hopCount'] ?? 0,
      radiusKm: json['radiusKm']?.toDouble() ?? 5.0,
      sentVia: ConnectionType.values.firstWhere(
        (e) => e.name == json['sentVia'],
        orElse: () => ConnectionType.mesh,
      ),
    );
  }

  // Create a copy with updated values
  CrisisMessage copyWith({
    String? id,
    String? title,
    String? content,
    MessageType? type,
    MessagePriority? priority,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    UserRole? senderRole,
    int? hopCount,
    double? radiusKm,
    ConnectionType? sentVia,
  }) {
    return CrisisMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      senderRole: senderRole ?? this.senderRole,
      hopCount: hopCount ?? this.hopCount,
      radiusKm: radiusKm ?? this.radiusKm,
      sentVia: sentVia ?? this.sentVia,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrisisMessage &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.type == type &&
        other.priority == priority &&
        other.timestamp == timestamp &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.senderRole == senderRole &&
        other.hopCount == hopCount &&
        other.radiusKm == radiusKm &&
        other.sentVia == sentVia;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      type,
      priority,
      timestamp,
      latitude,
      longitude,
      senderRole,
      hopCount,
      radiusKm,
      sentVia,
    );
  }

  @override
  String toString() {
    return 'CrisisMessage(id: $id, title: $title, type: $type, priority: $priority, timestamp: $timestamp, hopCount: $hopCount, sentVia: $sentVia)';
  }
}

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

  // JSON serialization for connected peers
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
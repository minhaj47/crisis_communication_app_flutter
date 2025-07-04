// lib/models/chat_models.dart

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName; // Add this field
  final DateTime timestamp;
  final bool isFromMe;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName, // Add this parameter
    required this.timestamp,
    required this.isFromMe,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    String? senderName, // Add this parameter
    DateTime? timestamp,
    bool? isFromMe,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName, // Add this line
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus { sending, sent, failed }

enum ConnectionStatus { disconnected, connecting, connected, error }

class ConnectedPeer {
  final String id;
  final String displayName;
  final DateTime connectedAt;

  ConnectedPeer({
    required this.id,
    required this.displayName,
    required this.connectedAt,
  });
}
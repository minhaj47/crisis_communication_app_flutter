// lib/pages/mesh_chat_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';
import '../providers/sdk_provider.dart';
import '../widgets/message_bubble.dart';
import '../screens/settings_screen.dart';

class MeshChatPage extends StatefulWidget {
  @override
  _MeshChatPageState createState() => _MeshChatPageState();
}

class _MeshChatPageState extends State<MeshChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final provider = context.read<SdkProvider>();

    if (!provider.permissionsGranted) {
      await provider.checkPermissions();
    }

    if (provider.permissionsGranted && !provider.isInitialized) {
      await provider.initialize();
    }
  }

  Future<void> _sendMessage() async {
    final provider = context.read<SdkProvider>();

    if (!provider.isStarted || _messageController.text.trim().isEmpty) {
      return;
    }

    final messageText = _messageController.text.trim();
    final message = ChatMessage(
      id: const Uuid().v4(),
      content: messageText,
      senderId: provider.currentUserId,
      timestamp: DateTime.now(),
      isFromMe: true,
      status: MessageStatus.sending,
    );

    provider.addMessage(message);
    _messageController.clear();
    _scrollToBottom();

    try {
      await provider.sendMessage(message);
    } catch (e) {
      provider.updateMessageStatus(message.id, MessageStatus.failed);
      _showSnackBar('Failed to send message');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SdkProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Mesh Chat'),
            actions: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isStarted ? Icons.wifi : Icons.wifi_off,
                      color: provider.isStarted ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text('${provider.connectedPeersCount}'),
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                color: provider.isStarted
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                child: Text(
                  provider.statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),

              // Messages
              Expanded(
                child: provider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              provider.isStarted
                                  ? 'Start chatting with nearby devices!'
                                  : 'Connect to start chatting',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(
                              message: provider.messages[index]);
                        },
                      ),
              ),

              // Input
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: provider.isStarted
                              ? 'Type a message...'
                              : 'Not connected',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        enabled: provider.isStarted,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: provider.isStarted ? _sendMessage : null,
                      child: Icon(Icons.send),
                      mini: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
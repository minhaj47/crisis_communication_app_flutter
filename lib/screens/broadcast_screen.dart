// screens/broadcast_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/broadcast_message_provider.dart';
import 'package:new_project/models/app_models.dart';
import 'package:new_project/utils/app_constants.dart';
import 'package:new_project/providers/sdk_provider.dart';
import 'package:new_project/screens/settings_screen.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  static const String BROADCAST_TOPIC = 'crisis_broadcast';
  static const String SOS_TOPIC = 'sos_emergency';

  @override
  void initState() {
    super.initState();
    _setupBroadcastListener();
    _setupSOSListener();
  }

  @override
  void dispose() {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    sdkProvider.unsubscribeFromTopic(BROADCAST_TOPIC);
    sdkProvider.unsubscribeFromTopic(SOS_TOPIC);
    super.dispose();
  }

  void _setupBroadcastListener() {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    final broadcastProvider = Provider.of<BroadcastMessageProvider>(context, listen: false);
    sdkProvider.subscribeToTopic(BROADCAST_TOPIC, (Uint8List data, String messageId) {
      try {
        final jsonString = utf8.decode(data);
        final messageData = jsonDecode(jsonString) as Map<String, dynamic>;
        final receivedMessage = CrisisMessage(
          id: messageData['id'] ?? messageId,
          title: messageData['title'] ?? 'Unknown Title',
          content: messageData['content'] ?? 'Unknown Content',
          type: MessageType.values.firstWhere(
            (e) => e.name == messageData['type'],
            orElse: () => MessageType.emergency,
          ),
          priority: MessagePriority.values.firstWhere(
            (e) => e.name == messageData['priority'],
            orElse: () => MessagePriority.high,
          ),
          timestamp: messageData['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(messageData['timestamp'])
              : DateTime.now(),
          latitude: messageData['latitude']?.toDouble() ?? 0.0,
          longitude: messageData['longitude']?.toDouble() ?? 0.0,
          senderRole: UserRole.values.firstWhere(
            (e) => e.name == messageData['senderRole'],
            orElse: () => UserRole.resident,
          ),
          radiusKm: messageData['radiusKm']?.toDouble() ?? 5.0,
          sentVia: ConnectionType.values.firstWhere(
            (e) => e.name == messageData['sentVia'],
            orElse: () => ConnectionType.mesh,
          ),
        );
        broadcastProvider.addMessage(receivedMessage);
      } catch (e) {
        print('Error handling broadcast message: $e');
      }
    });
  }

  void _setupSOSListener() {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    final broadcastProvider = Provider.of<BroadcastMessageProvider>(context, listen: false);
    sdkProvider.subscribeToTopic(SOS_TOPIC, (Uint8List data, String messageId) {
      try {
        final jsonString = utf8.decode(data);
        final sosData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final senderName = sosData['senderName'] ?? 'Unknown';
        final location = sosData['location'] as Map<String, dynamic>?;
        final timestamp = sosData['timestamp'] as int?;
        
        // Create a CrisisMessage for SOS
        final sosMessage = CrisisMessage(
          id: messageId,
          title: 'SOS EMERGENCY',
          content: 'EMERGENCY: $senderName needs immediate assistance!',
          type: MessageType.emergency,
          priority: MessagePriority.high,
          timestamp: timestamp != null 
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.now(),
          latitude: location?['latitude']?.toDouble() ?? 0.0,
          longitude: location?['longitude']?.toDouble() ?? 0.0,
          senderRole: UserRole.resident,
          radiusKm: 5.0,
          sentVia: ConnectionType.mesh,
        );
        
        broadcastProvider.addMessage(sosMessage);
        
      } catch (e) {
        print('Error handling SOS message: $e');
      }
    });
  }

  Widget _buildMessagesView(BroadcastMessageProvider broadcastProvider) {
    return broadcastProvider.messages.isEmpty
        ? _buildEmptyMessagesState()
        : RefreshIndicator(
            onRefresh: () async {
              // Refresh connection status and reload messages
              if (!Provider.of<SdkProvider>(context, listen: false).isStarted) {
                await Provider.of<SdkProvider>(context, listen: false).start();
              }
              await broadcastProvider.loadMessages();
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: broadcastProvider.messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageCard(broadcastProvider.messages[index]),
            ),
          );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Provider.of<SdkProvider>(context, listen: false).isStarted
                ? Icons.message_outlined
                : Icons.signal_wifi_off,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 24),
          Text(
            Provider.of<SdkProvider>(context, listen: false).isStarted
                ? 'No messages yet'
                : 'Not connected to mesh network',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            Provider.of<SdkProvider>(context, listen: false).isStarted
                ? 'Emergency messages and broadcasts will appear here'
                : 'Pull down to refresh and connect to the mesh network',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (!Provider.of<SdkProvider>(context, listen: false).isStarted) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<SdkProvider>(context, listen: false).start();
              },
              child: Text('Connect to Mesh Network'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageCard(CrisisMessage message) {
    final isSOSMessage = message.title == 'SOS EMERGENCY' || message.title == 'SOS EMERGENCY (SENT)';
    final isSentMessage = message.title.contains('(SENT)');
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isSOSMessage ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSOSMessage 
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      color: isSOSMessage ? Colors.red.shade50 : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSOSMessage ? Colors.red : _getPriorityColor(message.priority),
                  child: Icon(
                    isSOSMessage ? Icons.warning : _getMessageTypeIcon(message.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSOSMessage) ...[
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              message.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSOSMessage ? Colors.red : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(message.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.priority.name.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(message.priority),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14, 
                height: 1.4,
                color: isSOSMessage ? Colors.red.shade700 : null,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppConstants.messageTypeLabels[message.type]!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: message.sentVia == ConnectionType.mesh 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        message.sentVia == ConnectionType.mesh 
                            ? Icons.device_hub
                            : Icons.cell_tower,
                        size: 12,
                        color: message.sentVia == ConnectionType.mesh 
                            ? Colors.blue
                            : Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        message.sentVia == ConnectionType.mesh ? 'Mesh' : 'Cellular',
                        style: TextStyle(
                          fontSize: 12,
                          color: message.sentVia == ConnectionType.mesh 
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearMessagesDialog(BroadcastMessageProvider broadcastProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Messages'),
        content: Text('Are you sure you want to clear all stored messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              broadcastProvider.clearMessages();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All messages cleared'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotConnectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.signal_wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Not Connected'),
          ],
        ),
        content: Text('You need to be connected to the mesh network to send broadcast messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
              await sdkProvider.start();
            },
            child: Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    MessageType selectedType = MessageType.emergency;
    MessagePriority selectedPriority = MessagePriority.high;
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Row
                            Row(
                              children: [
                                Icon(Icons.broadcast_on_personal,
                                    color: Color(0xFF2E7D32)),
                                SizedBox(width: 8),
                                Text(
                                  'Broadcast Message',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.close),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Network Info
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.device_hub,
                                      color: Colors.blue, size: 16),
                                  SizedBox(width: 8),
                                  Consumer<SdkProvider>(
                                    builder: (context, sdkProvider, child) {
                                      return Text(
                                        'Broadcasting to ${sdkProvider.connectedPeersCount} peers',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // Message Type
                            Text('Message Type',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<MessageType>(
                                value: selectedType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: MessageType.values.map((type) {
                                  return DropdownMenuItem<MessageType>(
                                    value: type,
                                    child: Text(
                                        AppConstants.messageTypeLabels[type]!),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => selectedType = value!),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Priority
                            Text('Priority',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<MessagePriority>(
                                value: selectedPriority,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: MessagePriority.values.map((priority) {
                                  return DropdownMenuItem<MessagePriority>(
                                    value: priority,
                                    child: Text(priority.name.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => selectedPriority = value!),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Title Input
                            Text('Title',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller: titleController,
                                decoration: InputDecoration(
                                  hintText: 'Enter message title',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Message Input
                            Text('Message',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller: contentController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Enter your message content',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons (Sticky Bottom)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _sendBroadcast(
                                context,
                                selectedType,
                                selectedPriority,
                                titleController.text,
                                contentController.text,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('SEND'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendBroadcast(
    BuildContext context,
    MessageType type,
    MessagePriority priority,
    String title,
    String content,
  ) async {
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);

    if (!sdkProvider.isStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not connected to mesh network'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final newMessage = CrisisMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        type: type,
        priority: priority,
        timestamp: DateTime.now(),
        latitude: 0.0, // TODO: Get actual location
        longitude: 0.0, // TODO: Get actual location
        senderRole: UserRole.resident,
        radiusKm: 5.0,
        sentVia: ConnectionType.mesh,
      );

      // Create message data for mesh network
      final messageData = {
        'id': newMessage.id,
        'title': newMessage.title,
        'content': newMessage.content,
        'type': newMessage.type.name,
        'priority': newMessage.priority.name,
        'timestamp': newMessage.timestamp.millisecondsSinceEpoch,
        'latitude': newMessage.latitude,
        'longitude': newMessage.longitude,
        'senderRole': newMessage.senderRole.name,
        'radiusKm': newMessage.radiusKm,
        'sentVia': newMessage.sentVia.name,
      };

      // Convert to bytes for mesh network transmission
      final jsonString = jsonEncode(messageData);
      final data = Uint8List.fromList(utf8.encode(jsonString));

      // Send via mesh network
      await sdkProvider.sendTopicMessage(data, BROADCAST_TOPIC);

      // Add to provider
      final broadcastProvider = Provider.of<BroadcastMessageProvider>(context, listen: false);
      await broadcastProvider.addMessage(newMessage);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message broadcasted to ${sdkProvider.connectedPeersCount} peers'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error sending broadcast: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send broadcast: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BroadcastMessageProvider>(
      builder: (context, broadcastProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Broadcast Messages'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),
              // Add clear messages button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearMessagesDialog(broadcastProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20),
                        SizedBox(width: 8),
                        Text('Clear All Messages'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Provider.of<SdkProvider>(context, listen: false).isStarted
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: Provider.of<SdkProvider>(context, listen: false)
                              .isStarted
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      Provider.of<SdkProvider>(context, listen: false)
                          .statusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Provider.of<SdkProvider>(context, listen: false)
                                .isStarted
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    Spacer(),
                    if (Provider.of<SdkProvider>(context, listen: false)
                            .isStarted &&
                        Provider.of<SdkProvider>(context, listen: false)
                                .connectedPeersCount >
                            0)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${Provider.of<SdkProvider>(context, listen: false).connectedPeersCount} peers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          body: _buildMessagesView(broadcastProvider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: Provider.of<SdkProvider>(context, listen: false).isStarted
                ? _showBroadcastDialog
                : _showNotConnectedDialog,
            backgroundColor: Provider.of<SdkProvider>(context, listen: false)
                    .isStarted
                ? Color(0xFF2E7D32)
                : Colors.grey,
            icon: Icon(
              Provider.of<SdkProvider>(context, listen: false).isStarted
                  ? Icons.broadcast_on_personal
                  : Icons.signal_wifi_off,
              color: Colors.white,
            ),
            label: Text(
              Provider.of<SdkProvider>(context, listen: false).isStarted
                  ? 'Broadcast'
                  : 'Not Connected',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.high:
        return Colors.red;
      case MessagePriority.normal:
        return Colors.orange;
      case MessagePriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.emergency:
        return Icons.emergency;
      case MessageType.medical:
        return Icons.warning;
      case MessageType.resources:
        return Icons.info;
      case MessageType.coordination:
        return Icons.check_circle;
      default:
        return Icons.message;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
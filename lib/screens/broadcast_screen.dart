// screens/broadcast_screen.dart
import 'package:flutter/material.dart';
import 'package:new_project/models/app_models.dart';
import 'package:new_project/utils/app_constants.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  List<CrisisMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _buildMessagesView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBroadcastDialog,
        backgroundColor: Color(0xFF2E7D32),
        icon: Icon(Icons.broadcast_on_personal, color: Colors.white),
        label: Text('Broadcast', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMessagesView() {
    return _messages.isEmpty
        ? _buildEmptyMessagesState()
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) =>
                _buildMessageCard(_messages[index]),
          );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          const Text(
            'Tap the broadcast button to send your first message',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(CrisisMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getPriorityColor(message.priority),
                  child: Icon(
                    _getMessageTypeIcon(message.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 8),
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
          ],
        ),
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
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.broadcast_on_personal,
                            color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text(
                          'Broadcast Message',
                          style: TextStyle(
                            fontSize: 20,
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

                    // Message Type Selection
                    Text('Message Type',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<MessageType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: MessageType.values.map((type) {
                        return DropdownMenuItem<MessageType>(
                          value: type,
                          child: Text(AppConstants.messageTypeLabels[type]!),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedType = value!),
                    ),

                    SizedBox(height: 16),

                    // Priority Selection
                    Text('Priority',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<MessagePriority>(
                      value: selectedPriority,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                    SizedBox(height: 16),

                    // Title Input
                    Text('Title',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter message title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Content Input
                    Text('Message',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        hintText: 'Enter your message content',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: 24),

                    // Action Buttons
                    Row(
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sendBroadcast(
    BuildContext context,
    MessageType type,
    MessagePriority priority,
    String title,
    String content,
  ) {
    if (title.isNotEmpty && content.isNotEmpty) {
      final newMessage = CrisisMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        type: type,
        priority: priority,
        timestamp: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        senderRole: UserRole.resident,
        radiusKm: 5.0,
        sentVia: ConnectionType.mesh,
      );

      setState(() {
        _messages.insert(0, newMessage);
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message broadcasted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

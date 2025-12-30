import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/firestore_service.dart';
import '../../models/message_model.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({Key? key}) : super(key: key);

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _messageController = TextEditingController();
  bool _isBroadcast = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final message = MessageModel(
        id: '',
        type: _isBroadcast ? 'broadcast' : 'direct',
        senderId: 'admin',
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _firestoreService.sendMessage(message);
      
      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFF1E40AF)),
                const SizedBox(width: 8),
                const Text(
                  'Communications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'Live Chat',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.streamMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdmin = message.senderId == 'admin';

                    return Align(
                      alignment: isAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? const Color(0xFF1E40AF)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.isBroadcast)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.campaign,
                                      size: 12,
                                      color: isAdmin
                                          ? Colors.white
                                          : Colors.orange[900],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Broadcast',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin
                                            ? Colors.white
                                            : Colors.orange[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isAdmin ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isAdmin
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: PopupMenuButton<bool>(
                        icon: Icon(
                          _isBroadcast ? Icons.campaign : Icons.person,
                          color: const Color(0xFF1E40AF),
                        ),
                        onSelected: (value) {
                          setState(() {
                            _isBroadcast = value;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: true,
                            child: Row(
                              children: [
                                Icon(Icons.campaign),
                                SizedBox(width: 8),
                                Text('Broadcast'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: false,
                            child: Row(
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 8),
                                Text('Direct'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: const Color(0xFF1E40AF),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

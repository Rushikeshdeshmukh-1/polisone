import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'enhanced_chat_screen.dart';
import '../../widgets/broadcast_composer.dart';

class CommunicationHubScreen extends StatefulWidget {
  final bool isAdmin;
  
  const CommunicationHubScreen({
    Key? key,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<CommunicationHubScreen> createState() => _CommunicationHubScreenState();
}

class _CommunicationHubScreenState extends State<CommunicationHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isAdmin ? 3 : 2, vsync: this);
    _loadUnreadCount();
    _createDefaultChannelsIfNeeded();
  }

  Future<void> _createDefaultChannelsIfNeeded() async {
    try {
      // Check if channels already exist
      final snapshot = await _firestore.collection('communication_channels').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Create default channels
        final defaultChannels = [
          {
            'id': 'general',
            'name': 'General',
            'type': 'general',
            'description': 'General communication for all officers',
          },
          {
            'id': 'shift_morning',
            'name': 'Morning Shift',
            'type': 'shift',
            'description': 'Morning shift officers',
            'metadata': {'shift': 'Morning'},
          },
          {
            'id': 'shift_evening',
            'name': 'Evening Shift',
            'type': 'shift',
            'description': 'Evening shift officers',
            'metadata': {'shift': 'Evening'},
          },
          {
            'id': 'shift_night',
            'name': 'Night Shift',
            'type': 'shift',
            'description': 'Night shift officers',
            'metadata': {'shift': 'Night'},
          },
          {
            'id': 'beat_a',
            'name': 'Beat A',
            'type': 'beat',
            'description': 'Beat A officers',
            'metadata': {'beat': 'Beat A'},
          },
          {
            'id': 'beat_b',
            'name': 'Beat B',
            'type': 'beat',
            'description': 'Beat B officers',
            'metadata': {'beat': 'Beat B'},
          },
        ];

        for (var channel in defaultChannels) {
          await _firestore.collection('communication_channels').doc(channel['id'] as String).set({
            'name': channel['name'],
            'type': channel['type'],
            'description': channel['description'],
            'createdBy': _auth.currentUser?.uid ?? 'system',
            'createdAt': FieldValue.serverTimestamp(),
            'members': [],
            'admins': [_auth.currentUser?.uid ?? 'admin'],
            'lastMessage': channel['name'] == 'General' ? 'Welcome to ${channel['name']}!' : '',
            'lastActivity': FieldValue.serverTimestamp(),
            'unreadCount': {},
            'typingUsers': {},
            'metadata': channel['metadata'] ?? {},
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Default channels created!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - channels might already exist or permissions issue
      print('Channel creation: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('user_messages')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() => _unreadCount = snapshot.docs.length);
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: _unreadCount > 0 ? Text('$_unreadCount') : null,
                child: const Icon(Icons.forum),
              ),
              text: 'Channels',
            ),
            const Tab(icon: Icon(Icons.message), text: 'Direct'),
            if (widget.isAdmin)
              const Tab(icon: Icon(Icons.campaign), text: 'Broadcasts'),
          ],
        ),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Channel',
              onPressed: () => _showCreateChannelDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChannelsTab(),
          _buildDirectMessagesTab(),
          if (widget.isAdmin) _buildBroadcastsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.isAdmin) {
            showDialog(
              context: context,
              builder: (context) => const BroadcastComposerDialog(),
            );
          } else {
            _showNewMessageDialog();
          }
        },
        icon: Icon(widget.isAdmin ? Icons.campaign : Icons.add),
        label: Text(widget.isAdmin ? 'Broadcast' : 'New Message'),
        backgroundColor: const Color(0xFF1E40AF),
      ),
    );
  }

  Widget _buildChannelsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communication_channels')
          .where('type', whereIn: ['general', 'shift', 'beat', 'department'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final channels = snapshot.data!.docs;

        if (channels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No channels yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                if (widget.isAdmin)
                  ElevatedButton.icon(
                    onPressed: _showCreateChannelDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Channel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final data = channels[index].data() as Map<String, dynamic>;
            return _buildChannelTile(channels[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildChannelTile(String channelId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Channel';
    final lastMessage = data['lastMessage'] ?? '';
    final lastActivity = (data['lastActivity'] as Timestamp?)?.toDate();
    final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[_auth.currentUser?.uid] ?? 0;
    final type = data['type'] ?? 'general';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'shift':
        icon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case 'beat':
        icon = Icons.location_on;
        iconColor = Colors.green;
        break;
      case 'department':
        icon = Icons.business;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.forum;
        iconColor = Colors.blue;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: lastActivity != null
          ? Text(
              _formatTime(lastActivity),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatScreen(
              channelId: channelId,
              channelName: name,
              channelType: type,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectMessagesTab() {
    final userId = _auth.currentUser?.uid;
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('user_messages')
          .where('userId', isEqualTo: userId)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a broadcast to see messages here',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            return _buildMessageTile(messages[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildMessageTile(String messageId, Map<String, dynamic> data) {
    final message = data['message'] ?? '';
    final senderName = data['senderName'] ?? 'Unknown';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final isRead = data['isRead'] ?? false;
    final priority = data['priority'] ?? 'normal';
    final type = data['type'] ?? 'direct';

    Color? tileColor;
    if (priority == 'urgent') tileColor = Colors.orange[50];
    if (priority == 'emergency') tileColor = Colors.red[50];

    return ListTile(
      tileColor: tileColor,
      leading: CircleAvatar(
        backgroundColor: type == 'broadcast' ? Colors.blue[100] : Colors.grey[200],
        child: Icon(
          type == 'broadcast' ? Icons.campaign : Icons.person,
          color: type == 'broadcast' ? const Color(0xFF1E40AF) : Colors.grey[600],
        ),
      ),
      title: Row(
        children: [
          if (priority != 'normal')
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.priority_high,
                size: 16,
                color: priority == 'emergency' ? Colors.red : Colors.orange,
              ),
            ),
          Expanded(
            child: Text(
              senderName,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          if (type == 'broadcast')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BROADCAST',
                style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF)),
              ),
            ),
        ],
      ),
      subtitle: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timestamp != null)
            Text(
              _formatTime(timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        _markAsRead(messageId);
        _showMessageDetail(data);
      },
    );
  }

  Widget _buildBroadcastsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('broadcasts')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final broadcasts = snapshot.data!.docs;

        if (broadcasts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No broadcasts yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const BroadcastComposerDialog(),
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('Send Broadcast'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: broadcasts.length,
          itemBuilder: (context, index) {
            final data = broadcasts[index].data() as Map<String, dynamic>;
            return _buildBroadcastTile(data);
          },
        );
      },
    );
  }

  Widget _buildBroadcastTile(Map<String, dynamic> data) {
    final message = data['message'] ?? '';
    final priority = data['priority'] ?? 'normal';
    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
    final deliveryStatus = data['deliveryStatus'] as Map<String, dynamic>?;
    final sent = deliveryStatus?['sent'] ?? 0;
    final read = deliveryStatus?['read'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
                const Spacer(),
                if (sentAt != null)
                  Text(
                    DateFormat('MMM dd, h:mm a').format(sentAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.send, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$sent sent', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.done_all, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$read read', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'important':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      case 'emergency':
        return Colors.red[900]!;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await _firestore.collection('user_messages').doc(messageId).update({
        'isRead': true,
      });
      _loadUnreadCount();
    } catch (e) {
      // Handle error
    }
  }

  void _showMessageDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['senderName'] ?? 'Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['priority'] != 'normal')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(data['priority']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (data['priority'] ?? 'normal').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(data['priority']),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(data['message'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: const Text('Direct messaging coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  hintText: 'e.g., Beat C',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Channel description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Channel Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'shift', child: Text('Shift')),
                  DropdownMenuItem(value: 'beat', child: Text('Beat')),
                  DropdownMenuItem(value: 'department', child: Text('Department')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a channel name')),
                  );
                  return;
                }

                try {
                  await _firestore.collection('communication_channels').add({
                    'name': nameController.text.trim(),
                    'type': selectedType,
                    'description': descController.text.trim(),
                    'createdBy': _auth.currentUser?.uid ?? 'admin',
                    'createdAt': FieldValue.serverTimestamp(),
                    'members': [],
                    'admins': [_auth.currentUser?.uid ?? 'admin'],
                    'lastMessage': '',
                    'lastActivity': FieldValue.serverTimestamp(),
                    'unreadCount': {},
                    'typingUsers': {},
                    'metadata': {},
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Channel created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            // Implement search
          },
        ),
      ),
    );
  }
}

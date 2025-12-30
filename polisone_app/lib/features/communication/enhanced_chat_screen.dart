import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/file_picker_helper.dart';
import '../../widgets/voice_message_recorder.dart';
import '../../widgets/quick_reply_picker.dart';
import '../../widgets/message_search_dialog.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String channelType;

  const EnhancedChatScreen({
    Key? key,
    required this.channelId,
    required this.channelName,
    this.channelType = 'general',
  }) : super(key: key);

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isSending = false;
  bool _isTyping = false;
  String? _replyToMessageId;
  String? _replyToText;
  
  final Map<String, String> _priorityEmojis = {
    'normal': '',
    'important': '⚠️',
    'urgent': '🚨',
    'emergency': '🆘',
  };

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTyping(String text) {
    final isTyping = text.isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
      // Update typing status in Firestore
      _firestore
          .collection('communication_channels')
          .doc(widget.channelId)
          .update({
        'typingUsers.${_auth.currentUser?.uid}': isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channelName, style: const TextStyle(fontSize: 16)),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('communication_channels').doc(widget.channelId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final typingUsers = data?['typingUsers'] as Map<String, dynamic>?;
                
                if (typingUsers != null && typingUsers.isNotEmpty) {
                  final otherTyping = typingUsers.keys.where((uid) => uid != _auth.currentUser?.uid).length;
                  if (otherTyping > 0) {
                    return const Text(
                      'typing...',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                    );
                  }
                }
                
                return const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.normal),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChannelInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply preview
          if (_replyToMessageId != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    color: const Color(0xFF1E40AF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Replying to',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _replyToText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                      _replyToMessageId = null;
                      _replyToText = null;
                    }),
                  ),
                ],
              ),
            ),
          
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('communication_channels')
                  .doc(widget.channelId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet.\\nStart the conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _auth.currentUser?.uid;

                    return _buildEnhancedMessageBubble(doc.id, data, isMe);
                  },
                );
              },
            ),
          ),
          
          _buildEnhancedMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(String messageId, Map<String, dynamic> data, bool isMe) {
    final priority = data['priority'] ?? 'normal';
    final priorityEmoji = _priorityEmojis[priority] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final readBy = (data['readBy'] as List?)?.cast<String>() ?? [];
    final reactions = data['reactions'] as Map<String, dynamic>?;
    final replyTo = data['replyTo'] as String?;
    final attachments = (data['attachments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Mark as read if not already
    if (!isMe && !readBy.contains(_auth.currentUser?.uid)) {
      _firestore
          .collection('communication_channels')
          .doc(widget.channelId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([_auth.currentUser?.uid]),
      });
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(messageId, data, isMe),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF1E40AF) : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                  border: priority != 'normal'
                      ? Border.all(
                          color: priority == 'emergency' ? Colors.red : Colors.orange,
                          width: 2,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Priority indicator
                    if (priority != 'normal')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$priorityEmoji ${priority.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : Colors.red,
                          ),
                        ),
                      ),
                    
                    // Sender name (if not me)
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          data['senderName'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    
                    // Reply preview
                    if (replyTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '↩️ Reply to message',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    
                    // Attachments
                    if (attachments.isNotEmpty)
                      ...attachments.map((attachment) => _buildAttachment(attachment, isMe)),
                    
                    // Message text
                    Text(
                      data['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Time and read receipts
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timestamp != null ? DateFormat('h:mm a').format(timestamp) : '',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            readBy.length > 1 ? Icons.done_all : Icons.done,
                            size: 14,
                            color: readBy.length > 1 ? Colors.blue[200] : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Reactions
              if (reactions != null && reactions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Wrap(
                    spacing: 4,
                    children: reactions.entries.map((entry) {
                      return Text('${entry.value} ', style: const TextStyle(fontSize: 14));
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachment(Map<String, dynamic> attachment, bool isMe) {
    final type = attachment['type'] ?? 'file';
    final name = attachment['name'] ?? 'File';
    
    // Voice message player
    if (type == 'voice') {
      final url = attachment['url'] ?? '';
      final duration = attachment['duration'] ?? 0;
      return VoiceMessagePlayer(
        audioUrl: url,
        duration: duration,
        isMe: isMe,
      );
    }
    
    // Regular file attachment
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == 'image' ? Icons.image : Icons.insert_drive_file,
            size: 20,
            color: isMe ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.flash_on, color: Color(0xFF1E40AF)),
              tooltip: 'Quick Replies',
              onPressed: _showQuickReplies,
            ),
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFF1E40AF)),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _handleTyping,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final user = _auth.currentUser;
      final senderName = user?.email?.split('@')[0] ?? 'User';

      await _firestore
          .collection('communication_channels')
          .doc(widget.channelId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user?.uid,
        'senderName': senderName,
        'senderRole': 'officer', // Would fetch from user doc
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'priority': 'normal',
        'readBy': [user?.uid],
        'replyTo': _replyToMessageId,
        'attachments': [],
        'reactions': {},
        'isEdited': false,
        'isDeleted': false,
      });

      await _firestore.collection('communication_channels').doc(widget.channelId).update({
        'lastMessage': text,
        'lastActivity': FieldValue.serverTimestamp(),
        'typingUsers.${user?.uid}': FieldValue.delete(),
      });

      _messageController.clear();
      setState(() {
        _replyToMessageId = null;
        _replyToText = null;
        _isTyping = false;
      });
      
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showMessageActions(String messageId, Map<String, dynamic> data, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessageId = messageId;
                  _replyToText = data['text'];
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // Copy to clipboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(messageId);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    final reactions = ['👍', '❤️', '😊', '🎉', '✅', '⚠️'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('React to message'),
        content: Wrap(
          spacing: 12,
          children: reactions.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addReaction(messageId, emoji);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    try {
      await _firestore
          .collection('communication_channels')
          .doc(widget.channelId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.${_auth.currentUser?.uid}': emoji,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('communication_channels')
          .doc(widget.channelId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'text': 'Message deleted',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF1E40AF)),
              title: const Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF1E40AF)),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFF1E40AF)),
              title: const Text('Voice Message'),
              onTap: () {
                Navigator.pop(context);
                _recordVoiceMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF1E40AF)),
              title: const Text('Location'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await getFilePicker().pickImage();
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${file.name}')),
      );
      // Would upload to Firebase Storage here
    }
  }

  Future<void> _pickDocument() async {
    final file = await getFilePicker().pickFile(['.pdf', '.doc', '.docx']);
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${file.name}')),
      );
    }
  }

  void _recordVoiceMessage() {
    showDialog(
      context: context,
      builder: (context) => VoiceMessageRecorder(
        onRecordingComplete: (audioUrl, duration) async {
          // Send voice message to chat
          try {
            final user = _auth.currentUser;
            final senderName = user?.email?.split('@')[0] ?? 'User';

            await _firestore
                .collection('communication_channels')
                .doc(widget.channelId)
                .collection('messages')
                .add({
              'text': '🎙️ Voice message ($duration seconds)',
              'senderId': user?.uid,
              'senderName': senderName,
              'senderRole': 'officer',
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'voice',
              'priority': 'normal',
              'readBy': [user?.uid],
              'replyTo': null,
              'attachments': [
                {
                  'url': audioUrl,
                  'type': 'voice',
                  'name': 'voice_message.webm',
                  'duration': duration,
                }
              ],
              'reactions': {},
              'isEdited': false,
              'isDeleted': false,
            });

            await _firestore.collection('communication_channels').doc(widget.channelId).update({
              'lastMessage': '🎙️ Voice message',
              'lastActivity': FieldValue.serverTimestamp(),
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Voice message sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sending voice message: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing coming soon!')),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => MessageSearchDialog(channelId: widget.channelId),
    );
  }

  void _showQuickReplies() {
    showModalBottomSheet(
      context: context,
      builder: (context) => QuickReplyPicker(
        onReplySelected: (text) {
          _messageController.text = text;
          _sendMessage();
        },
      ),
    );
  }

  void _showChannelInfo() {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('communication_channels').doc(widget.channelId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return AlertDialog(
              title: const Text('Channel Info'),
              content: const Text('Channel not found'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final members = (data['members'] as List?)?.cast<String>() ?? [];
          final admins = (data['admins'] as List?)?.cast<String>() ?? [];
          final isAdmin = admins.contains(_auth.currentUser?.uid);

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text(widget.channelName)),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditChannelDialog(data);
                    },
                  ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel Type
                  Row(
                    children: [
                      Icon(
                        widget.channelType == 'shift' ? Icons.access_time :
                        widget.channelType == 'beat' ? Icons.location_on :
                        widget.channelType == 'department' ? Icons.business :
                        Icons.forum,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.channelType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  if (data['description'] != null && data['description'].toString().isNotEmpty)
                    Text(
                      data['description'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  const SizedBox(height: 16),
                  
                  // Members Section
                  Row(
                    children: [
                      Text(
                        'Members (${members.isEmpty ? "All Officers" : members.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isAdmin)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showManageMembersDialog(widget.channelId, members);
                          },
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Manage'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Member List
                  if (members.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.public, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Open to all officers',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('users').doc(members[index]).get(),
                            builder: (context, userSnapshot) {
                              String userName = 'Loading...';
                              if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                final email = userData['email'];
                                if (email != null && email is String) {
                                  userName = email.split('@')[0];
                                } else {
                                  userName = 'Officer';
                                }
                              }
                              
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  child: Text(userName[0].toUpperCase()),
                                ),
                                title: Text(userName, style: const TextStyle(fontSize: 14)),
                                trailing: admins.contains(members[index])
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ADMIN',
                                          style: TextStyle(fontSize: 10, color: Colors.orange[900]),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManageMembersDialog(String channelId, List<String> currentMembers) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Channel Members'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search officers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Officer list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').where('role', isEqualTo: 'officer').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final officers = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: officers.length,
                        itemBuilder: (context, index) {
                          final officerData = officers[index].data() as Map<String, dynamic>;
                          final officerId = officers[index].id;
                          final officerName = officerData['email']?.split('@')[0] ?? 'Officer';
                          final isMember = currentMembers.contains(officerId);

                          return CheckboxListTile(
                            title: Text(officerName),
                            subtitle: Text(officerData['email'] ?? ''),
                            value: isMember,
                            onChanged: (bool? value) async {
                              if (value == true) {
                                // Add member
                                await _firestore.collection('communication_channels').doc(channelId).update({
                                  'members': FieldValue.arrayUnion([officerId]),
                                });
                              } else {
                                // Remove member
                                await _firestore.collection('communication_channels').doc(channelId).update({
                                  'members': FieldValue.arrayRemove([officerId]),
                                });
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChannelDialog(Map<String, dynamic> channelData) {
    final nameController = TextEditingController(text: channelData['name']);
    final descController = TextEditingController(text: channelData['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              try {
                await _firestore.collection('communication_channels').doc(widget.channelId).update({
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Channel updated!'), backgroundColor: Colors.green),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

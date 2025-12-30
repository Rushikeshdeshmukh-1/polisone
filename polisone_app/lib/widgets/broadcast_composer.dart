import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BroadcastComposerDialog extends StatefulWidget {
  const BroadcastComposerDialog({Key? key}) : super(key: key);

  @override
  State<BroadcastComposerDialog> createState() => _BroadcastComposerDialogState();
}

class _BroadcastComposerDialogState extends State<BroadcastComposerDialog> {
  final _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  String _selectedRecipient = 'all';
  String _selectedPriority = 'normal';
  String? _selectedShift;
  String? _selectedBeat;
  bool _isSending = false;

  final _priorities = {
    'normal': {'label': 'Normal', 'color': Colors.blue, 'icon': Icons.message},
    'important': {'label': 'Important', 'color': Colors.orange, 'icon': Icons.priority_high},
    'urgent': {'label': 'Urgent', 'color': Colors.red, 'icon': Icons.warning},
    'emergency': {'label': 'Emergency', 'color': Colors.red[900]!, 'icon': Icons.emergency},
  };

  final _recipientTypes = {
    'all': 'All Officers',
    'shift': 'Specific Shift',
    'beat': 'Specific Beat',
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = _auth.currentUser;
      
      // Create broadcast record
      final broadcastRef = await _firestore.collection('broadcasts').add({
        'message': _messageController.text.trim(),
        'priority': _selectedPriority,
        'sentBy': user?.uid,
        'senderName': user?.email?.split('@')[0] ?? 'Admin',
        'sentAt': FieldValue.serverTimestamp(),
        'recipients': {
          'type': _selectedRecipient,
          'shift': _selectedShift,
          'beat': _selectedBeat,
        },
        'deliveryStatus': {
          'sent': 0,
          'delivered': 0,
          'read': 0,
        },
      });

      // Get recipients based on selection
      Query recipientsQuery = _firestore.collection('users').where('role', isEqualTo: 'officer');
      
      if (_selectedRecipient == 'shift' && _selectedShift != null) {
        // Get officers on specific shift today
        final today = DateTime.now();
        final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        final shiftsSnapshot = await _firestore
            .collection('shifts')
            .where('date', isEqualTo: dateStr)
            .where('shift', isEqualTo: _selectedShift)
            .get();
        
        final officerIds = shiftsSnapshot.docs.map((doc) => doc.data()['officerId'] as String).toList();
        if (officerIds.isNotEmpty) {
          recipientsQuery = _firestore.collection('users').where(FieldPath.documentId, whereIn: officerIds);
        }
      } else if (_selectedRecipient == 'beat' && _selectedBeat != null) {
        // Get officers assigned to specific beat today
        final today = DateTime.now();
        final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        final shiftsSnapshot = await _firestore
            .collection('shifts')
            .where('date', isEqualTo: dateStr)
            .where('beat', isEqualTo: _selectedBeat)
            .get();
        
        final officerIds = shiftsSnapshot.docs.map((doc) => doc.data()['officerId'] as String).toList();
        if (officerIds.isNotEmpty) {
          recipientsQuery = _firestore.collection('users').where(FieldPath.documentId, whereIn: officerIds);
        }
      }

      final recipientsSnapshot = await recipientsQuery.get();
      
      // Send message to each recipient's inbox
      int sentCount = 0;
      for (var userDoc in recipientsSnapshot.docs) {
        await _firestore.collection('user_messages').add({
          'userId': userDoc.id,
          'broadcastId': broadcastRef.id,
          'message': _messageController.text.trim(),
          'priority': _selectedPriority,
          'senderId': user?.uid,
          'senderName': user?.email?.split('@')[0] ?? 'Admin',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'broadcast',
        });
        sentCount++;
      }

      // Update broadcast delivery status
      await broadcastRef.update({
        'deliveryStatus.sent': sentCount,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Broadcast sent to $sentCount officer(s)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign, color: Color(0xFF1E40AF), size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broadcast Message',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Send message to multiple officers',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recipient Selector
            const Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _recipientTypes.entries.map((entry) {
                final isSelected = _selectedRecipient == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRecipient = entry.key);
                  },
                  selectedColor: Colors.blue[100],
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF1E40AF) : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            // Shift/Beat selector if needed
            if (_selectedRecipient == 'shift') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedShift,
                decoration: const InputDecoration(
                  labelText: 'Select Shift',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: ['Morning', 'Evening', 'Night'].map((shift) {
                  return DropdownMenuItem(value: shift, child: Text(shift));
                }).toList(),
                onChanged: (value) => setState(() => _selectedShift = value),
              ),
            ],
            if (_selectedRecipient == 'beat') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBeat,
                decoration: const InputDecoration(
                  labelText: 'Select Beat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: ['Beat A', 'Beat B', 'Beat C', 'Beat D'].map((beat) {
                  return DropdownMenuItem(value: beat, child: Text(beat));
                }).toList(),
                onChanged: (value) => setState(() => _selectedBeat = value),
              ),
            ],
            const SizedBox(height: 16),

            // Priority Selector
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _priorities.entries.map((entry) {
                final isSelected = _selectedPriority == entry.key;
                final color = entry.value['color'] as Color;
                return ChoiceChip(
                  avatar: Icon(
                    entry.value['icon'] as IconData,
                    size: 18,
                    color: isSelected ? color : Colors.grey,
                  ),
                  label: Text(entry.value['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedPriority = entry.key);
                  },
                  selectedColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Message Input
            const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Type your broadcast message here...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendBroadcast,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'Send Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

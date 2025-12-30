import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessageSearchDialog extends StatefulWidget {
  final String? channelId;

  const MessageSearchDialog({
    Key? key,
    this.channelId,
  }) : super(key: key);

  @override
  State<MessageSearchDialog> createState() => _MessageSearchDialogState();
}

class _MessageSearchDialogState extends State<MessageSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      Query messagesQuery;
      
      if (widget.channelId != null) {
        // Search within specific channel
        messagesQuery = _firestore
            .collection('communication_channels')
            .doc(widget.channelId)
            .collection('messages')
            .where('text', isGreaterThanOrEqualTo: query)
            .where('text', isLessThan: query + 'z')
            .limit(20);
      } else {
        // Search across all channels (collection group)
        messagesQuery = _firestore
            .collectionGroup('messages')
            .where('text', isGreaterThanOrEqualTo: query)
            .where('text', isLessThan: query + 'z')
            .limit(20);
      }

      final snapshot = await messagesQuery.get();
      
      setState(() {
        _searchResults = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF1E40AF), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Search Messages',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type to search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _performSearch(value);
                } else {
                  setState(() => _searchResults = []);
                }
              },
            ),
            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Type to search messages'
                                    : 'No messages found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final message = _searchResults[index];
                            return _buildSearchResult(message);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(Map<String, dynamic> message) {
    final text = message['text'] ?? '';
    final senderName = message['senderName'] ?? 'Unknown';
    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
    final priority = message['priority'] ?? 'normal';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(priority).withOpacity(0.2),
          child: Icon(
            Icons.message,
            color: _getPriorityColor(priority),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                senderName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (timestamp != null)
              Text(
                DateFormat('MMM dd, h:mm a').format(timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        subtitle: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // Could navigate to the message in its channel
          Navigator.pop(context);
        },
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

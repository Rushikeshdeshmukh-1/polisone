import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import '../models/evidence_model.dart';
import '../repositories/evidence_repository.dart';

class EvidenceDetailScreen extends StatefulWidget {
  final String evidenceId;

  const EvidenceDetailScreen({Key? key, required this.evidenceId}) : super(key: key);

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  final EvidenceRepository _repository = EvidenceRepository();
  bool _isLoading = false;

  Future<void> _updateStatus() async {
    final reasonController = TextEditingController();
    final receiverController = TextEditingController();
    String action = 'Check Out';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: action,
                  decoration: const InputDecoration(labelText: 'Action'),
                  items: ['Check Out', 'Check In', 'Dispose'].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => action = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (e.g. Court, Lab)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (action == 'Check Out') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: receiverController,
                    decoration: const InputDecoration(
                      labelText: 'Receiver ID / Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              Navigator.pop(context);
              
              setState(() => _isLoading = true);
              
              try {
                String newStatus = action == 'Check Out' ? 'Checked Out' 
                    : action == 'Check In' ? 'In Custody' 
                    : 'Disposed';

                final log = CustodyLog(
                  action: action,
                  officerId: 'current_user_id', // TODO: Get from Auth
                  officerName: 'Current Officer', // TODO: Get from Auth
                  reason: reasonController.text,
                  receiverId: action == 'Check Out' ? receiverController.text : null,
                  timestamp: DateTime.now(),
                );

                await _repository.updateCustodyStatus(
                  evidenceId: widget.evidenceId,
                  newStatus: newStatus,
                  logEntry: log,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Details')),
      body: StreamBuilder<List<EvidenceModel>>(
        stream: _repository.streamEvidence(), // Less efficient but works for now as getById isn't stream
        // Ideally should have a document stream in repo
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          try {
            final evidence = snapshot.data!.firstWhere((e) => e.id == widget.evidenceId);
            return _buildContent(evidence);
          } catch (e) {
            return const Center(child: Text('Evidence not found'));
          }
        },
      ),
    );
  }

  Widget _buildContent(EvidenceModel item) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Image & QR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: item.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.imageUrl.isEmpty 
                        ? const Icon(Icons.image, size: 48, color: Colors.grey) 
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                // QR Code
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      QrImageView(
                        data: item.id,
                        version: QrVersions.auto,
                        size: 120.0,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.id,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Basic Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('FIR Number', item.firNumber),
                _buildInfoRow('Category', item.category),
                _buildInfoRow('Current Status', item.status),
                _buildInfoRow('Location', item.currentLocation ?? 'Unknown'),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(item.description),
              ],
            ),
          ),

          const Divider(thickness: 1),

          // Chain of Custody Timeline
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chain of Custody',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: item.chainOfCustody.length,
                  itemBuilder: (context, index) {
                    final log = item.chainOfCustody[item.chainOfCustody.length - 1 - index]; // Reverse order
                    return _buildTimelineTile(log, index == item.chainOfCustody.length - 1);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(CustodyLog log, bool isLast) {
    return TimelineTile(
      isFirst: false, // In reversed list, first item is actually the verified latest
      isLast: isLast,
      beforeLineStyle: const LineStyle(color: Color(0xFF1E40AF), thickness: 2),
      indicatorStyle: IndicatorStyle(
        width: 12,
        color: const Color(0xFF1E40AF),
        padding: const EdgeInsets.all(6),
      ),
      endChild: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(log.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('By: ${log.officerName} (ID: ${log.officerId})'),
            if (log.receiverId != null)
              Text('Receiver: ${log.receiverId}', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              'Reason: ${log.reason}',
              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

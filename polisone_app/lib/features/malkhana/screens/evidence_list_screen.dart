import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evidence_model.dart';
import '../repositories/evidence_repository.dart';
import 'add_evidence_screen.dart';
import 'evidence_detail_screen.dart';

class EvidenceListScreen extends StatefulWidget {
  const EvidenceListScreen({Key? key}) : super(key: key);

  @override
  State<EvidenceListScreen> createState() => _EvidenceListScreenState();
}

class _EvidenceListScreenState extends State<EvidenceListScreen> {
  final EvidenceRepository _repository = EvidenceRepository();
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Malkhana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Implement scanner navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FIR, Item Name, or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('In Custody'),
                _buildFilterChip('Checked Out'),
                _buildFilterChip('Disposed'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: StreamBuilder<List<EvidenceModel>>(
              stream: _repository.streamEvidence(
                status: _selectedFilter == 'All' ? null : _selectedFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allEvidence = snapshot.data ?? [];
                
                // Client-side search filtering
                final evidence = allEvidence.where((item) {
                  final matchesSearch = 
                      item.firNumber.toLowerCase().contains(_searchQuery) ||
                      item.itemName.toLowerCase().contains(_searchQuery) ||
                      item.id.toLowerCase().contains(_searchQuery);
                  return matchesSearch;
                }).toList();

                if (evidence.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No evidence found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: evidence.length,
                  itemBuilder: (context, index) {
                    final item = evidence[index];
                    return _buildEvidenceCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEvidenceScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Seizure'),
        backgroundColor: const Color(0xFF1E40AF),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = label);
          }
        },
        selectedColor: const Color(0xFF1E40AF).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1E40AF) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel item) {
    Color statusColor;
    switch (item.status) {
      case 'In Custody':
        statusColor = Colors.green;
        break;
      case 'Checked Out':
        statusColor = Colors.orange;
        break;
      case 'Disposed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvidenceDetailScreen(evidenceId: item.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or Placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl.isEmpty
                    ? Icon(Icons.image_not_supported, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FIR: ${item.firNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(item.seizureDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

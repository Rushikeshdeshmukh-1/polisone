import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerMapWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  
  const OfficerMapWidget({Key? key, required this.firestore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Map background with Mumbai location
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/72.8777,19.0760,11,0/800x400@2x?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Officer markers from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('officers').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No officers to display',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add officers in Firebase to see them on the map',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: snapshot.data!.docs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final status = data['status'] ?? 'off_duty';
                  
                  // Use demo positions (in production, use actual lat/lng)
                  final left = 50.0 + (index * 100) % 650;
                  final top = 50.0 + (index * 70) % 280;

                  return Positioned(
                    left: left,
                    top: top,
                    child: _buildOfficerMarker(name, status),
                  );
                }).toList(),
              );
            },
          ),
          // Map title overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: Color(0xFF1E40AF)),
                  SizedBox(width: 4),
                  Text(
                    'Mumbai, India',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Map legend
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.green, 'On Patrol'),
                  _buildLegendItem(Colors.orange, 'Responding'),
                  _buildLegendItem(Colors.grey, 'Off Duty'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerMarker(String name, String status) {
    Color markerColor;
    switch (status) {
      case 'on_patrol':
        markerColor = Colors.green;
        break;
      case 'responding':
        markerColor = Colors.orange;
        break;
      default:
        markerColor = Colors.grey;
    }

    return Tooltip(
      message: name,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

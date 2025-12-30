import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String uid;
  final double lat;
  final double lng;
  final double? heading;
  final DateTime lastUpdated;
  final String status; // 'patrol', 'sos', 'on_duty', 'off_duty'
  
  LocationModel({
    required this.uid,
    required this.lat,
    required this.lng,
    this.heading,
    required this.lastUpdated,
    required this.status,
  });
  
  // Convert from Firestore document
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      uid: doc.id,
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      heading: data['heading']?.toDouble(),
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
      status: data['status'] ?? 'off_duty',
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'status': status,
    };
  }
  
  // Check if location is recent (within last 5 minutes)
  bool get isRecent {
    return DateTime.now().difference(lastUpdated).inMinutes < 5;
  }
  
  // Check if SOS status
  bool get isSOS => status == 'sos';
}

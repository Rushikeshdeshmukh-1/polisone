import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String type; // 'Theft', 'Assault', 'Traffic', etc.
  final String description;
  final String status; // 'Draft', 'Pending', 'Approved', 'Filed'
  final String createdBy; // Officer UID
  final DateTime createdAt;
  final String? audioUrl;
  final String? pdfUrl;
  final double? lat;
  final double? lng;
  final String? location;
  
  IncidentModel({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.audioUrl,
    this.pdfUrl,
    this.lat,
    this.lng,
    this.location,
  });
  
  // Convert from Firestore document
  factory IncidentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncidentModel(
      id: doc.id,
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Draft',
      createdBy: data['created_by'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      audioUrl: data['audio_url'],
      pdfUrl: data['pdf_url'],
      lat: data['lat']?.toDouble(),
      lng: data['lng']?.toDouble(),
      location: data['location'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'description': description,
      'status': status,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'audio_url': audioUrl,
      'pdf_url': pdfUrl,
      'lat': lat,
      'lng': lng,
      'location': location,
    };
  }
  
  IncidentModel copyWith({
    String? id,
    String? type,
    String? description,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? audioUrl,
    String? pdfUrl,
    double? lat,
    double? lng,
    String? location,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      audioUrl: audioUrl ?? this.audioUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      location: location ?? this.location,
    );
  }
}

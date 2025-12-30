import 'package:cloud_firestore/cloud_firestore.dart';

class RosterModel {
  final String id;
  final String officerId;
  final String officerName;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final String beatArea;
  final String? notes;
  
  RosterModel({
    required this.id,
    required this.officerId,
    required this.officerName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.beatArea,
    this.notes,
  });
  
  // Convert from Firestore document
  factory RosterModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RosterModel(
      id: doc.id,
      officerId: data['officer_id'] ?? '',
      officerName: data['officer_name'] ?? '',
      shiftStart: (data['shift_start'] as Timestamp).toDate(),
      shiftEnd: (data['shift_end'] as Timestamp).toDate(),
      beatArea: data['beat_area'] ?? '',
      notes: data['notes'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'officer_id': officerId,
      'officer_name': officerName,
      'shift_start': Timestamp.fromDate(shiftStart),
      'shift_end': Timestamp.fromDate(shiftEnd),
      'beat_area': beatArea,
      'notes': notes,
    };
  }
  
  // Get shift duration in hours
  double get shiftDurationHours {
    return shiftEnd.difference(shiftStart).inHours.toDouble();
  }
  
  // Check if shift is active now
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(shiftStart) && now.isBefore(shiftEnd);
  }
  
  // Check if shift is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(shiftStart);
  }
  
  // Check if shift is completed
  bool get isCompleted {
    return DateTime.now().isAfter(shiftEnd);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role; // 'admin' or 'officer'
  final String name;
  final String stationId;
  final String status; // 'on_duty', 'off_duty', 'sos', 'patrol'
  final String? fcmToken;
  final String? email;
  
  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.stationId,
    required this.status,
    this.fcmToken,
    this.email,
  });
  
  // Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      role: data['role'] ?? 'officer',
      name: data['name'] ?? '',
      stationId: data['station_id'] ?? '',
      status: data['status'] ?? 'off_duty',
      fcmToken: data['fcm_token'],
      email: data['email'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'role': role,
      'name': name,
      'station_id': stationId,
      'status': status,
      'fcm_token': fcmToken,
      'email': email,
    };
  }
  
  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? role,
    String? name,
    String? stationId,
    String? status,
    String? fcmToken,
    String? email,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      stationId: stationId ?? this.stationId,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      email: email ?? this.email,
    );
  }
  
  bool get isAdmin => role == 'admin';
  bool get isOfficer => role == 'officer';
  bool get isOnDuty => status == 'on_duty' || status == 'patrol';
  bool get isSOS => status == 'sos';
}

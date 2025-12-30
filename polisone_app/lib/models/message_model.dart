import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String type; // 'broadcast' or 'direct'
  final String senderId;
  final String? receiverId; // null for broadcast, specific UID for direct
  final String message;
  final DateTime timestamp;
  final bool? read;
  
  MessageModel({
    required this.id,
    required this.type,
    required this.senderId,
    this.receiverId,
    required this.message,
    required this.timestamp,
    this.read,
  });
  
  // Convert from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      type: data['type'] ?? 'direct',
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'],
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read ?? false,
    };
  }
  
  bool get isBroadcast => type == 'broadcast';
}

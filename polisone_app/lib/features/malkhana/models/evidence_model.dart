import 'package:cloud_firestore/cloud_firestore.dart';

class EvidenceModel {
  final String id;
  final String firNumber;
  final String itemName;
  final String category;
  final String description;
  final String status; // 'In Custody', 'Checked Out', 'Disposed'
  final String imageUrl;
  final DateTime seizureDate;
  final String seizedByOfficerId;
  final String seizedByOfficerName;
  final List<CustodyLog> chainOfCustody;
  final String? currentLocation; // e.g., 'Shelf A-4' or 'Forensic Lab'

  EvidenceModel({
    required this.id,
    required this.firNumber,
    required this.itemName,
    required this.category,
    required this.description,
    required this.status,
    required this.imageUrl,
    required this.seizureDate,
    required this.seizedByOfficerId,
    required this.seizedByOfficerName,
    required this.chainOfCustody,
    this.currentLocation,
  });

  factory EvidenceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EvidenceModel(
      id: doc.id,
      firNumber: data['firNumber'] ?? '',
      itemName: data['itemName'] ?? '',
      category: data['category'] ?? 'Other',
      description: data['description'] ?? '',
      status: data['status'] ?? 'In Custody',
      imageUrl: data['imageUrl'] ?? '',
      seizureDate: (data['seizureDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seizedByOfficerId: data['seizedByOfficerId'] ?? '',
      seizedByOfficerName: data['seizedByOfficerName'] ?? '',
      chainOfCustody: (data['chainOfCustody'] as List<dynamic>?)
              ?.map((e) => CustodyLog.fromMap(e))
              .toList() ??
          [],
      currentLocation: data['currentLocation'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firNumber': firNumber,
      'itemName': itemName,
      'category': category,
      'description': description,
      'status': status,
      'imageUrl': imageUrl,
      'seizureDate': Timestamp.fromDate(seizureDate),
      'seizedByOfficerId': seizedByOfficerId,
      'seizedByOfficerName': seizedByOfficerName,
      'chainOfCustody': chainOfCustody.map((e) => e.toMap()).toList(),
      'currentLocation': currentLocation,
    };
  }
}

class CustodyLog {
  final String action; // 'Seized', 'Checked Out', 'Returned', 'Disposed'
  final String officerId;
  final String officerName;
  final String? receiverId; // Who took it (if checked out)
  final String reason;
  final DateTime timestamp;

  CustodyLog({
    required this.action,
    required this.officerId,
    required this.officerName,
    this.receiverId,
    required this.reason,
    required this.timestamp,
  });

  factory CustodyLog.fromMap(Map<String, dynamic> map) {
    return CustodyLog(
      action: map['action'] ?? '',
      officerId: map['officerId'] ?? '',
      officerName: map['officerName'] ?? '',
      receiverId: map['receiverId'],
      reason: map['reason'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'officerId': officerId,
      'officerName': officerName,
      'receiverId': receiverId,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

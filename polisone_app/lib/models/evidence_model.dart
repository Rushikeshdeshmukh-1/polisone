import 'package:cloud_firestore/cloud_firestore.dart';

class CustodyLog {
  final String handler; // Officer UID or name
  final DateTime time;
  final String action; // 'Check-in', 'Check-out', 'Transfer'
  
  CustodyLog({
    required this.handler,
    required this.time,
    required this.action,
  });
  
  factory CustodyLog.fromMap(Map<String, dynamic> map) {
    return CustodyLog(
      handler: map['handler'] ?? '',
      time: (map['time'] as Timestamp).toDate(),
      action: map['action'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'handler': handler,
      'time': Timestamp.fromDate(time),
      'action': action,
    };
  }
}

class EvidenceModel {
  final String id;
  final String qrCode;
  final String itemName;
  final String currentCustody; // Current handler UID
  final List<CustodyLog> custodyLog;
  final String? description;
  final String? caseId;
  final String? photoUrl;
  final DateTime createdAt;
  
  EvidenceModel({
    required this.id,
    required this.qrCode,
    required this.itemName,
    required this.currentCustody,
    required this.custodyLog,
    this.description,
    this.caseId,
    this.photoUrl,
    required this.createdAt,
  });
  
  // Convert from Firestore document
  factory EvidenceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<CustodyLog> logs = [];
    if (data['custody_log'] != null) {
      logs = (data['custody_log'] as List)
          .map((log) => CustodyLog.fromMap(log as Map<String, dynamic>))
          .toList();
    }
    
    return EvidenceModel(
      id: doc.id,
      qrCode: data['qr_code'] ?? '',
      itemName: data['item_name'] ?? '',
      currentCustody: data['current_custody'] ?? '',
      custodyLog: logs,
      description: data['description'],
      caseId: data['case_id'],
      photoUrl: data['photo_url'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'qr_code': qrCode,
      'item_name': itemName,
      'current_custody': currentCustody,
      'custody_log': custodyLog.map((log) => log.toMap()).toList(),
      'description': description,
      'case_id': caseId,
      'photo_url': photoUrl,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
  
  EvidenceModel copyWith({
    String? id,
    String? qrCode,
    String? itemName,
    String? currentCustody,
    List<CustodyLog>? custodyLog,
    String? description,
    String? caseId,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return EvidenceModel(
      id: id ?? this.id,
      qrCode: qrCode ?? this.qrCode,
      itemName: itemName ?? this.itemName,
      currentCustody: currentCustody ?? this.currentCustody,
      custodyLog: custodyLog ?? this.custodyLog,
      description: description ?? this.description,
      caseId: caseId ?? this.caseId,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

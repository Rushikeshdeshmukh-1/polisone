import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evidence_model.dart';

class EvidenceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _collection = FirebaseFirestore.instance.collection('evidence');

  // Stream all evidence (with minimal filtering initially)
  Stream<List<EvidenceModel>> streamEvidence({String? status}) {
    Query query = _collection.orderBy('seizureDate', descending: true);
    
    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EvidenceModel.fromFirestore(doc)).toList();
    });
  }

  // Get single evidence by ID
  Future<EvidenceModel?> getEvidenceById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return EvidenceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting evidence: $e');
      return null;
    }
  }

  // Add new evidence (seizure)
  Future<String> addEvidence(EvidenceModel evidence) async {
    try {
      final docRef = await _collection.add(evidence.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding evidence: $e');
      rethrow;
    }
  }

  // Update status / Check-in / Check-out / Dispose
  // This pushes a new entry to 'chainOfCustody' array
  Future<void> updateCustodyStatus({
    required String evidenceId,
    required String newStatus,
    required CustodyLog logEntry,
  }) async {
    try {
      await _collection.doc(evidenceId).update({
        'status': newStatus,
        'chainOfCustody': FieldValue.arrayUnion([logEntry.toMap()]),
        'currentLocation': logEntry.action == 'Checked Out' ? 'With ${logEntry.receiverId}' : 'Malkhana',
      });
    } catch (e) {
      print('Error updating custody: $e');
      rethrow;
    }
  }
}

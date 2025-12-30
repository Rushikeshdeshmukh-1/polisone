import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/location_model.dart';
import '../../models/incident_model.dart';
import '../../models/evidence_model.dart';
import '../../models/message_model.dart';
import '../../models/roster_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ========== USERS ==========
  
  Stream<List<UserModel>> streamUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }
  
  Stream<List<UserModel>> streamOfficers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'officer')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }
  
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }
  
  // ========== LOCATIONS ==========
  
  Stream<List<LocationModel>> streamLocations() {
    return _firestore
        .collection('live_locations')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromFirestore(doc))
            .toList());
  }
  
  Stream<LocationModel?> streamUserLocation(String uid) {
    return _firestore
        .collection('live_locations')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? LocationModel.fromFirestore(doc) : null);
  }
  
  Future<void> updateLocation(String uid, double lat, double lng, String status) async {
    try {
      await _firestore.collection('live_locations').doc(uid).set({
        'lat': lat,
        'lng': lng,
        'last_updated': FieldValue.serverTimestamp(),
        'status': status,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Update location error: $e');
    }
  }
  
  // ========== INCIDENTS/FIRs ==========
  
  Stream<List<IncidentModel>> streamIncidents() {
    return _firestore
        .collection('firs')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentModel.fromFirestore(doc))
            .toList());
  }
  
  Stream<List<IncidentModel>> streamPendingIncidents() {
    return _firestore
        .collection('firs')
        .where('status', isEqualTo: 'Pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentModel.fromFirestore(doc))
            .toList());
  }
  
  Future<String> createIncident(IncidentModel incident) async {
    try {
      DocumentReference ref = await _firestore
          .collection('firs')
          .add(incident.toFirestore());
      return ref.id;
    } catch (e) {
      print('Create incident error: $e');
      rethrow;
    }
  }
  
  Future<void> updateIncident(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('firs').doc(id).update(data);
    } catch (e) {
      print('Update incident error: $e');
      rethrow;
    }
  }
  
  Future<void> deleteIncident(String id) async {
    try {
      await _firestore.collection('firs').doc(id).delete();
    } catch (e) {
      print('Delete incident error: $e');
      rethrow;
    }
  }
  
  // ========== EVIDENCE ==========
  
  Stream<List<EvidenceModel>> streamEvidence() {
    return _firestore
        .collection('evidence')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EvidenceModel.fromFirestore(doc))
            .toList());
  }
  
  Future<String> createEvidence(EvidenceModel evidence) async {
    try {
      DocumentReference ref = await _firestore
          .collection('evidence')
          .add(evidence.toFirestore());
      return ref.id;
    } catch (e) {
      print('Create evidence error: $e');
      rethrow;
    }
  }
  
  Future<void> updateEvidence(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('evidence').doc(id).update(data);
    } catch (e) {
      print('Update evidence error: $e');
      rethrow;
    }
  }
  
  Future<void> deleteEvidence(String id) async {
    try {
      await _firestore.collection('evidence').doc(id).delete();
    } catch (e) {
      print('Delete evidence error: $e');
      rethrow;
    }
  }
  
  // ========== COMMUNICATIONS ==========
  
  Stream<List<MessageModel>> streamMessages({String? receiverId}) {
    Query query = _firestore.collection('communications');
    
    if (receiverId != null) {
      query = query.where('receiver_id', whereIn: [receiverId, null]);
    }
    
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }
  
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore.collection('communications').add(message.toFirestore());
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }
  
  // ========== ROSTERS ==========
  
  Stream<List<RosterModel>> streamRosters() {
    return _firestore
        .collection('rosters')
        .orderBy('shift_start', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RosterModel.fromFirestore(doc))
            .toList());
  }
  
  Stream<List<RosterModel>> streamOfficerRosters(String officerId) {
    return _firestore
        .collection('rosters')
        .where('officer_id', isEqualTo: officerId)
        .orderBy('shift_start', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RosterModel.fromFirestore(doc))
            .toList());
  }
  
  Future<String> createRoster(RosterModel roster) async {
    try {
      DocumentReference ref = await _firestore
          .collection('rosters')
          .add(roster.toFirestore());
      return ref.id;
    } catch (e) {
      print('Create roster error: $e');
      rethrow;
    }
  }
  
  Future<void> updateRoster(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('rosters').doc(id).update(data);
    } catch (e) {
      print('Update roster error: $e');
      rethrow;
    }
  }
  
  Future<void> deleteRoster(String id) async {
    try {
      await _firestore.collection('rosters').doc(id).delete();
    } catch (e) {
      print('Delete roster error: $e');
      rethrow;
    }
  }
  
  // ========== ANALYTICS ==========
  
  Future<Map<String, int>> getIncidentsByType() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('firs').get();
      Map<String, int> counts = {};
      
      for (var doc in snapshot.docs) {
        String type = (doc.data() as Map<String, dynamic>)['type'] ?? 'Unknown';
        counts[type] = (counts[type] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      print('Get incidents by type error: $e');
      return {};
    }
  }
}

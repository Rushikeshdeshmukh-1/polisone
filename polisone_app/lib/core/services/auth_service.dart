import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();
        
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        }
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
  
  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>)['role'];
      }
      return null;
    } catch (e) {
      print('Get user role error: $e');
      return null;
    }
  }
  
  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
  
  // Update user status
  Future<void> updateUserStatus(String uid, String status) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'status': status});
    } catch (e) {
      print('Update user status error: $e');
      rethrow;
    }
  }
  
  // Update FCM token
  Future<void> updateFCMToken(String uid, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'fcm_token': token});
    } catch (e) {
      print('Update FCM token error: $e');
    }
  }
}

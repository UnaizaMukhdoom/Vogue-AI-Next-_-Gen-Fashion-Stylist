// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for admin operations on Firebase
class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final adminDoc = await _db.collection('admins').doc(user.uid).get();
    return adminDoc.exists && adminDoc.data()?['role'] == 'admin';
  }

  /// Get all users with pagination
  static Stream<QuerySnapshot> getAllUsers({int limit = 50}) {
    return _db.collection('users').limit(limit).snapshots();
  }

  /// Get user details
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      
      // Get onboarding data
      final onboardingQuery = await _db
          .collection('users')
          .doc(uid)
          .collection('onboarding')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // Get analysis data
      final analysisDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('analysis')
          .doc('latest')
          .get();

      return {
        'uid': uid,
        'email': data['email'] ?? 'N/A',
        'createdAt': data['createdAt'],
        'onboarding': onboardingQuery.docs.isNotEmpty 
            ? onboardingQuery.docs.first.data() 
            : null,
        'analysis': analysisDoc.exists ? analysisDoc.data() : null,
      };
    } catch (e) {
      return null;
    }
  }

  /// Block/unblock a user
  static Future<void> toggleUserBlock(String uid, bool isBlocked) async {
    await _db.collection('users').doc(uid).update({
      'blocked': isBlocked,
      'blockedAt': isBlocked ? FieldValue.serverTimestamp() : null,
    });
  }

  /// Get total user count
  static Future<int> getUserCount() async {
    final snapshot = await _db.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  /// Get analytics data
  static Future<Map<String, dynamic>> getAnalytics() async {
    final usersSnapshot = await _db.collection('users').get();
    final totalUsers = usersSnapshot.size;

    // Count users with onboarding
    int usersWithOnboarding = 0;
    int usersWithAnalysis = 0;
    
    for (var doc in usersSnapshot.docs) {
      final onboardingQuery = await _db
          .collection('users')
          .doc(doc.id)
          .collection('onboarding')
          .limit(1)
          .get();
      if (onboardingQuery.docs.isNotEmpty) usersWithOnboarding++;

      final analysisDoc = await _db
          .collection('users')
          .doc(doc.id)
          .collection('analysis')
          .doc('latest')
          .get();
      if (analysisDoc.exists) usersWithAnalysis++;
    }

    return {
      'totalUsers': totalUsers,
      'usersWithOnboarding': usersWithOnboarding,
      'usersWithAnalysis': usersWithAnalysis,
      'completionRate': totalUsers > 0 
          ? ((usersWithOnboarding / totalUsers) * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Get clothing items from admin-managed collection
  static Stream<QuerySnapshot> getClothingItems() {
    return _db.collection('clothing_items').orderBy('createdAt', descending: true).snapshots();
  }

  /// Add clothing item
  static Future<void> addClothingItem(Map<String, dynamic> item) async {
    await _db.collection('clothing_items').add({
      ...item,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update clothing item
  static Future<void> updateClothingItem(String itemId, Map<String, dynamic> updates) async {
    await _db.collection('clothing_items').doc(itemId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete clothing item
  static Future<void> deleteClothingItem(String itemId) async {
    await _db.collection('clothing_items').doc(itemId).delete();
  }

  /// Get questionnaire config
  static Future<DocumentSnapshot> getQuestionnaireConfig() async {
    return await _db.collection('config').doc('questionnaire_v1').get();
  }

  /// Update questionnaire config
  static Future<void> updateQuestionnaireConfig(Map<String, dynamic> config) async {
    await _db.collection('config').doc('questionnaire_v1').set({
      ...config,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}


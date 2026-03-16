import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email & password
  Future<String?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'username': username,
        'email': email,
        'wins': 0,
        'losses': 0,
        'totalGames': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Get username
  Future<String> getUsername() async {
    if (currentUser == null) return 'Unknown';
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    return (doc.data() as Map<String, dynamic>?)?['username'] ?? 'Unknown';
  }

  // Update win/loss stats
  Future<void> updateStats({required bool won}) async {
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'wins': FieldValue.increment(won ? 1 : 0),
      'losses': FieldValue.increment(won ? 0 : 1),
      'totalGames': FieldValue.increment(1),
    });
  }
}

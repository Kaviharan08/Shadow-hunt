import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  Future<String?> register(String email, String password, String username) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'username': username, 'email': email,
        'wins': 0, 'losses': 0, 'gamesPlayed': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<void> logout() async { await _auth.signOut(); notifyListeners(); }

  Future<String> getUsername() async {
    if (uid.isEmpty) return 'Guest';
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return (doc.data())?['username'] ?? 'Player';
    } catch (_) { return 'Player'; }
  }

  Future<void> updateStats({required bool won}) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).update({
        'gamesPlayed': FieldValue.increment(1),
        'wins': FieldValue.increment(won ? 1 : 0),
        'losses': FieldValue.increment(won ? 0 : 1),
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final snap = await _db.collection('users')
          .orderBy('wins', descending: true).limit(20).get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) { return []; }
  }
}

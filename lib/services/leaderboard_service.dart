import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get top 20 players sorted by wins
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _firestore
        .collection('users')
        .orderBy('wins', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get a single user's stats
  Future<Map<String, dynamic>?> getUserStats(String uid) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }
}

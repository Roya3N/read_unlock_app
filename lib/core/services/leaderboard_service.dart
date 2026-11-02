import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

/// Public leaderboard entries live in `leaderboard/{childId}` with only a
/// first name, avatar and XP. Other families can no longer read the full
/// child profiles (see firestore.rules).
class LeaderboardService {
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('leaderboard');

  static Query<Map<String, dynamic>> topQuery({int limit = 50}) =>
      _col.orderBy('xp', descending: true).limit(limit);

  /// Short public name: first word only, at most 20 characters.
  static String publicName(String? fullName) {
    final first = (fullName ?? '').trim().split(RegExp(r'\s+')).first;
    if (first.isEmpty) return 'Hero';
    return first.length > 20 ? first.substring(0, 20) : first;
  }

  /// Copies the active child's current XP to their public entry.
  static Future<void> syncActiveChild() async {
    final user = FirebaseAuth.instance.currentUser;
    final childRef = AppState.currentChildRef;
    if (user == null || childRef == null) return;

    try {
      final snap = await childRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;

      final xp = data['xp'];
      await _col.doc(snap.id).set({
        'parentId': user.uid,
        'name': publicName(data['name']?.toString()),
        'avatar': (data['avatar'] ?? '').toString(),
        'xp': xp is int ? xp : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Leaderboard sync error: $e");
    }
  }

  static Future<void> removeChild(String childId) async {
    try {
      await _col.doc(childId).delete();
    } catch (e) {
      debugPrint("Leaderboard remove error: $e");
    }
  }
}

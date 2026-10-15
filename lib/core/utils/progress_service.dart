import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class ProgressService {
  static Future<void> logActivity({
    required int xpEarned,
    required int playedMinutes,
    String activityName = 'general',
    int? achievedCombo, // 🌟 اضافه شدن متغیر رکوردِ کمبو
  }) async {
    if (xpEarned <= 0 &&
        playedMinutes <= 0 &&
        (achievedCombo == null || achievedCombo == 0))
      return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && AppState.activeChildId.isNotEmpty) {
        final childDocRef = FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .collection('children')
            .doc(AppState.activeChildId);

        // ۱. اضافه کردن XP کل
        if (xpEarned > 0) {
          await childDocRef.update({'xp': FieldValue.increment(xpEarned)});
        }

        // ۲. اضافه کردن زمان بازی + ریزِ فعالیت‌ها (Breakdown)
        if (playedMinutes > 0) {
          String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          await childDocRef.collection('daily_activity').doc(today).set({
            'date': today,
            'minutes': FieldValue.increment(playedMinutes),
            'breakdown': {activityName: FieldValue.increment(playedMinutes)},
          }, SetOptions(merge: true));
        }

        // 🌟 ۳. ذخیره بهترین رکورد (Personal Best)
        if (achievedCombo != null && achievedCombo > 0) {
          // اول دیتای قبلی بچه رو می‌خونیم
          final docSnap = await childDocRef.get();
          final data = docSnap.data() as Map<String, dynamic>?;

          // چک می‌کنیم رکورد قبلیش تو این بازی چند بوده (اگر نداشته، همون ۰ در نظر می‌گیریم)
          int currentBest = 0;
          if (data != null &&
              data.containsKey('records') &&
              data['records'][activityName] != null) {
            currentBest = data['records'][activityName]['maxCombo'] ?? 0;
          }

          // اگر رکورد جدیدش از رکورد قبلی بهتر بود، تو دیتابیس ثبتش می‌کنیم! 🏆
          if (achievedCombo > currentBest) {
            await childDocRef.set({
              'records': {
                activityName: {'maxCombo': achievedCombo},
              },
            }, SetOptions(merge: true));
            debugPrint("🎉 New Personal Best! $activityName: $achievedCombo");
          }
        }

        debugPrint(
          "✅ Progress Logged: +$xpEarned XP, +$playedMinutes Mins in [$activityName]",
        );
      }
    } catch (e) {
      debugPrint("❌ Error logging progress: $e");
    }
  }
}

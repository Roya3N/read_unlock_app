import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class ScreenTimeToday {
  final int dailyLimit;
  final int usedToday;
  const ScreenTimeToday({required this.dailyLimit, required this.usedToday});
}

/// Records recreational minutes used per day in
/// `daily_activity/{yyyy-MM-dd}.screenMinutes` and reads the parent's
/// `dailyLimitMinutes` from the child doc. Learning minutes stay in
/// `minutes`, so the two are never mixed.
class ScreenTimeService {
  static String todayKey([DateTime? now]) =>
      DateFormat('yyyy-MM-dd').format(now ?? DateTime.now());

  static DocumentReference? _todayRef() =>
      AppState.currentChildRef?.collection('daily_activity').doc(todayKey());

  static Future<ScreenTimeToday> loadToday() async {
    final childRef = AppState.currentChildRef;
    if (childRef == null) {
      return const ScreenTimeToday(dailyLimit: 0, usedToday: 0);
    }
    try {
      final results = await Future.wait([childRef.get(), _todayRef()!.get()]);
      final child = results[0].data() as Map<String, dynamic>?;
      final today = results[1].data() as Map<String, dynamic>?;
      final limit = child?['dailyLimitMinutes'];
      final used = today?['screenMinutes'];
      return ScreenTimeToday(
        dailyLimit: limit is int ? limit : 0,
        usedToday: used is int ? used : 0,
      );
    } catch (e) {
      debugPrint("Screen time load error: $e");
      return const ScreenTimeToday(dailyLimit: 0, usedToday: 0);
    }
  }

  /// [minutes] may be negative for a refund.
  static Future<void> recordUsed(int minutes) async {
    final ref = _todayRef();
    if (ref == null || minutes == 0) return;
    try {
      await ref.set({
        'date': todayKey(),
        'screenMinutes': FieldValue.increment(minutes),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Screen time record error: $e");
    }
  }

  static Future<void> setDailyLimit(
    DocumentReference childRef,
    int minutes,
  ) async {
    await childRef.update({'dailyLimitMinutes': minutes});
  }
}

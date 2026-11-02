import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:read_unlock_app/core/backend/backend.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class ScreenTimeToday {
  final int dailyLimit;
  final int usedToday;
  const ScreenTimeToday({required this.dailyLimit, required this.usedToday});
}

/// Result of asking the server to start a screen-time session.
class ScreenSessionStart {
  final bool ok;
  final String? sessionId;
  final DateTime? endsAt;

  /// 'not_enough_minutes', 'daily_limit', 'session_running' or 'error'.
  final String? reason;
  final int? leftToday;

  const ScreenSessionStart({
    required this.ok,
    this.sessionId,
    this.endsAt,
    this.reason,
    this.leftToday,
  });
}

/// Screen time is counted by the server: starting a session takes the
/// minutes after checking the balance and the parent's daily limit, and
/// ending early refunds the unused whole minutes by the server clock.
/// Learning minutes are stored separately and never mixed in.
class ScreenTimeService {
  static String todayKey([DateTime? now]) =>
      DateFormat('yyyy-MM-dd').format(now ?? DateTime.now());

  static Future<ScreenTimeToday> loadToday() async {
    final childId = AppState.activeChildId;
    if (childId.isEmpty || !Backend.isSignedIn) {
      return const ScreenTimeToday(dailyLimit: 0, usedToday: 0);
    }
    try {
      final child = await Children.get(childId);
      final days = await Children.dailyActivity(childId, days: 1);
      final today = days.where((d) => d['day'] == todayKey()).toList();
      final used = today.isEmpty ? 0 : today.first['screen_minutes'];
      return ScreenTimeToday(
        dailyLimit: child?['dailyLimitMinutes'] as int? ?? 0,
        usedToday: used is int ? used : 0,
      );
    } catch (e) {
      debugPrint("Screen time load error: $e");
      return const ScreenTimeToday(dailyLimit: 0, usedToday: 0);
    }
  }

  static Future<ScreenSessionStart> start(int minutes) async {
    final childId = AppState.activeChildId;
    if (childId.isEmpty || !Backend.isSignedIn) {
      return const ScreenSessionStart(ok: false, reason: 'error');
    }
    try {
      final r = await Rewards.startScreenSession(childId, minutes);
      await AppState.refreshActiveChild();
      if (r['ok'] == true) {
        return ScreenSessionStart(
          ok: true,
          sessionId: r['session_id']?.toString(),
          endsAt: DateTime.tryParse(r['ends_at']?.toString() ?? '')?.toLocal(),
        );
      }
      return ScreenSessionStart(
        ok: false,
        reason: r['reason']?.toString() ?? 'error',
        leftToday: r['left_today'] as int?,
      );
    } catch (e) {
      debugPrint("Start session error: $e");
      return const ScreenSessionStart(ok: false, reason: 'error');
    }
  }

  /// Ends a session early. Returns the minutes given back.
  static Future<int> end(String sessionId) async {
    try {
      final r = await Rewards.endScreenSession(sessionId);
      await AppState.refreshActiveChild();
      final refunded = r['refunded'];
      return refunded is int ? refunded : 0;
    } catch (e) {
      debugPrint("End session error: $e");
      return 0;
    }
  }

  static Future<void> setDailyLimit(String childId, int minutes) async {
    await Children.updateProfile(childId, dailyLimitMinutes: minutes);
  }
}

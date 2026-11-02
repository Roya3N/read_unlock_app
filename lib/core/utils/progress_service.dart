import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/backend/backend.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class ProgressService {
  /// Reports a finished game or activity. The server decides how much XP is
  /// actually granted (capped per game and per day) and returns it; games
  /// never give screen minutes. [key] makes retries safe: pass the same key
  /// when re-sending the same result.
  static Future<int> logActivity({
    required int xpEarned,
    required int playedMinutes,
    String activityName = 'general',
    int? achievedCombo,
    String? key,
  }) async {
    if (xpEarned <= 0 &&
        playedMinutes <= 0 &&
        (achievedCombo == null || achievedCombo == 0)) {
      return 0;
    }
    final childId = AppState.activeChildId;
    if (!Backend.isSignedIn || childId.isEmpty) return 0;

    try {
      var granted = 0;
      if (xpEarned > 0 || playedMinutes > 0) {
        final result = await Rewards.logActivity(
          childId: childId,
          activity: _activityName(activityName),
          xp: xpEarned,
          playedMinutes: playedMinutes,
          key: key,
        );
        final xp = result['xp'];
        granted = xp is int ? xp : 0;
      }

      if (achievedCombo != null && achievedCombo > 0) {
        await Rewards.saveRecord(
          childId,
          _activityName(activityName),
          'maxCombo',
          achievedCombo,
        );
      }

      await AppState.refreshActiveChild();
      debugPrint("Progress logged: +$granted XP, $playedMinutes min [$activityName]");
      return granted;
    } catch (e) {
      debugPrint("Error logging progress: $e");
      return 0;
    }
  }

  /// Server accepts lowercase letters and underscores only.
  static String _activityName(String name) {
    final cleaned = name.toLowerCase().replaceAll(RegExp(r'[^a-z_]'), '_');
    if (cleaned.isEmpty) return 'general';
    return cleaned.length > 30 ? cleaned.substring(0, 30) : cleaned;
  }
}

import 'package:read_unlock_app/core/backend/backend.dart';

/// The leaderboard comes from a server function that returns only a first
/// name, avatar and XP. Other families never see full child profiles.
class LeaderboardService {
  static Future<List<Map<String, dynamic>>> top({int limit = 50}) =>
      Rewards.leaderboard(limit: limit);

  /// Short public name: first word only, at most 20 characters.
  static String publicName(String? fullName) {
    final first = (fullName ?? '').trim().split(RegExp(r'\s+')).first;
    if (first.isEmpty) return 'Hero';
    return first.length > 20 ? first.substring(0, 20) : first;
  }
}

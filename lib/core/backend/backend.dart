import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Single entry point to Supabase for the whole app.
///
/// XP, minutes, unlocks and daily usage are never written from here
/// directly: they change only through the server functions in [Rewards]
/// (see supabase/migrations/20261102020000_reward_functions.sql).
class Backend {
  static SupabaseClient get db => Supabase.instance.client;

  static User? get currentUser => db.auth.currentUser;
  static String? get uid => db.auth.currentUser?.id;
  static bool get isSignedIn => db.auth.currentUser != null;

  static final Random _random = Random.secure();

  /// Unique key for one reward claim, so a retry never pays twice.
  static String newKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<Map<String, dynamic>> rpcMap(
    String fn, [
    Map<String, dynamic>? params,
  ]) async {
    final result = await db.rpc(fn, params: params);
    if (result is Map) return Map<String, dynamic>.from(result);
    return <String, dynamic>{};
  }
}

/// Maps a `children` row to the camelCase keys the screens already use.
Map<String, dynamic> childFromRow(Map<String, dynamic> r) {
  int i(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);
  List<String> s(Object? v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];
  return <String, dynamic>{
    'id': r['id']?.toString() ?? '',
    'name': r['name']?.toString() ?? '',
    'ageGroup': r['age_group']?.toString() ?? '',
    'avatar': r['avatar']?.toString() ?? 'boy1',
    'xp': i(r['xp']),
    'level': r['level'] == null ? 1 : i(r['level']),
    'timeBalance': i(r['time_balance']),
    'totalEarnedTime': i(r['total_earned_time']),
    'unlockedAvatars': s(r['unlocked_avatars']),
    'unlockedCards': s(r['unlocked_cards']),
    'dailyLimitMinutes': i(r['daily_limit_minutes']),
    'showOnLeaderboard': r['show_on_leaderboard'] != false,
    'learnedWords': r['learned_words'] is List ? r['learned_words'] : [],
    'records': r['records'] is Map
        ? Map<String, dynamic>.from(r['records'])
        : <String, dynamic>{},
    'lastBookReadId': r['last_book_read_id'],
    'createdAt': r['created_at'],
  };
}

class Children {
  static SupabaseQueryBuilder get _t => Backend.db.from('children');

  static Future<List<Map<String, dynamic>>> mine() async {
    final rows = await _t.select().order('created_at');
    return rows.map(childFromRow).toList();
  }

  static Future<Map<String, dynamic>?> get(String childId) async {
    if (childId.isEmpty) return null;
    final row = await _t.select().eq('id', childId).maybeSingle();
    return row == null ? null : childFromRow(row);
  }

  /// Live updates of one child (needs realtime on `children`).
  static Stream<Map<String, dynamic>?> watch(String childId) {
    return _t
        .stream(primaryKey: ['id'])
        .eq('id', childId)
        .map((rows) => rows.isEmpty ? null : childFromRow(rows.first));
  }

  static Stream<List<Map<String, dynamic>>> watchMine() {
    final parentId = Backend.uid ?? '';
    return _t
        .stream(primaryKey: ['id'])
        .eq('parent_id', parentId)
        .order('created_at')
        .map((rows) => rows.map(childFromRow).toList());
  }

  static Future<Map<String, dynamic>> add({
    required String name,
    String? ageGroup,
    String avatar = 'boy1',
  }) async {
    final row = await _t
        .insert({
          'parent_id': Backend.uid,
          'name': name,
          'age_group': ageGroup,
          'avatar': avatar,
        })
        .select()
        .single();
    return childFromRow(row);
  }

  /// Only profile fields; rewards go through [Rewards].
  static Future<void> updateProfile(
    String childId, {
    String? name,
    String? ageGroup,
    String? avatar,
    int? dailyLimitMinutes,
    bool? showOnLeaderboard,
  }) async {
    final patch = <String, dynamic>{
      if (name != null) 'name': name,
      if (ageGroup != null) 'age_group': ageGroup,
      if (avatar != null) 'avatar': avatar,
      if (dailyLimitMinutes != null) 'daily_limit_minutes': dailyLimitMinutes,
      if (showOnLeaderboard != null) 'show_on_leaderboard': showOnLeaderboard,
    };
    if (patch.isEmpty) return;
    await _t.update(patch).eq('id', childId);
  }

  static Future<void> delete(String childId) async {
    await _t.delete().eq('id', childId);
  }

  static Future<void> addLearnedWords(String childId, List<dynamic> words) async {
    if (words.isEmpty) return;
    await Backend.db.rpc(
      'add_learned_words',
      params: {'p_child_id': childId, 'p_words': words},
    );
  }

  /// Rows of `daily_activity`, newest first.
  static Future<List<Map<String, dynamic>>> dailyActivity(
    String childId, {
    int days = 30,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await Backend.db
        .from('daily_activity')
        .select()
        .eq('child_id', childId)
        .gte('day', since.toIso8601String().substring(0, 10))
        .order('day', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<int> letterLevel(String childId, String letter) async {
    final row = await Backend.db
        .from('letters')
        .select('level')
        .eq('child_id', childId)
        .eq('letter', letter.toUpperCase())
        .maybeSingle();
    final v = row?['level'];
    return v is int ? v : 0;
  }

  /// Letter progress for stages without a reward (the reward stage uses
  /// [Rewards.completeLetter]). Never lowers the level.
  static Future<void> saveLetterLevel(
    String childId,
    String letter,
    int level,
  ) async {
    final current = await letterLevel(childId, letter);
    if (level <= current) return;
    await Backend.db.from('letters').upsert({
      'child_id': childId,
      'letter': letter.toUpperCase(),
      'level': level,
    });
  }
}

/// Wrappers for the server reward functions. Each returns the server's
/// answer; the app shows what the server granted, not what it asked for.
class Rewards {
  static Future<String> startReading(String childId, String bookId) async {
    final id = await Backend.db.rpc(
      'start_reading',
      params: {'p_child_id': childId, 'p_book_id': bookId},
    );
    return id.toString();
  }

  static Future<Map<String, dynamic>> finishReading(
    String sessionId,
    int correctAnswers,
  ) => Backend.rpcMap('finish_reading', {
    'p_session_id': sessionId,
    'p_correct_answers': correctAnswers,
  });

  static Future<Map<String, dynamic>> logActivity({
    required String childId,
    required String activity,
    required int xp,
    required int playedMinutes,
    String? key,
  }) => Backend.rpcMap('log_activity', {
    'p_child_id': childId,
    'p_activity': activity,
    'p_xp': xp,
    'p_played_minutes': playedMinutes,
    'p_key': key ?? Backend.newKey(),
  });

  static Future<void> saveRecord(
    String childId,
    String game,
    String field,
    int value,
  ) async {
    await Backend.db.rpc(
      'save_record',
      params: {
        'p_child_id': childId,
        'p_game': game,
        'p_field': field,
        'p_value': value,
      },
    );
  }

  static Future<Map<String, dynamic>> completeLetter(
    String childId,
    String letter,
  ) => Backend.rpcMap('complete_letter', {
    'p_child_id': childId,
    'p_letter': letter,
  });

  static Future<Map<String, dynamic>> buyMinutes(
    String childId,
    int minutes, {
    String? key,
  }) => Backend.rpcMap('buy_minutes', {
    'p_child_id': childId,
    'p_minutes': minutes,
    'p_key': key ?? Backend.newKey(),
  });

  static Future<Map<String, dynamic>> buyAvatar(
    String childId,
    String avatarId,
  ) => Backend.rpcMap('buy_avatar', {
    'p_child_id': childId,
    'p_avatar_id': avatarId,
  });

  static Future<Map<String, dynamic>> startScreenSession(
    String childId,
    int minutes,
  ) => Backend.rpcMap('start_screen_session', {
    'p_child_id': childId,
    'p_minutes': minutes,
  });

  static Future<Map<String, dynamic>> endScreenSession(String sessionId) =>
      Backend.rpcMap('end_screen_session', {'p_session_id': sessionId});

  static Future<Map<String, dynamic>> parentAdjust(
    String childId, {
    required int xp,
    required int minutes,
    String? key,
  }) => Backend.rpcMap('parent_adjust', {
    'p_child_id': childId,
    'p_xp': xp,
    'p_minutes': minutes,
    'p_key': key ?? Backend.newKey(),
  });

  static Future<void> adminSetChildRewards(
    String childId, {
    required int xp,
    required int timeBalance,
    String reason = '',
  }) async {
    await Backend.db.rpc(
      'admin_set_child_rewards',
      params: {
        'p_child_id': childId,
        'p_xp': xp,
        'p_time_balance': timeBalance,
        'p_reason': reason,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> leaderboard({int limit = 50}) async {
    final rows = await Backend.db.rpc(
      'leaderboard_top',
      params: {'p_limit': limit},
    );
    return rows is List
        ? rows.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }
}

/// Shared settings: `app_config` (economy, global, app_settings) and
/// `game_settings`.
class AppConfig {
  static Future<Map<String, dynamic>> get(String key) async {
    final row = await Backend.db
        .from('app_config')
        .select('value')
        .eq('key', key)
        .maybeSingle();
    final v = row?['value'];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  /// Admins only (enforced by the database).
  static Future<void> set(String key, Map<String, dynamic> value) async {
    await Backend.db.from('app_config').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>> gameSettings(String key) async {
    final row = await Backend.db
        .from('game_settings')
        .select('value')
        .eq('key', key)
        .maybeSingle();
    final v = row?['value'];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  static Future<void> setGameSettings(
    String key,
    Map<String, dynamic> value,
  ) async {
    await Backend.db.from('game_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

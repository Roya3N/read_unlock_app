import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LevelRewards {
  static const Map<int, String> rewards = {
    3: 'hat_cool',
    5: 'avatar_dragon',
    10: 'super_hero_cape',
  };
  static bool isGuest = false;
  static bool isUnlocked(int currentLevel, int requiredLevel) {
    return currentLevel >= requiredLevel;
  }
}

class AppState {
  static const int _schemaVersion = 1;
  static const String _blobKey = 'app_state_v1';
  static const String _legacyChildrenKey = 'children';

  static bool isGuest = false;
  static int guestXp = 250; // سکه اولیه مهمان
  static int guestTime = 60; // زمان اولیه مهمان
  static List<dynamic> guestAvatars = ['1']; // آواتارهای پیش‌فرض مهمان

  // 🎯 CORE
  static int activeChildAge = 0;
  static int timeBalance = 0;
  static int totalEarnedTime = 0;
  static int streak = 0;
  static DateTime? lastActiveDate;

  static int get level => (totalEarnedTime ~/ 50) + 1;

  // 👤 USER (Parent/Global)
  static String userName = '';
  static String ageGroup = 'kids';
  static bool isLoggedIn = false;
  static String role = 'parent';
  static String parentPin = '';

  // 🔥 ACTIVE PARENT ID
  static String? get activeParentId => FirebaseAuth.instance.currentUser?.uid;

  // 👶 ACTIVE CHILD SESSION
  static String activeChildName = '';
  static String activeChildId = '';

  // 👶 CHILDREN (Local Cache)
  static List<Map<String, dynamic>> children = [];
  static int selectedChildIndex = 0;

  // 🎨 AVATAR
  static String avatar = 'boy1';
  static List<String> unlockedAvatars = ['boy1'];

  // 🏆 BADGES
  static List<String> badges = [];

  // =========================
  // 🔗 FIREBASE SHORTCUTS
  // =========================
  static DocumentReference? get currentChildRef {
    final parentId = activeParentId;
    if (parentId != null && activeChildId.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(activeChildId);
    }
    return null;
  }

  // =========================
  // ✅ INTENT METHODS
  // =========================

  static Future<void> addTime(int minutes) async {
    if (minutes <= 0) return;

    timeBalance += minutes;
    totalEarnedTime += minutes;
    await save();

    await currentChildRef?.set({
      'timeBalance': FieldValue.increment(minutes),
      'totalEarnedTime': FieldValue.increment(minutes),
    }, SetOptions(merge: true));
  }

  static Future<bool> spendTime(int minutes) async {
    if (minutes <= 0) return true;
    if (timeBalance < minutes) return false;

    timeBalance -= minutes;
    await save();

    try {
      await currentChildRef?.update({
        'timeBalance': FieldValue.increment(-minutes),
      });
      return true;
    } catch (e) {
      print("Error spending time: $e");
      return false;
    }
  }

  static void setUserProfile({
    required String name,
    required String roleValue,
    required String ageGroupValue,
  }) {
    userName = name;
    role = roleValue;
    ageGroup = ageGroupValue;
  }

  static void login() {
    isLoggedIn = true;
  }

  static void logout() {
    role = 'parent';
    activeChildId = '';
    activeChildName = '';
    unlockedAvatars = ['boy1'];
    avatar = 'boy1';
    timeBalance = 0;
    totalEarnedTime = 0;
    selectedChildIndex = 0;
  }

  static void setParentPin(String pin) {
    parentPin = pin;
  }

  static void selectChild(int index) {
    selectedChildIndex = index;
    _clampSelectedChildIndex();

    if (children.isNotEmpty && selectedChildIndex < children.length) {
      final child = children[selectedChildIndex];
      activeChildId = child['id'] ?? '';
      activeChildName = child['name'] ?? '';
    }
  }

  static Map<String, dynamic> createChild({
    required String name,
    int xp = 0,
    int level = 1,
    String avatarId = 'boy1',
    String? id,
  }) {
    return <String, dynamic>{
      'id':
          id ?? DateTime.now().millisecondsSinceEpoch.toString(), // شناسه یکتا
      'name': name,
      'xp': xp,
      'level': level,
      'avatar': avatarId,
      'timeBalance': 0,
      'learnedWords': [],
    };
  }

  static void setAvatar(String avatarId) {
    avatar = avatarId;
  }

  static Future<bool> unlockAvatar(
    String avatarId, {
    required int costMinutes,
  }) async {
    if (unlockedAvatars.contains(avatarId)) return true;

    final success = await spendTime(costMinutes);
    if (!success) return false;

    unlockedAvatars.add(avatarId);
    await save();

    await currentChildRef?.update({
      'unlockedAvatars': FieldValue.arrayUnion([avatarId]),
    });

    return true;
  }

  static bool hasBadge(String badgeId) => badges.contains(badgeId);

  static void addBadge(String badgeId) {
    if (!badges.contains(badgeId)) badges.add(badgeId);
  }

  static int get childrenCount => children.length;
  static bool get hasChildren => children.isNotEmpty;

  static int get safeSelectedChildIndex {
    _clampSelectedChildIndex();
    return selectedChildIndex;
  }

  static Map<String, dynamic>? get selectedChild {
    _clampSelectedChildIndex();
    if (children.isEmpty) return null;
    return children[selectedChildIndex];
  }

  // 🪄 متد اضافه کردن بچه (آکولادها فیکس شد)
  static Future<void> addChild(String name) async {
    final newChild = createChild(name: name);
    children.add(newChild);

    if (children.length == 1) {
      selectChild(0);
    } else {
      _clampSelectedChildIndex();
    }

    // آپلود در فایربیس
    final parentId = activeParentId;
    if (parentId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(newChild['id'])
            .set(newChild, SetOptions(merge: true));
      } catch (e) {
        print("Error saving child to Firebase: $e");
      }
    }
  } // پایان درستِ متد addChild

  // 🗑️ متد حذف اکانت (حالا سر جای درستشه)
  static Future<void> deleteChild(String childId) async {
    // ۱. حذف از لیست محلی گوشی
    children.removeWhere((child) => child['id'] == childId);

    // ۲. مدیریت سشن فعال
    if (activeChildId == childId) {
      activeChildId = '';
      activeChildName = '';
      if (children.isNotEmpty) {
        selectChild(0);
      }
    }

    await save();

    // ۳. حذف دائمی از دیتابیس فایربیس
    final parentId = activeParentId;
    if (parentId != null) {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .delete();
    }
  }

  static void checkBadges(int score) {
    if (!badges.contains('first_book')) badges.add('first_book');
    if (streak >= 3 && !badges.contains('streak_3')) badges.add('streak_3');
    if (score >= 3 && !badges.contains('quiz_master'))
      badges.add('quiz_master');
    if (timeBalance >= 60 && !badges.contains('time_60')) badges.add('time_60');
  }

  static void updateStreak() {
    final now = DateTime.now();

    if (lastActiveDate == null) {
      streak = 1;
    } else {
      final diff = now.difference(lastActiveDate!).inDays;
      if (diff == 1) streak++;
      if (diff > 1) streak = 1;
    }
    lastActiveDate = now;
  }

  // =========================
  // 💾 SAVE
  // =========================
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    final blob = jsonEncode(_toJson());
    await prefs.setString(_blobKey, blob);

    await prefs.setString('avatar', avatar);
    await prefs.setStringList('unlockedAvatars', unlockedAvatars);
    await prefs.setStringList('badges', badges);

    await prefs.setInt('timeBalance', timeBalance);
    await prefs.setInt('totalEarnedTime', totalEarnedTime);
    await prefs.setInt('streak', streak);

    await prefs.setString('userName', userName);
    await prefs.setString('ageGroup', ageGroup);
    await prefs.setBool('isLoggedIn', isLoggedIn);

    await prefs.setString('role', role);
    await prefs.setString('parentPin', parentPin);

    await prefs.setString('activeChildName', activeChildName);
    await prefs.setString('activeChildId', activeChildId);

    await prefs.setString(_legacyChildrenKey, jsonEncode(children));
    await prefs.setInt('selectedChildIndex', selectedChildIndex);

    await prefs.setString(
      'lastActiveDate',
      lastActiveDate?.toIso8601String() ?? '',
    );
  }

  // =========================
  // 📥 LOAD
  // =========================
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final blob = prefs.getString(_blobKey);
    if (blob != null && blob.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(blob);
        if (decoded is Map<String, dynamic>) {
          _applyFromJson(decoded);
          _sanitizeAfterLoad();
          return;
        }
      } catch (_) {}
    }

    userName = prefs.getString('userName') ?? '';
    ageGroup = prefs.getString('ageGroup') ?? 'kids';
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    role = prefs.getString('role') ?? 'parent';
    parentPin = prefs.getString('parentPin') ?? '';
    activeChildName = prefs.getString('activeChildName') ?? '';
    activeChildId = prefs.getString('activeChildId') ?? '';
    selectedChildIndex = prefs.getInt('selectedChildIndex') ?? 0;
    avatar = prefs.getString('avatar') ?? 'boy1';
    unlockedAvatars = prefs.getStringList('unlockedAvatars') ?? ['boy1'];
    badges = prefs.getStringList('badges') ?? [];
    timeBalance = prefs.getInt('timeBalance') ?? 0;
    totalEarnedTime = prefs.getInt('totalEarnedTime') ?? 0;
    streak = prefs.getInt('streak') ?? 0;
    children = _decodeChildren(prefs.getString(_legacyChildrenKey));

    _sanitizeAfterLoad();

    final dateString = prefs.getString('lastActiveDate');
    lastActiveDate = (dateString == null || dateString.isEmpty)
        ? null
        : DateTime.tryParse(dateString);

    await prefs.setString(_blobKey, jsonEncode(_toJson()));
  }

  static Map<String, dynamic> _toJson() {
    return <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'core': <String, dynamic>{
        'timeBalance': timeBalance,
        'totalEarnedTime': totalEarnedTime,
        'streak': streak,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
      },
      'user': <String, dynamic>{
        'userName': userName,
        'ageGroup': ageGroup,
        'isLoggedIn': isLoggedIn,
        'role': role,
        'parentPin': parentPin,
        'activeChildName': activeChildName,
        'activeChildId': activeChildId,
      },
      'children': <String, dynamic>{
        'items': children,
        'selectedChildIndex': selectedChildIndex,
      },
      'avatar': <String, dynamic>{
        'avatar': avatar,
        'unlockedAvatars': unlockedAvatars,
      },
      'rewards': <String, dynamic>{'badges': badges},
    };
  }

  static void _applyFromJson(Map<String, dynamic> json) {
    final core = json['core'];
    if (core is Map) {
      timeBalance = _asInt(core['timeBalance'], defaultValue: 0);
      totalEarnedTime = _asInt(core['totalEarnedTime'], defaultValue: 0);
      streak = _asInt(core['streak'], defaultValue: 0);
      final dateStr = core['lastActiveDate'];
      lastActiveDate = (dateStr is String && dateStr.isNotEmpty)
          ? DateTime.tryParse(dateStr)
          : null;
    }

    final user = json['user'];
    if (user is Map) {
      userName = _asString(user['userName'], defaultValue: '');
      ageGroup = _asString(user['ageGroup'], defaultValue: 'kids');
      isLoggedIn = _asBool(user['isLoggedIn'], defaultValue: false);
      role = _asString(user['role'], defaultValue: 'parent');
      parentPin = _asString(user['parentPin'], defaultValue: '');
      activeChildName = _asString(user['activeChildName'], defaultValue: '');
      activeChildId = _asString(user['activeChildId'], defaultValue: '');
    }

    final childrenJson = json['children'];
    if (childrenJson is Map) {
      selectedChildIndex = _asInt(
        childrenJson['selectedChildIndex'],
        defaultValue: 0,
      );
      final items = childrenJson['items'];
      children = _decodeChildren(items);
    } else {
      children = [];
      selectedChildIndex = 0;
    }

    final avatarJson = json['avatar'];
    if (avatarJson is Map) {
      avatar = _asString(avatarJson['avatar'], defaultValue: 'boy1');
      unlockedAvatars = _asStringList(
        avatarJson['unlockedAvatars'],
        defaultValue: ['boy1'],
      );
    }

    final rewards = json['rewards'];
    if (rewards is Map) {
      badges = _asStringList(rewards['badges'], defaultValue: <String>[]);
    }
  }

  static List<Map<String, dynamic>> _decodeChildren(Object? source) {
    try {
      Object? decoded = source;
      if (decoded is String) {
        if (decoded.trim().isEmpty) return [];
        decoded = jsonDecode(decoded);
      }
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .map(_sanitizeChild)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Map<String, dynamic> _sanitizeChild(Map<String, dynamic> child) {
    return <String, dynamic>{
      'id': _asString(
        child['id'],
        defaultValue: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      'name': _asString(child['name'], defaultValue: ''),
      'xp': _asInt(child['xp'], defaultValue: 0),
      'level': _asInt(child['level'], defaultValue: 1),
      'avatar': _asString(child['avatar'], defaultValue: 'boy1'),
      'timeBalance': _asInt(child['timeBalance'], defaultValue: 0),
      'learnedWords': child['learnedWords'] is List
          ? child['learnedWords']
          : [],
    };
  }

  static void _sanitizeAfterLoad() {
    if (timeBalance < 0) timeBalance = 0;
    if (totalEarnedTime < 0) totalEarnedTime = 0;
    if (streak < 0) streak = 0;

    if (unlockedAvatars.isEmpty) unlockedAvatars = ['boy1'];
    if (avatar.isEmpty) avatar = unlockedAvatars.first;

    _clampSelectedChildIndex();

    if (activeChildId.isEmpty && children.isNotEmpty) {
      selectChild(selectedChildIndex);
    }
  }

  static void _clampSelectedChildIndex() {
    if (children.isEmpty) {
      selectedChildIndex = 0;
    } else if (selectedChildIndex < 0) {
      selectedChildIndex = 0;
    } else if (selectedChildIndex >= children.length) {
      selectedChildIndex = 0;
    }
  }

  static int _asInt(Object? v, {required int defaultValue}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static String _asString(Object? v, {required String defaultValue}) {
    if (v is String) return v;
    return defaultValue;
  }

  static bool _asBool(Object? v, {required bool defaultValue}) {
    if (v is bool) return v;
    if (v is String) {
      if (v.toLowerCase() == 'true') return true;
      if (v.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }

  static List<String> _asStringList(
    Object? v, {
    required List<String> defaultValue,
  }) {
    if (v is List) {
      return v.whereType<String>().toList();
    }
    return defaultValue;
  }

  static Map<String, dynamic>? get activeChild {
    return selectedChild;
  }
}

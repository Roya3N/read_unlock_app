import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  static const _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // ==========================================
  // 🔑 کلیدهای گاوصندوق
  // ==========================================
  static const String _parentPinHashKey = 'secure_parent_pin_hash';
  static const String _failedAttemptsKey = 'secure_failed_attempts';
  static const String _lockoutTimeKey = 'secure_lockout_time';
  static Future<void> deleteParentPin() async {
    await _storage.delete(key: _parentPinHashKey);
  }

  // ==========================================
  // 🧠 موتور هشینگ (Hashing)
  // ==========================================
  static String hashPin(String pin) {
    var bytes = utf8.encode(pin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ==========================================
  // 🔐 مدیریت رمز عبور والدین
  // ==========================================
  static Future<void> saveParentPin(String pin) async {
    String hashedPin = hashPin(pin);
    await _storage.write(key: _parentPinHashKey, value: hashedPin);
  }

  // ذخیره مستقیم هشِ دانلود شده از فایربیس
  static Future<void> saveRawHash(String hash) async {
    await _storage.write(key: _parentPinHashKey, value: hash);
  }

  static Future<bool> hasParentPin() async {
    final hash = await _storage.read(key: _parentPinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<bool> verifyParentPin(String inputPin) async {
    String? savedHash = await _storage.read(key: _parentPinHashKey);
    if (savedHash == null) return false;
    String inputHash = hashPin(inputPin);
    return savedHash == inputHash;
  }

  // ==========================================
  // 🛑 سیستم جلوگیری از هک (Brute-Force Protection)
  // ==========================================

  // گرفتن تعداد دفعات اشتباه
  static Future<int> getFailedAttempts() async {
    String? attemptsStr = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(attemptsStr ?? '0') ?? 0;
  }

  // ذخیره تعداد دفعات اشتباه
  static Future<void> saveFailedAttempts(int attempts) async {
    await _storage.write(key: _failedAttemptsKey, value: attempts.toString());
  }

  // گرفتن زمان پایان مسدودی
  static Future<DateTime?> getLockoutTime() async {
    String? timeStr = await _storage.read(key: _lockoutTimeKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // ذخیره زمان مسدودی
  static Future<void> saveLockoutTime(DateTime time) async {
    await _storage.write(key: _lockoutTimeKey, value: time.toIso8601String());
  }

  // ریست کردن قفل و شمارنده اشتباهات (وقتی رمز درست وارد میشه)
  static Future<void> resetLockout() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutTimeKey);
  }

  // ==========================================
  // 🧹 پاکسازی کامل
  // ==========================================
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    debugPrint("🗑️ All secure data cleared!");
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:read_unlock_app/core/backend/backend.dart';
import 'package:read_unlock_app/core/services/secure_storage_service.dart'; // 👈 گاوصندوق اضافه شد

class AuthService {
  GoTrueClient get _auth => Backend.db.auth;

  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationSeconds = 30;

  // ==========================================
  // 1. Sign Up (Parent)
  // ==========================================
  Future<String?> signUpParent({
    required String email,
    required String password,
    required String name,
    required String dob,
  }) async {
    try {
      // The parent row is created by a database trigger from this metadata.
      // Supabase sends the confirmation email itself.
      await _auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'dob': _isoDate(dob)},
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// "2015/3/7" -> "2015-03-07"; anything else -> null.
  static String? _isoDate(String text) {
    final m = RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$').firstMatch(text);
    if (m == null) return null;
    return '${m[1]}-${m[2]!.padLeft(2, '0')}-${m[3]!.padLeft(2, '0')}';
  }

  // ==========================================
  // 2. Sign In (با گاوصندوق امنیتی 🛡️)
  // ==========================================
  Future<String?> signIn(String email, String password) async {
    // خواندن اطلاعات امنیتی از گاوصندوق به جای SharedPreferences
    int failedAttempts = await SecureStorageService.getFailedAttempts();
    DateTime? lockoutUntil = await SecureStorageService.getLockoutTime();

    // 🛑 بررسی وضعیت مسدودی
    if (lockoutUntil != null) {
      if (DateTime.now().isBefore(lockoutUntil)) {
        final secondsLeft = lockoutUntil.difference(DateTime.now()).inSeconds;
        return "🚨 Login is locked. Try again in $secondsLeft seconds.";
      } else {
        // زمان قفل تمام شده، ریست می‌کنیم
        await SecureStorageService.resetLockout();
        failedAttempts = 0;
      }
    }

    try {
      await _auth.signInWithPassword(email: email, password: password);

      // ✅ موفقیت‌آمیز بود: ریست کردن خطاهای امنیتی
      await SecureStorageService.resetLockout();
      return null;
    } on AuthException catch (e) {
      // ❌ ورود ناموفق: افزایش کنتور اشتباهات
      failedAttempts++;

      if (failedAttempts >= _maxFailedAttempts) {
        // فعال‌سازی قفل ۳۰ ثانیه‌ای
        DateTime lockUntil = DateTime.now().add(
          const Duration(seconds: _lockoutDurationSeconds),
        );
        await SecureStorageService.saveLockoutTime(lockUntil);
        return "🚨 Too many failed attempts! Login locked for 30 seconds.";
      } else {
        await SecureStorageService.saveFailedAttempts(failedAttempts);
      }
      return e.message;
    }
  }

  // ==========================================
  // 3. Reset Password
  // ==========================================
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // ==========================================
  // 4. Sign Out
  // ==========================================
  Future<void> signOut() async {
    await _auth.signOut();
    await SecureStorageService.clearAll(); // پاک کردن اطلاعات حساس موقع خروج
  }

  User? get currentUser => _auth.currentUser;
}

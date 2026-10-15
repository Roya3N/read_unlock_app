import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/services/secure_storage_service.dart'; // 👈 گاوصندوق اضافه شد

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        try {
          await user.sendEmailVerification();
          debugPrint("✅ Verification email sent to: $email");
        } catch (emailError) {
          debugPrint("❌ Failed to send email: $emailError");
        }

        // ذخیره اطلاعات والدین در دیتابیس
        await _db.collection('parents').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'dob': dob,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'parent',
        });

        return null; // یعنی خطایی وجود ندارد
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
    return "An unknown error occurred.";
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
      // تلاش برای ورود به فایربیس
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // ✅ موفقیت‌آمیز بود: ریست کردن خطاهای امنیتی
      await SecureStorageService.resetLockout();
      return null;
    } on FirebaseAuthException catch (e) {
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
      return e.message; // نمایش ارور فایربیس (مثلاً رمز اشتباه است)
    }
  }

  // ==========================================
  // 3. Reset Password
  // ==========================================
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
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

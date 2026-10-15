import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/services/secure_storage_service.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class AuthController extends ChangeNotifier {
  // وضعیت‌های صفحه (States)
  bool isLoading = true;
  bool isLockedOut = false;
  String lockoutMessage = '';
  String errorMessage = '';
  bool isSetupMode = false;

  Timer? _lockoutTimer;

  // مقداردهی اولیه و چک کردن وضعیت امنیتی
  Future<void> checkSecurityStatus({required bool forceSetup}) async {
    isLoading = true;
    notifyListeners();

    // ۱. بررسی مسدودی
    DateTime? lockoutTime = await SecureStorageService.getLockoutTime();
    if (lockoutTime != null && DateTime.now().isBefore(lockoutTime)) {
      _startLockoutTimer(lockoutTime);
      return;
    } else {
      await SecureStorageService.resetLockout();
    }

    // ۲. بررسی رمز عبور (از گاوصندوق یا دیتابیس)
    bool hasPin = await SecureStorageService.hasParentPin();

    if (!hasPin) {
      // تلاش برای دانلود از فایربیس
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('parents')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data()!.containsKey('parentPinHash')) {
            // فرض می‌کنیم در دیتابیس هم هش شده ذخیره می‌شود
            String downloadedHash = doc.data()!['parentPinHash'];
            await SecureStorageService.saveRawHash(downloadedHash);
            hasPin = true;
          }
        } catch (e) {
          debugPrint("Error fetching PIN: $e");
        }
      }
    }

    isSetupMode = forceSetup || !hasPin;
    isLoading = false;
    notifyListeners();
  }

  // مدیریت ثبت/تایید رمز عبور
  Future<bool> submitPin(String inputPin) async {
    if (isLockedOut) return false;

    if (inputPin.length < 4) {
      errorMessage = 'Password must be at least 4 characters';
      notifyListeners();
      return false;
    }

    if (isSetupMode) {
      // 🔒 ذخیره رمز جدید (هش شده)
      await SecureStorageService.saveParentPin(inputPin);

      // ☁️ سینک با فایربیس (ذخیره هش)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String hash = SecureStorageService.hashPin(
          inputPin,
        ); // از متد هش استفاده کن
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .set({'parentPinHash': hash}, SetOptions(merge: true));
      }
      return true;
    } else {
      // 🛡️ تایید رمز عبور
      bool isValid = await SecureStorageService.verifyParentPin(inputPin);

      if (isValid) {
        await SecureStorageService.resetLockout();
        errorMessage = '';
        notifyListeners();
        return true;
      } else {
        await _handleFailedAttempt();
        return false;
      }
    }
  }

  Future<void> _handleFailedAttempt() async {
    int failedAttempts = await SecureStorageService.getFailedAttempts() + 1;

    if (failedAttempts >= 5) {
      final lockoutTime = DateTime.now().add(const Duration(minutes: 15));
      await SecureStorageService.saveLockoutTime(lockoutTime);
      _startLockoutTimer(lockoutTime);
    } else {
      await SecureStorageService.saveFailedAttempts(failedAttempts);
      errorMessage = 'Incorrect Password. ${5 - failedAttempts} attempts left!';
      notifyListeners();
    }
  }

  void _startLockoutTimer(DateTime lockoutTime) {
    isLockedOut = true;
    isLoading = false;
    notifyListeners();

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(lockoutTime)) {
        timer.cancel();
        SecureStorageService.resetLockout();
        isLockedOut = false;
        lockoutMessage = '';
        errorMessage = '';
        notifyListeners();
      } else {
        final remaining = lockoutTime.difference(now);
        lockoutMessage =
            'Too many attempts. Try again in ${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ==========================================
  // 🚀 راه‌اندازی اکانت جدید (Setup Account)
  // ==========================================
  Future<bool> setupParentAccount({
    required String parentName,
    required String pin,
    required String childName,
    required String ageGroup,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      // ۱. 🔐 ذخیره پین‌کد به صورت هش شده در گاوصندوق
      await SecureStorageService.saveParentPin(pin);

      // ۲. ☁️ سینک با فایربیس (اگر کاربر لاگین باشه)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String hash = SecureStorageService.hashPin(pin);
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .set({
              'parentName': parentName,
              'parentPinHash': hash,
              'setupCompleted': true,
            }, SetOptions(merge: true));
      }

      // ۳. آپدیت وضعیت‌های لوکال
      AppState.userName = parentName;
      AppState.role = 'parent';
      AppState.children = [];
      AppState.addChild(childName);
      AppState.ageGroup = ageGroup;
      AppState.isLoggedIn = true;
      await AppState.save();

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = "Setup failed: $e";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

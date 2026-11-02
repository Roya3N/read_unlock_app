import 'dart:async';
import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/backend/backend.dart';
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
      final uid = Backend.uid;
      if (uid != null) {
        try {
          final row = await Backend.db
              .from('parents')
              .select('pin_hash')
              .eq('id', uid)
              .maybeSingle();
          final downloadedHash = row?['pin_hash'];
          if (downloadedHash is String && downloadedHash.isNotEmpty) {
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

      final uid = Backend.uid;
      if (uid != null) {
        final hash = SecureStorageService.hashPin(inputPin);
        await Backend.db
            .from('parents')
            .update({'pin_hash': hash})
            .eq('id', uid);
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

      final uid = Backend.uid;
      if (uid != null) {
        final hash = SecureStorageService.hashPin(pin);
        await Backend.db
            .from('parents')
            .update({
              'name': parentName,
              'pin_hash': hash,
              'setup_completed': true,
            })
            .eq('id', uid);
      }

      // ۳. آپدیت وضعیت‌های لوکال
      AppState.userName = parentName;
      AppState.role = 'parent';
      AppState.children = [];
      await AppState.addChild(childName, ageGroupValue: ageGroup);
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

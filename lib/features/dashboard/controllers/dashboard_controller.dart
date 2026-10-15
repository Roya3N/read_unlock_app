import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/core/services/secure_storage_service.dart';

class DashboardController extends ChangeNotifier {
  // === وضعیت‌های (States) رابط کاربری ===
  bool isLoading = true;
  int celebratedLevel = 0;

  // دیتای مربوط به کودک یا مهمان
  Map<String, dynamic> activeData = {};
  int currentLevel = 1;
  int currentLevelXp = 0;
  double progressPercent = 0.0;
  int timeBalance = 0;

  // استریم فایربیس (برای لغو اتصال در صورت خروج)
  StreamSubscription<DocumentSnapshot>? _childDataSubscription;

  // === راه‌اندازی اولیه ===
  void initialize() {
    if (AppState.isGuest) {
      _loadGuestData();
    } else if (AppState.role == 'parent') {
      _loadParentData();
    } else {
      _startChildDataStream();
    }
  }

  // --- بارگذاری دیتای حالت مهمان (Guest) ---
  void _loadGuestData() {
    activeData = {
      'name': 'Guest Hero',
      'xp': AppState.guestXp,
      'timeBalance': AppState.guestTime,
      'avatar': 'boy1',
      'unlockedAvatars': AppState.guestAvatars,
    };

    _calculateLevelAndProgress(AppState.guestXp, AppState.guestTime);
    isLoading = false;
    notifyListeners();
  }

  // --- بارگذاری دیتای حالت والدین (Parent) ---
  void _loadParentData() {
    isLoading = false;
    notifyListeners();
    // در داشبورد والدین نیازی به دیتای بازی نداریم
  }

  // --- استریم زنده اطلاعات کودک از فایربیس ---
  void _startChildDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || AppState.activeChildId.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    _childDataSubscription = FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(AppState.activeChildId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              activeData = snapshot.data() as Map<String, dynamic>;

              int totalXp = activeData['xp'] ?? 0;
              int tBalance = activeData['timeBalance'] ?? 0;

              // همگام‌سازی با استیت محلی (AppState)
              AppState.avatar = (activeData['avatar'] ?? 'boy1').toString();
              AppState.timeBalance = tBalance;

              _calculateLevelAndProgress(totalXp, tBalance);
            }

            isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Error fetching child data: $error");
            isLoading = false;
            notifyListeners();
          },
        );
  }

  // --- محاسبات ریاضی سطح و پیشرفت ---
  void _calculateLevelAndProgress(int totalXp, int tBalance) {
    currentLevel = (totalXp ~/ 100) + 1;
    currentLevelXp = totalXp % 100;
    progressPercent = currentLevelXp / 100.0;
    timeBalance = tBalance;
  }

  // === منطق خروج (Logout / Exit Kid Mode) ===
  Future<void> performLogout() async {
    await FirebaseAuth.instance.signOut();
    await SecureStorageService.clearAll();
    AppState.logout();
    await AppState.save();
  }

  Future<void> performExitKidMode() async {
    AppState.role = 'parent';
    AppState.activeChildName = '';
    AppState.activeChildId = '';
    await AppState.save();
  }

  // === پاکسازی حافظه هنگام بستن صفحه ===
  @override
  void dispose() {
    _childDataSubscription?.cancel();
    super.dispose();
  }
}

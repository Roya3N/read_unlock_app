import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:read_unlock_app/features/auth/screens/login_screen.dart';
import 'package:read_unlock_app/features/auth/screens/pin_screen.dart';
import 'package:read_unlock_app/features/child/screens/avatar_screen.dart';
import 'package:read_unlock_app/features/child/screens/child_insights_screen.dart';
import 'package:read_unlock_app/features/child/screens/child_selector_screen.dart';
import 'package:read_unlock_app/features/child/screens/parent_screen.dart';
import 'package:read_unlock_app/features/child/screens/parent_signup_screen.dart';
import 'package:read_unlock_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:read_unlock_app/features/engagement/screens/shop_screen.dart';
import 'package:read_unlock_app/features/engagement/screens/time_wallet_screen.dart';
import 'package:read_unlock_app/features/game/screens/math_quest_screen.dart';
import 'package:read_unlock_app/features/game/screens/memory_hub_screen.dart';
import 'package:read_unlock_app/features/reading/screens/academy_screen.dart';
import 'package:read_unlock_app/features/reading/screens/book_library_screen.dart';
import 'package:read_unlock_app/features/reading/screens/homework_solver_screen.dart';
import 'package:read_unlock_app/features/reading/screens/paper_selector_screen.dart';
import 'package:read_unlock_app/features/system/screens/settings_screen.dart';
import 'leaderboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _celebratedLevel = 0;

  // 🎨 رنگ‌های تم Pro برای پنل والدین
  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color accentBlue = const Color(0xFF3B82F6);
  final DashboardController _dashboardController = DashboardController();

  @override
  void initState() {
    super.initState();
    _dashboardController.initialize();
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    super.dispose();
  }

  // ==========================================
  // دیالوگ‌های سیستمی و خروج
  // ==========================================
  Future<bool?> _showExitConfirmation(String title, String message) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: FadeTransition(
            opacity: a1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.2),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.power_settings_new_rounded,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Yes, Exit",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // منطق و ناوبری صفحات
  // ==========================================
  Future<void> _openParentPanel() async {
    HapticFeedback.mediumImpact();
    final success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen()),
    );
    if (success == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentScreen()),
      );
      if (mounted) setState(() {});
    }
  }

  Future<void> _switchChild() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildSelectorScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _changeAvatar() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvatarScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openLibrary() async => await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const BookLibraryScreen()),
  );
  Future<void> _openGames() async => await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MemoryHubScreen()),
  );
  Future<void> _openMathGame() async => await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MathQuestScreen()),
  );
  // 👈 صفحه جدید آکادمی
  Future<void> _openAcademy() async => await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AcademyScreen()),
  );

  Future<void> _useTime() async => await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TimeWalletScreen()),
  );

  Future<void> _openMyProgress(Map<String, dynamic> childData) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildInsightsScreen(
          childId: AppState.activeChildId,
          childData: childData,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await _showExitConfirmation(
      "Log Out?",
      "Are you sure you want to log out of your parent account?",
    );
    if (confirm != true) return;

    await _dashboardController.performLogout(); // 👈 فراخوانی کنترلر

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _exitKidMode() async {
    final confirm = await _showExitConfirmation(
      "Lock Screen?",
      "Are you sure you want to exit Kid Mode?",
    );
    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    final success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen()),
    );
    if (success == true) {
      AppState.role = 'parent';
      AppState.activeChildName = '';
      AppState.activeChildId = '';
      await AppState.save();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  // ==========================================
  // 🛡️ Pro Upgrade: ایست بازرسی فوق امنیتی ادمین
  // ==========================================
  Future<void> _openAdminPanel() async {
    HapticFeedback.heavyImpact();

    final user = FirebaseAuth.instance.currentUser;
    const adminEmail = "roya3n@gmail.com";

    // ۱. اگر ایمیل ادمین نبود، وانمود کن فقط یه متن مخفی پیدا کرده
    if (user == null || user.email != adminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "✨ You discovered a secret text!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
      return;
    }

    String enteredPin = '';

    // ۲. نمایش دیالوگ شیشه‌ای و فوق‌امنیتی
    bool isAuthorized =
        await showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6), // تاریک کردن پس‌زمینه
          builder: (context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.95),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Admin Auth",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enter the Master Code to access the Command Center.",
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      obscureText: true,
                      autofocus: true, // کیبورد خودکار باز می‌شود
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        letterSpacing: 8,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          letterSpacing: 8,
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF8B5CF6),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (val) => enteredPin = val,
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.only(
                  right: 20,
                  bottom: 20,
                  left: 20,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      "Abort",
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      elevation: 10,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (enteredPin == "Roya2026") {
                        Navigator.pop(context, true);
                      } else {
                        Navigator.pop(context, false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "❌ Access Denied! Incorrect Master Code.",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Verify",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;

    // ۳. هدایت به داشبورد مرکزی ادمین (نه فقط آپلودر)
    if (isAuthorized) {
      if (!mounted) return;
      HapticFeedback.vibrate(); // ویبره تایید نهایی
      Navigator.push(
        context,
        // 🚀 حالا مستقیم میره تو AdminDashboard
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    }
  }

  // ==========================================
  // دیالوگ جشن ارتقا سطح (Level Up)
  // ==========================================
  void _showLevelUpCelebration(int newLevel) {
    HapticFeedback.heavyImpact();
    String? rewardIcon = newLevel == 3
        ? "🎩"
        : (newLevel == 5 ? "🐲" : (newLevel == 10 ? "🦸‍♂️" : null));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(anim1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFFFBBF24),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        "LEVEL UP!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8B5CF6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Amazing! You've reached\nLevel $newLevel",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (rewardIcon != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFFC084FC),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "🎁 NEW UNLOCK!",
                                style: TextStyle(
                                  color: Color(0xFF9333EA),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                rewardIcon,
                                style: const TextStyle(fontSize: 50),
                              ),
                            ],
                          ),
                        ).animate().scale(
                          delay: 300.ms,
                          curve: Curves.easeOutBack,
                        ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF166534),
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            "AWESOME!",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -40,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBBF24),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text("🌟", style: TextStyle(fontSize: 60)),
                  ).animate().rotate(duration: 1.seconds),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // بدنه اصلی برنامه
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dashboardController,
      builder: (context, child) {
        if (_dashboardController.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        // ۱. حالت مهمان (Guest)
        if (AppState.isGuest) {
          return _buildKidCartoonDashboard(
            _dashboardController.activeData,
            _dashboardController.currentLevel,
            _dashboardController.currentLevelXp,
            _dashboardController.progressPercent,
            _dashboardController.timeBalance,
          );
        }

        // ۲. حالت والدین (Parent)
        if (AppState.role == 'parent') {
          return _buildParentProDashboard();
        }

        // ۳. حالت کودک (Child - دیتا از فایربیس آپدیت شده در کنترلر)
        // بررسی بالا رفتن سطح برای نمایش انیمیشن
        if (_celebratedLevel != 0 &&
            _dashboardController.currentLevel > _celebratedLevel) {
          _celebratedLevel = _dashboardController.currentLevel;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showLevelUpCelebration(_dashboardController.currentLevel),
          );
        } else if (_celebratedLevel == 0) {
          _celebratedLevel = _dashboardController.currentLevel;
        }

        return _buildKidCartoonDashboard(
          _dashboardController.activeData,
          _dashboardController.currentLevel,
          _dashboardController.currentLevelXp,
          _dashboardController.progressPercent,
          _dashboardController.timeBalance,
        );
      },
    );
  }

  // ==========================================
  // توابع کمکی برای طراحی UI
  // ==========================================
  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 150)],
      ),
    );
  }

  Widget _buildGlassParentButton(
    String text,
    Color glowColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: glowColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: glowColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: glowColor.withOpacity(0.2), blurRadius: 15),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 👨‍💼 داشبورد حرفه‌ای و شیشه‌ای والدین
  // ==========================================
  Widget _buildParentProDashboard() {
    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowOrb(primaryNeon, 400),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildGlowOrb(accentBlue, 350),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // 📍 کدهای صفحه Command Center (همین عکسی که فرستادی)
                      GestureDetector(
                        onLongPress: () {
                          // 🛡️ به جای رفتن مستقیم، تابع بازرسی رو صدا می‌زنیم
                          _openAdminPanel();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Smart ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Unlock",
                              style: TextStyle(
                                color: const Color(0xFF8B5CF6),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withOpacity(0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1E1E24,
                                  ).withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Command Center",
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Parent Dashboard",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.settings_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              HapticFeedback.mediumImpact();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const SettingsScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 40),
                                    _buildGlassParentButton(
                                      "⚙️ Parent Panel",
                                      primaryNeon,
                                      _openParentPanel,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildGlassParentButton(
                                      "👶 Switch Child",
                                      accentBlue,
                                      _switchChild,
                                    ),
                                    const SizedBox(height: 30),

                                    GestureDetector(
                                      onTap: _logout,
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(
                                            0.1,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.redAccent.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.power_settings_new_rounded,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fade(delay: 200.ms)
                          .scale(curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🚀 👶 داشبورد شاد کودکان
  // ==========================================
  Widget _buildKidCartoonDashboard(
    Map<String, dynamic> data,
    int currentLevel,
    int currentLevelXp,
    double progressPercent,
    int timeBalance,
  ) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double cardWidth = screenWidth > 700 ? 700 : screenWidth * 0.99;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/cartoon_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) =>
                  Container(color: const Color(0xFF89CFF0)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: cardWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildCartoonAppTitle()
                          .animate()
                          .fade(duration: 500.ms)
                          .scale(curve: Curves.easeOutBack),
                      const SizedBox(height: 15),

                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 15, bottom: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(
                                    screenWidth * 0.02,
                                    70,
                                    screenWidth * 0.02,
                                    25,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // 🌟 کارت یکپارچه و زیبای وضعیت (XP + Min + Goal)
                                      _buildUnifiedStatsCard(
                                            currentLevel,
                                            currentLevelXp,
                                            progressPercent,
                                            data,
                                          )
                                          .animate()
                                          .fade(delay: 200.ms)
                                          .scale(curve: Curves.easeOutBack),

                                      const SizedBox(height: 5),

                                      // منوی اصلی ۵ دکمه‌ای (Game Stations)
                                      _buildGameStations()
                                          .animate()
                                          .fade(delay: 300.ms)
                                          .scale(curve: Curves.easeOutBack),

                                      const SizedBox(height: 5),

                                      // دکمه‌های رنگی اکشن
                                      _buildActionButtons(data, currentLevel)
                                          .animate()
                                          .fade(delay: 400.ms)
                                          .slideY(begin: 0.05),

                                      const SizedBox(height: 15),

                                      // بخش صندوق گنج
                                      _buildTreasureSection(timeBalance)
                                          .animate()
                                          .fade(delay: 500.ms)
                                          .slideY(begin: 0.05),

                                      const SizedBox(height: 5),

                                      // دکمه قفل
                                      _buildGuestOrLockAction(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -50,
                            left: 0,
                            right: 0,
                            child: _buildWelcomeBanner(AppState.activeChildName)
                                .animate()
                                .fade(duration: 600.ms, delay: 300.ms)
                                .slideY(begin: -0.5, curve: Curves.bounceOut),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestOrLockAction() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (AppState.isGuest) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ParentSignupScreen()),
          );
        } else {
          _exitKidMode();
        }
      },
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppState.isGuest
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppState.isGuest
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.3),
                  ),
                  boxShadow: AppState.isGuest
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppState.isGuest
                          ? Icons.person_add_rounded
                          : Icons.lock_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    if (AppState.isGuest) ...[
                      const SizedBox(width: 10),
                      const Text(
                        "Sign Up to Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2)),
    );
  }

  Widget _buildCartoonAppTitle() {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        children: const [
          TextSpan(
            text: "Smart",
            style: TextStyle(color: Color.fromARGB(255, 97, 2, 2)),
          ),
          TextSpan(
            text: " Unlock",
            style: TextStyle(color: Color.fromARGB(255, 4, 64, 85)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(String name) {
    final String avatarId = AppState.avatar.isNotEmpty
        ? AppState.avatar
        : "boy1";
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(left: 45, right: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/bg_welcome.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
              Positioned(
                left: 5,
                right: 20,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Welcome Back, $name!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 15,
          child: GestureDetector(
            onTap: _changeAvatar,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE047),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFFFF914D),
                  child: Image.asset(
                    'assets/avatars/$avatarId.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => const Center(
                      child: Text("👦", style: TextStyle(fontSize: 45)),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data, int currentLevel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildImageButton(
            "Homework",
            "📝",
            'assets/images/Green_button.png',
            _showProHomeworkMenu,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildImageButton(
            "Progress",
            "⭐",
            'assets/images/ping_button.png',
            () => _openMyProgress(data),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildImageButton(
            "Missions",
            "🎯",
            'assets/images/blue_button.png',
            _showDailyMissionsMenu,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildImageButton(
            "Shop",
            "🛍️",
            'assets/images/orenge_button.png',
            () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopScreen(
                    currentXp: data['xp'] ?? 0,
                    currentLevel: currentLevel,
                    unlockedAvatars:
                        data['unlockedAvatars'] ?? ['boy1', 'girl1'],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton(
    String label,
    String icon,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 5),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedStatsCard(
    int level,
    int xp,
    double percent,
    Map<String, dynamic> data,
  ) {
    int totalXp = data['xp'] ?? 0;
    int timeBalance = data['timeBalance'] ?? 0;

    return Container(
      // 👈 حاشیه و فاصله‌های داخلی کادر اصلی
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFFFCA28), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🔝 ردیف بالا: نمایش XP و زمان
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text("🔥", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    "$totalXp XP",
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                height: 14,
                width: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                color: Colors.orangeAccent.withOpacity(0.5),
              ),
              Row(
                children: [
                  const Text("⏱️", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    "$timeBalance Min",
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10), // 👈 فاصله بین ردیف بالا و نوار پیشرفت
          // ⬇️ ردیف پایین: نوار پیشرفت Daily Goal
          Row(
            children: [
              const Text("🌟", style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                "Goal:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 203, 110, 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            height: 8,
                            width: constraints.maxWidth * percent,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 132, 200, 22),
                                  Color.fromARGB(255, 29, 154, 75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$xp / 100",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 منوی ۵ دکمه‌ای آپدیت شده (این قسمت دقیقاً همون چیزیه که خواستی)
  Widget _buildGameStations() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/bg_Reward.png', // دقت کن که عکس جدید رو جایگزین این فایل کرده باشی
              width: double.infinity,
              fit: BoxFit.contain,
            ),
            Positioned.fill(
              child: Row(
                children: [
                  // ۱. Library
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _openLibrary();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // ۲. Math Quest
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _openMathGame();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // ۳. Memory Match
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _openGames();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // ۴. Academy (دکمه جدید)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _openAcademy();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // ۵. Top Heroes
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreasureSection(int balance) {
    bool canUnlock = balance >= 10;
    String chestImage = canUnlock
        ? 'assets/images/treasure_open_chest.png'
        : 'assets/images/treasure_close_chest.png';

    return GestureDetector(
      onTap: () {
        if (canUnlock) {
          HapticFeedback.mediumImpact();
          _useTime();
        } else {
          HapticFeedback.vibrate();
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 8),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.asset(
                chestImage,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 250, color: Colors.grey.shade800),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    canUnlock ? "Ready to Open!" : "Need ${10 - balance} min",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProHomeworkMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Homework Menu',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Creative Studio",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "How would you like to start?",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),

                        _buildProDialogOption(
                          title: "Blank Notebook",
                          subtitle: "Start fresh on a clean page",
                          icon: Icons.edit_document,
                          color: const Color(0xFF22C55E),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaperSelectorScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildProDialogOption(
                          title: "Scan Homework",
                          subtitle: "Take a photo of your paper",
                          icon: Icons.camera_alt_rounded,
                          color: const Color(0xFF3B82F6),
                          onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            final XFile? photo = await ImagePicker().pickImage(
                              source: ImageSource.camera,
                            );
                            if (photo != null) {
                              final bytes = await photo.readAsBytes();
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => HomeworkSolverScreen(
                                    fileName: photo.name,
                                    filePath: photo.path,
                                    fileBytes: bytes,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildProDialogOption(
                          title: "Upload Document",
                          subtitle: "PDF, JPG, or PNG files",
                          icon: Icons.file_upload_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            fp.FilePickerResult? result =
                                await fp.FilePicker.pickFiles(
                                  type: fp.FileType.custom,
                                  allowedExtensions: [
                                    'pdf',
                                    'jpg',
                                    'jpeg',
                                    'png',
                                  ],
                                  withData: true,
                                );
                            if (result != null) {
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => HomeworkSolverScreen(
                                    fileName: result.files.single.name,
                                    filePath: result.files.single.path,
                                    fileBytes: result.files.single.bytes,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProDialogOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white24,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDailyMissionsMenu() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Daily Missions',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Text(
                            "🎯",
                            style: TextStyle(fontSize: 45),
                          ),
                        ).animate().scale(
                          delay: 100.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Daily Quests",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ).animate().fade(delay: 200.ms).slideY(begin: -0.2),
                        const SizedBox(height: 5),
                        const Text(
                          "Complete tasks to earn magical XP! ✨",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ).animate().fade(delay: 300.ms),
                        const SizedBox(height: 30),

                        _buildProMissionItem(
                          title: "Read 1 Book",
                          icon: "📚",
                          xpReward: 20,
                          isCompleted: false,
                          color: const Color(0xFF3B82F6),
                          onTap: () {
                            Navigator.pop(context);
                            _openLibrary();
                          },
                        ).animate().fade(delay: 400.ms).slideX(begin: -0.1),
                        const SizedBox(height: 15),
                        _buildProMissionItem(
                          title: "Play Memory Match",
                          icon: "🧠",
                          xpReward: 15,
                          isCompleted: false,
                          color: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.pop(context);
                            _openGames();
                          },
                        ).animate().fade(delay: 500.ms).slideX(begin: -0.1),
                        const SizedBox(height: 15),
                        _buildProMissionItem(
                          title: "Solve 5 Math Quests",
                          icon: "➕",
                          xpReward: 30,
                          isCompleted: false,
                          color: const Color(0xFFEC4899),
                          onTap: () {
                            Navigator.pop(context);
                            _openMathGame();
                          },
                        ).animate().fade(delay: 600.ms).slideX(begin: -0.1),
                        const SizedBox(height: 35),

                        GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Awesome! 🚀",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fade(delay: 700.ms)
                            .scale(curve: Curves.easeOutBack),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProMissionItem({
    required String title,
    required String icon,
    required int xpReward,
    required bool isCompleted,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isCompleted) {
          HapticFeedback.selectionClick();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.white.withOpacity(0.02)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? Colors.white.withOpacity(0.05)
                : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isCompleted
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.white.withOpacity(0.05)
                    : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isCompleted ? Colors.white38 : Colors.white,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      "+$xpReward XP 🔥",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? Colors.green : color),
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted ? Colors.green : color).withOpacity(
                      0.4,
                    ),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: isCompleted ? Colors.greenAccent : Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

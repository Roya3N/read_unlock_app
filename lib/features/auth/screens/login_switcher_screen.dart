import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/child/screens/parent_signup_screen.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';
import 'login_screen.dart';

class LoginSwitcherScreen extends StatelessWidget {
  const LoginSwitcherScreen({super.key});

  final Color darkGalaxy = const Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          // 🌌 هاله‌های کهکشانی پس‌زمینه
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlowOrb(const Color(0xFF8B5CF6), 300),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _buildGlowOrb(const Color(0xFFF59E0B), 300),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // عنوان صفحه
                  const Text(
                    "Who is exploring today?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: -0.5),
                  const SizedBox(height: 10),
                  const Text(
                    "Choose your portal to enter the galaxy",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fade(delay: 200.ms),

                  const SizedBox(height: 40),

                  // --- 🛡️ پورتال والدین (Parent Section) ---
                  Expanded(
                    child: _buildPortalCard(
                      context: context,
                      title: "Parent Portal",
                      subtitle: "Manage kids, settings & progress",
                      icon: Icons.admin_panel_settings_rounded,
                      glowColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        AppState.isGuest = false; // 👈 خروج از حالت مهمان
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) =>
                                const LoginScreen(),
                            transitionsBuilder: (context, anim1, anim2, child) {
                              return FadeTransition(
                                opacity: anim1,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      extraWidget: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentSignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "New here? Sign Up",
                          style: TextStyle(
                            color: Color(0xFFD8B4FE),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 300.ms).slideX(begin: -0.2),
                  ),

                  const SizedBox(height: 25),

                  // --- 🚀 پورتال مهمان (Guest Section) ---
                  Expanded(
                    child: _buildPortalCard(
                      context: context,
                      title: "Try as Guest", // 👈 تغییر نام دکمه
                      subtitle:
                          "Play games and read books for free!", // 👈 تغییر زیرنویس
                      icon: Icons.rocket_launch_rounded,
                      glowColor: const Color(0xFFF59E0B),
                      onTap: () {
                        HapticFeedback.heavyImpact();

                        // 🔥 فعال کردن حالت مهمان در حافظه موقت
                        AppState.isGuest = true;

                        // 🚀 انتقال مستقیم به داشبورد بدون نیاز به لاگین
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ).animate().fade(delay: 500.ms).slideX(begin: 0.2),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ویجت سازنده هاله‌های نوری
  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 150)],
      ),
    );
  }

  // ویجت سازنده کارت‌های پورتال شیشه‌ای
  Widget _buildPortalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color glowColor,
    required VoidCallback onTap,
    Widget? extraWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24).withOpacity(0.6),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: glowColor.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: glowColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: glowColor.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 60, color: Colors.white),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scaleXY(
                      end: 1.05,
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: glowColor.withOpacity(0.9),
                    shadows: [
                      Shadow(color: glowColor.withOpacity(0.5), blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (extraWidget != null) ...[
                  const SizedBox(height: 10),
                  extraWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/features/admin/screens/seed_service.dart';
import 'admin_config_screen.dart';
import 'admin_uploader_screen.dart';
import 'admin_words_screen.dart';
import 'admin_users_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_global_config_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  final Color darkGalaxy = const Color(0xFF0D0D17);
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color matrixGreen = const Color(0xFF10B981);
  final Color radarOrange = const Color(0xFFF59E0B);
  final Color cyberBlue = const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          // 🌌 Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlowOrb(primaryNeon, 300),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _buildGlowOrb(matrixGreen, 250),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    children: [
                      // 🧠 Smart Database Injector (All-in-One)
                      _buildAdminTile(
                        title: "Smart Injector",
                        subtitle: "Auto-detect & Seed",
                        icon: Icons
                            .auto_awesome_mosaic_rounded, // یه آیکون هوشمندانه
                        color: Colors.tealAccent,
                        onTap: () async {
                          _showLoading(context); // نمایش لودینگ

                          // 🔥 فراخوانی موتور تزریق هوشمند (جفتش رو اتوماتیک چک و تزریق می‌کنه)
                          await SeedService.smartSeed();

                          if (context.mounted) {
                            Navigator.pop(context); // بستن لودینگ
                            _showSuccess(context); // نمایش پیام موفقیت
                          }
                        },
                      ),
                      _buildAdminTile(
                        title: "Book Injector",
                        subtitle: "Upload Stories",
                        icon: Icons.auto_stories_rounded,
                        color: matrixGreen,
                        onTap: () =>
                            _navigate(context, const AdminBookUploader()),
                      ),
                      _buildAdminTile(
                        title: "Word Injector",
                        subtitle: "Game Content",
                        icon: Icons.abc_rounded,
                        color: primaryNeon,
                        onTap: () =>
                            _navigate(context, const AdminWordsScreen()),
                      ),
                      _buildAdminTile(
                        title: "User Radar",
                        subtitle: "Manage Players",
                        icon: Icons.radar_rounded,
                        color: radarOrange,
                        onTap: () =>
                            _navigate(context, const AdminUsersScreen()),
                      ),
                      _buildAdminTile(
                        title: "Economy Config",
                        subtitle: "Prices & Rewards",
                        icon: Icons.settings_suggest_rounded,
                        color: cyberBlue,
                        onTap: () =>
                            _navigate(context, const AdminConfigScreen()),
                      ),
                      _buildAdminTile(
                        title: "System Logs",
                        subtitle: "Error Tracking",
                        icon: Icons.terminal_rounded,
                        color: Colors.redAccent,
                        onTap: () => _navigate(context, AdminLogsScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ Helpers for PRO feel
  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CircularProgressIndicator(color: primaryNeon),
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Database Seeded Successfully! 🔥",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: matrixGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
          ),
          const SizedBox(height: 20),
          const Text(
            "Central Intelligence 🛰️",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Master Control & Data Injection",
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    ).animate().fade().slideX();
  }

  Widget _buildAdminTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(delay: 2.seconds),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(curve: Curves.easeOutBack);
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

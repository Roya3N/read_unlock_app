import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final Color bgDark = const Color(0xFF0D0D17);
  final Color cyberBlue = const Color(0xFF3B82F6);
  final Color premiumGold = const Color(0xFFFBBF24);
  final Color alertRed = const Color(0xFFEF4444);
  final Color successGreen = const Color(0xFF10B981);

  // کنترلرهای مقادیر اقتصاد بازی
  final TextEditingController _bookXpController = TextEditingController();
  final TextEditingController _quizXpController = TextEditingController();
  final TextEditingController _minuteCostController = TextEditingController();

  // کنترلرهای جدید برای هدایا
  final TextEditingController _dailyLoginController = TextEditingController();
  final TextEditingController _welcomeBonusController = TextEditingController();

  // سوئیچ توقف اضطراری
  bool _isMaintenanceMode = false;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEconomyConfig();
  }

  // 📥 خواندن اطلاعات از فایربیس
  Future<void> _loadEconomyConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('economy')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _bookXpController.text = (data['book_reward_xp'] ?? 50).toString();
        _quizXpController.text = (data['quiz_reward_xp'] ?? 10).toString();
        _minuteCostController.text = (data['minute_cost_xp'] ?? 5).toString();
        _dailyLoginController.text = (data['daily_login_xp'] ?? 20).toString();
        _welcomeBonusController.text = (data['welcome_bonus_xp'] ?? 100)
            .toString();
        _isMaintenanceMode = data['maintenance_mode'] ?? false;
      } else {
        // مقادیر پیش‌فرض
        _bookXpController.text = "50";
        _quizXpController.text = "10";
        _minuteCostController.text = "5";
        _dailyLoginController.text = "20";
        _welcomeBonusController.text = "100";
        _isMaintenanceMode = false;
      }
    } catch (e) {
      debugPrint("Error loading config: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 📤 ذخیره اطلاعات در فایربیس
  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      await FirebaseFirestore.instance.collection('config').doc('economy').set({
        'book_reward_xp': int.tryParse(_bookXpController.text) ?? 50,
        'quiz_reward_xp': int.tryParse(_quizXpController.text) ?? 10,
        'minute_cost_xp': int.tryParse(_minuteCostController.text) ?? 5,
        'daily_login_xp': int.tryParse(_dailyLoginController.text) ?? 20,
        'welcome_bonus_xp': int.tryParse(_welcomeBonusController.text) ?? 100,
        'maintenance_mode': _isMaintenanceMode,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Global Systems Updated! 🚀",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving config: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _bookXpController.dispose();
    _quizXpController.dispose();
    _minuteCostController.dispose();
    _dailyLoginController.dispose();
    _welcomeBonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Global Config ⚙️",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cyberBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("⚠️ SYSTEM SECURITY"),
                  _buildMaintenanceSwitch(),
                  const SizedBox(height: 30),

                  _buildSectionTitle("🎁 GIFTS & REWARDS"),
                  _buildConfigField(
                    title: "Welcome Bonus",
                    subtitle: "XP given when a new child profile is created",
                    icon: Icons.card_giftcard_rounded,
                    controller: _welcomeBonusController,
                    color: successGreen,
                  ),
                  const SizedBox(height: 15),
                  _buildConfigField(
                    title: "Daily Login Reward",
                    subtitle: "XP given for opening the app every day",
                    icon: Icons.today_rounded,
                    controller: _dailyLoginController,
                    color: cyberBlue,
                  ),
                  const SizedBox(height: 30),

                  _buildSectionTitle("📚 CORE ECONOMY"),
                  _buildConfigField(
                    title: "Book Completion",
                    subtitle: "XP given when a book is finished",
                    icon: Icons.auto_stories_rounded,
                    controller: _bookXpController,
                    color: premiumGold,
                  ),
                  const SizedBox(height: 15),
                  _buildConfigField(
                    title: "Quiz Correct Answer",
                    subtitle: "XP given per correct quiz answer",
                    icon: Icons.quiz_rounded,
                    controller: _quizXpController,
                    color: premiumGold,
                  ),
                  const SizedBox(height: 15),
                  _buildConfigField(
                    title: "Time Cost Multiplier",
                    subtitle: "XP cost per 1 minute of screen time",
                    icon: Icons.timer_rounded,
                    controller: _minuteCostController,
                    color: alertRed,
                  ),

                  const SizedBox(height: 40),

                  // دکمه ذخیره
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cyberBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 10,
                        shadowColor: cyberBlue.withOpacity(0.5),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "DEPLOY TO SERVERS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ).animate().scale(delay: 200.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMaintenanceSwitch() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isMaintenanceMode
                ? alertRed.withOpacity(0.15)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isMaintenanceMode
                  ? alertRed.withOpacity(0.5)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alertRed.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.build_rounded, color: alertRed),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Maintenance Mode",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _isMaintenanceMode
                          ? "App is currently LOCKED for users"
                          : "App is LIVE and running normally",
                      style: TextStyle(
                        color: _isMaintenanceMode ? alertRed : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isMaintenanceMode,
                activeColor: alertRed,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _isMaintenanceMode = value);
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildConfigField({
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/features/auth/controllers/auth_controller.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController();
  final AuthController _authController = AuthController();

  int _currentStep = 0;
  String _selectedAge = 'kids';

  // 🎨 رنگ‌های تم Pro
  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color glassBg = const Color(0xFF1E1E24).withOpacity(0.6);

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep == 0 && _parentNameController.text.isEmpty) {
      _showError("Please enter your name 🌌");
      return;
    }
    if (_currentStep == 1 && _pinController.text.length < 4) {
      _showError("PIN must be at least 4 characters 🔒");
      return;
    }

    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _finishSetup() async {
    HapticFeedback.heavyImpact();
    if (_childNameController.text.isEmpty) {
      _showError("Please enter your explorer's name 🚀");
      return;
    }

    // 🔥 کار رو می‌سپاریم به کنترلر (این متد خودش AppState رو هم آپدیت می‌کنه)
    bool success = await _authController.setupParentAccount(
      parentName: _parentNameController.text.trim(),
      pin: _pinController.text.trim(),
      childName: _childNameController.text.trim(),
      ageGroup: _selectedAge,
    );

    // بررسی نتیجه کار کنترلر
    if (success) {
      if (!mounted) return;
      // اگه موفق بود مستقیم میره داشبورد
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      // اگه ارور داد (مثلاً نتونست تو دیتابیس ذخیره کنه) ارور رو نشون میده
      _showError(_authController.errorMessage);
    }
  }

  void _showError(String msg) {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          // 🌌 هاله‌های نوری معلق
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowOrb(primaryNeon, 300),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildGlowOrb(accentBlue, 250),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 📊 نشانگر پیشرفت نئونی (Neon Progress Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = _currentStep == index;
                      final isPassed = _currentStep > index;
                      final color = isPassed || isActive
                          ? primaryNeon
                          : Colors.white.withOpacity(0.1);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 30 : 10,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive || isPassed
                              ? [
                                  BoxShadow(
                                    color: primaryNeon.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                      );
                    }),
                  ).animate().fade(duration: 500.ms).slideY(begin: -1),

                  const SizedBox(height: 40),

                  // 📱 محتوای اصلی (ترانزیشن صفحات)
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildParentStep(),
                        _buildPinStep(),
                        _buildChildStep(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🌟 مراحل تنظیمات ---

  Widget _buildParentStep() {
    return _buildStepContainer(
      title: "Welcome! 👋",
      subtitle: "First, let's set up the Parent Account.",
      icon: Icons.supervisor_account_rounded,
      content: _buildGlassInput(
        controller: _parentNameController,
        hint: "Your Name (Parent)",
        icon: Icons.person_outline_rounded,
      ),
      buttonText: "Continue",
      onTap: _nextStep,
    );
  }

  Widget _buildPinStep() {
    return _buildStepContainer(
      title: "Security 🔐",
      subtitle: "Create a PIN or Password for parent settings.",
      icon: Icons.security_rounded,
      content: _buildGlassInput(
        controller: _pinController,
        hint: "Enter Password / PIN",
        icon: Icons.lock_outline_rounded,
        isObscured: true,
      ),
      buttonText: "Set Security",
      onTap: _nextStep,
    );
  }

  Widget _buildChildStep() {
    return _buildStepContainer(
      title: "Add Explorer 🚀",
      subtitle: "Who will be using this app to learn?",
      icon: Icons.child_care_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassInput(
            controller: _childNameController,
            hint: "Explorer's Name",
            icon: Icons.rocket_launch_rounded,
          ),
          const SizedBox(height: 30),
          const Text(
            "Select Age Group:",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildAgeCard('kids', 'Kids', '👦')),
              const SizedBox(width: 10),
              Expanded(child: _buildAgeCard('teen', 'Teen', '🧑')),
              const SizedBox(width: 10),
              Expanded(child: _buildAgeCard('adult', 'Adult', '👨')),
            ],
          ),
        ],
      ),
      buttonText: "Start Learning! ✨",
      onTap: _finishSetup,
    );
  }

  // --- 🛠️ ویجت‌های سازنده (Builders) ---

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget content,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: primaryNeon.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: primaryNeon.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 40, color: primaryNeon),
        ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ).animate().fade(delay: 200.ms).slideX(),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fade(delay: 300.ms),
        const SizedBox(height: 40),

        content.animate().fade(delay: 400.ms).slideY(begin: 0.1),

        const Spacer(),

        _buildProButton(
          text: buttonText,
          onTap: onTap,
        ).animate().fade(delay: 500.ms).scale(),
      ],
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscured = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          obscureText: isObscured,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeCard(String value, String title, String emoji) {
    bool isSelected = _selectedAge == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAge = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? accentBlue.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentBlue : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accentBlue.withOpacity(0.3), blurRadius: 15)]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryNeon, const Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryNeon.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

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
}

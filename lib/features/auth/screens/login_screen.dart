import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 ایمپورت جدید برای خواندن تنظیمات
import 'package:read_unlock_app/features/child/screens/parent_signup_screen.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:read_unlock_app/services/app_logger.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // 🎨 رنگ‌های تم Pro
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color darkGalaxy = const Color(0xFF1A1A2E);

  // متد ورود
  Future<void> _handleLogin() async {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // ==========================================
      // 🛑 قفل توقف اضطراری (Maintenance Mode Check)
      // ==========================================
      try {
        final configDoc = await FirebaseFirestore.instance
            .collection('config')
            .doc('economy')
            .get();
        if (configDoc.exists) {
          final isMaintenance = configDoc.data()?['maintenance_mode'] ?? false;
          final userEmail = _emailController.text.trim();

          // اگر اپلیکیشن در حالت تعمیره و کسی که داره لاگین می‌کنه ادمین نیست:
          if (isMaintenance && userEmail != "roya3n@gmail.com") {
            // ⭐️ این خط رو دقیقاً اینجا اضافه کن:
            AppLogger.warning(
              "Blocked login attempt due to maintenance: $userEmail",
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.build_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "App is under maintenance! We'll be back soon. 🛠️",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFF59E0B), // رنگ نارنجی هشدار
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            }
            setState(() => _isLoading = false);
            return; // ⛔️ همینجا عملیات لاگین رو متوقف کن و پایین‌تر نرو
          }
        }
      } catch (e) {
        // به جای اینکه فقط تو گوشی پرینت بشه، الان مستقیم میره تو داشبورد ادمینت!
        AppLogger.error("Failed to check Maintenance Mode", e);
      }
      // ==========================================

      // اگر از قفل رد شد، پروسه لاگین عادی رو ادامه بده
      final result = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result == null) {
        AppLogger.info(
          "Admin/Parent logged in successfully: ${_emailController.text.trim()}",
        );
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        _showProSnackBar(result, isError: true);
      }
    }
  }

  // متد فراموشی رمز عبور
  Future<void> _handleForgotPassword() async {
    HapticFeedback.lightImpact();
    if (_emailController.text.isEmpty) {
      _showProSnackBar(
        "Please enter your email first to reset password. 📧",
        isError: true,
      );
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());
      _showProSnackBar("Reset link sent! Check your inbox. ✨");
    } catch (e) {
      _showProSnackBar("Error sending reset email. ❌", isError: true);
    }
  }

  // اسنک‌بار شیشه‌ای و حرفه‌ای
  void _showProSnackBar(String message, {bool isError = false}) {
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
          // 🌌 هاله‌های نورانی کهکشان
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlowOrb(primaryNeon, 350),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildGlowOrb(const Color(0xFF3B82F6), 250),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // آیکون قفل شیشه‌ای
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNeon.withOpacity(0.2),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_person_rounded,
                        size: 80,
                        color: primaryNeon,
                      ),
                    ).animate().scale(
                      curve: Curves.easeOutBack,
                      duration: 800.ms,
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: 8),

                    const Text(
                      "Login to manage your child's progress",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2),

                    const SizedBox(height: 40),

                    // فیلد ایمیل
                    _buildProTextField(
                      controller: _emailController,
                      hint: "Email Address",
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fade(delay: 400.ms).slideX(begin: -0.1),

                    const SizedBox(height: 20),

                    // فیلد پسورد
                    _buildProTextField(
                      controller: _passwordController,
                      hint: "Password",
                      icon: Icons.vpn_key_rounded,
                      isPassword: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          );
                        },
                      ),
                    ).animate().fade(delay: 500.ms).slideX(begin: 0.1),

                    // دکمه فراموشی رمز عبور
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: primaryNeon.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 600.ms),

                    const SizedBox(height: 30),

                    // دکمه ورود
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          )
                        : GestureDetector(
                                onTap: _handleLogin,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF6D28D9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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

                    const SizedBox(height: 25),

                    // لینک ثبت نام
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white54),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ParentSignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: primaryNeon,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 800.ms),
                  ],
                ),
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

  // فیلد متنی شیشه‌ای (Glassmorphism)
  Widget _buildProTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.white54),
            suffixIcon: suffixIcon,
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
              borderSide: BorderSide(color: primaryNeon, width: 2),
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
      ),
    );
  }
}

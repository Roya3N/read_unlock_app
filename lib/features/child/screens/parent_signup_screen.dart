import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/features/auth/services/auth_service.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';

class ParentSignupScreen extends StatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  State<ParentSignupScreen> createState() => _ParentSignupScreenState();
}

class _ParentSignupScreenState extends State<ParentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0; // 0: Info, 1: Verification Info, 2: Password
  double _passwordStrength = 0.0; // برای نوار قدرت رمز

  // 🎨 رنگ‌های تم Pro
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color glassBg = const Color(0xFF1E1E24).withOpacity(0.6);

  @override
  void initState() {
    super.initState();
    // لیسنر برای محاسبه قدرت رمز عبور
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String pass = _passwordController.text;
    double strength = 0;
    if (pass.length > 5) strength += 0.25;
    if (pass.length > 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pass)) strength += 0.25;
    if (RegExp(r'[0-9!@#\$&*~]').hasMatch(pass)) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
    });
  }

  // انتخاب تاریخ تولد (با استایل دارک)
  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryNeon,
              onPrimary: Colors.white,
              surface: const Color(0xFF2A2A35),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}/${picked.month}/${picked.day}";
      });
    }
  }

  // مدیریت مراحل با اعتبار‌سنجی
  void _handleNext() {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _createAccount();
      }
    }
  }

  // منطق ثبت‌نام
  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showProSnackBar("Passwords do not match! 🔒", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUpParent(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        dob: _dobController.text.trim(),
      );

      if (result == null) {
        if (!mounted) return;
        _showProSnackBar("Account created! Check your email. 🚀");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        _showProSnackBar(result, isError: true);
      }
    } catch (e) {
      _showProSnackBar("An unexpected error occurred. 📡", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryNeon.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryNeon.withOpacity(0.3),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🌟 هدر
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Parent Portal',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 📊 نوار پیشرفت نئونی
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  child: _buildProProgressIndicator(),
                ),

                // 📝 فرم اصلی
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // محتوای مرحله
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            child: _buildCurrentStepView(),
                          ),

                          const SizedBox(height: 40),

                          // دکمه مرحله بعد / ثبت‌نام
                          _isLoading
                              ? const CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                )
                              : GestureDetector(
                                  onTap: _handleNext,
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
                                    child: Center(
                                      child: Text(
                                        _currentStep == 2
                                            ? "Launch Adventure 🚀"
                                            : "Continue",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ).animate().scale(delay: 200.ms),

                          const SizedBox(height: 25),

                          // لینک ورود
                          if (!_isLoading)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Log In",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fade(delay: 300.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // نوار پیشرفت حرفه‌ای
  Widget _buildProProgressIndicator() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentStep >= index
                  ? primaryNeon
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _currentStep >= index
                  ? [
                      BoxShadow(
                        color: primaryNeon.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep().animate().fade().slideX();
      case 1:
        return _buildEmailVerificationInfoStep().animate().fade().slideX();
      case 2:
        return _buildPasswordStep().animate().fade().slideX();
      default:
        return const SizedBox.shrink();
    }
  }

  // مرحله ۱
  Widget _buildPersonalInfoStep() {
    return Column(
      key: const ValueKey(0),
      children: [
        _buildProTextField(_nameController, "Full Name", Icons.person_rounded),
        const SizedBox(height: 20),
        _buildProTextField(
          _emailController,
          "Gmail Address",
          Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: _buildProTextField(
              _dobController,
              "Date of Birth",
              Icons.calendar_month_rounded,
            ),
          ),
        ),
      ],
    );
  }

  // مرحله ۲
  Widget _buildEmailVerificationInfoStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 80,
            color: Color(0xFF4ADE80),
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
        const SizedBox(height: 30),
        const Text(
          "Verify Your Identity",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "For your child's security, we will send a verification link to your Gmail after you create your password.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white54, height: 1.5),
        ),
      ],
    );
  }

  // مرحله ۳
  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey(2),
      children: [
        _buildProTextField(
          _passwordController,
          "Password",
          Icons.lock_rounded,
          isPassword: true,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white54,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordStrengthBar(), // 👈 نوار قدرت رمز
        const SizedBox(height: 20),
        _buildProTextField(
          _confirmPasswordController,
          "Confirm Password",
          Icons.lock_outline_rounded,
          isPassword: true,
          validator: (val) {
            if (val!.isEmpty) return "Required";
            if (val != _passwordController.text) return "Passwords don't match";
            return null;
          },
        ),
      ],
    );
  }

  // نشانگر قدرت رمز عبور
  Widget _buildPasswordStrengthBar() {
    Color getStrengthColor() {
      if (_passwordStrength <= 0.25) return Colors.redAccent;
      if (_passwordStrength <= 0.5) return Colors.orangeAccent;
      if (_passwordStrength <= 0.75) return Colors.yellowAccent;
      return Colors.greenAccent;
    }

    String getStrengthText() {
      if (_passwordStrength == 0) return "Enter password";
      if (_passwordStrength <= 0.25) return "Weak";
      if (_passwordStrength <= 0.5) return "Fair";
      if (_passwordStrength <= 0.75) return "Good";
      return "Strong";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(height: 6, color: Colors.white.withOpacity(0.1)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    width:
                        MediaQuery.of(context).size.width * _passwordStrength,
                    decoration: BoxDecoration(
                      color: getStrengthColor(),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: getStrengthColor().withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 80,
            child: Text(
              getStrengthText(),
              style: TextStyle(
                color: getStrengthColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // فیلد متنی شیشه‌ای (Glassmorphism)
  Widget _buildProTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
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
          validator:
              validator ??
              (val) => val!.isEmpty ? "This field is required" : null,
        ),
      ),
    );
  }
}

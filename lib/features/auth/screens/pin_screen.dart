import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../controllers/auth_controller.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;

  const PinScreen({super.key, this.isSetup = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _controller = TextEditingController();
  final AuthController _authController = AuthController();

  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _authController.checkSecurityStatus(forceSetup: widget.isSetup);
  }

  void _submit() async {
    HapticFeedback.mediumImpact();

    // ارسال رمز به کنترلر برای تایید
    bool success = await _authController.submitPin(_controller.text.trim());

    if (success && mounted) {
      Navigator.pop(context, true); // ورود موفق!
    } else {
      HapticFeedback.heavyImpact(); // ویبره خطا
      setState(() {
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, child) {
        if (_authController.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Stack(
            children: [
              // 🎨 افکت‌های نوری پس‌زمینه
              Positioned(
                top: -100,
                right: -100,
                child: _buildGlowOrb(const Color(0xFF8B5CF6)),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: _buildGlowOrb(const Color(0xFF3B82F6)),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // آیکون نئونی بالای صفحه
                            _buildNeonIcon().animate().scale(
                              curve: Curves.easeOutBack,
                              duration: 600.ms,
                            ),

                            const SizedBox(height: 30),

                            // عنوان صفحه
                            Text(
                              _authController.isLockedOut
                                  ? 'Access Blocked'
                                  : (_authController.isSetupMode
                                        ? 'Security Setup'
                                        : 'Parent Access'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _authController.isLockedOut
                                    ? Colors.redAccent
                                    : Colors.white,
                                letterSpacing: 1,
                              ),
                            ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

                            const SizedBox(height: 10),

                            Text(
                              _authController.isLockedOut
                                  ? 'Security measure activated'
                                  : 'Use letters, numbers, and symbols',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().fade(delay: 300.ms),

                            const SizedBox(height: 50),

                            // باکس اخطار مسدودی (اگر قفل شده باشه)
                            if (_authController.isLockedOut)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 25,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.timer_off_rounded,
                                      color: Colors.redAccent,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _authController.lockoutMessage,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fade().shake()
                            else ...[
                              // ⌨️ فیلد ورود رمز شیشه‌ای (برگشت به همون زیبایی قبل)
                              _buildGlassInput()
                                  .animate()
                                  .fade(delay: 400.ms)
                                  .slideX(),

                              // نمایش ارور (مثلاً رمز اشتباه است)
                              if (_authController.errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    _authController.errorMessage,
                                    style: const TextStyle(
                                      color: Color(0xFFF87171),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ).animate().shake(),
                                ),

                              const SizedBox(height: 40),

                              // دکمه تایید نئونی
                              _buildConfirmButton()
                                  .animate()
                                  .fade(delay: 500.ms)
                                  .scale(),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // دکمه بازگشت
              Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 🎨 بخش ویجت‌های UI (بدون تغییر منطق)
  // ==========================================

  Widget _buildNeonIcon() {
    final color = _authController.isLockedOut
        ? Colors.redAccent
        : const Color(0xFF60A5FA);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 30)],
      ),
      child: Icon(
        _authController.isLockedOut
            ? Icons.block_rounded
            : (_authController.isSetupMode
                  ? Icons.security_rounded
                  : Icons.lock_outline_rounded),
        size: 50,
        color: color,
      ),
    );
  }

  Widget _buildGlassInput() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _controller,
            obscureText: _isObscured,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'Enter Password',
              hintStyle: const TextStyle(
                color: Colors.white24,
                letterSpacing: 0,
              ),
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isObscured = !_isObscured);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'CONFIRM ACCESS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowOrb(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 100)],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _authController.dispose();
    super.dispose();
  }
}

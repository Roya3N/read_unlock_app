import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:read_unlock_app/core/services/audio_service.dart';

class GalaxyLuckySpin extends StatefulWidget {
  final VoidCallback onSpinComplete;
  final Function(int rewardAmount) onRewardDetermined;

  const GalaxyLuckySpin({
    super.key,
    required this.onSpinComplete,
    required this.onRewardDetermined,
  });

  @override
  State<GalaxyLuckySpin> createState() => _GalaxyLuckySpinState();
}

class _GalaxyLuckySpinState extends State<GalaxyLuckySpin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isSpinning = false;
  double _currentRotation = 0.0;

  // 🎯 Map the segments of YOUR image to actual rewards.
  // Assuming 10 slices based on the image provided. Adjust values as needed.
  final List<int> _rewards = [50, 10, 5, 50, 15, 50, 50, 5, 25, 50];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Duration of the spin
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    HapticFeedback.heavyImpact();
    // Play a spinning sound here if you have one
    // AudioService.playSpinSound();

    // 1. Calculate random outcome
    final random = Random();
    // Number of full rotations (between 3 and 6)
    final fullRotations = (random.nextInt(4) + 3) * 2 * pi;
    // Random slice to land on
    final randomSliceIndex = random.nextInt(_rewards.length);

    // Calculate the angle for the specific slice.
    // We add an offset to ensure the pointer lands in the *middle* of the slice.
    final sliceAngle = (2 * pi) / _rewards.length;
    final landingAngle = (randomSliceIndex * sliceAngle) + (sliceAngle / 2);

    final totalRotation = fullRotations + landingAngle;

    // 2. Set up the animation
    _animation =
        Tween<double>(
          begin: _currentRotation,
          end: _currentRotation + totalRotation,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve:
                Curves.fastOutSlowIn, // Starts fast, slows down realistically
          ),
        );

    _animation.addListener(() {
      setState(() {});
      // Optional: Add light haptics during the spin to simulate "clicks"
      // if (_controller.value % 0.1 < 0.01) HapticFeedback.selectionClick();
    });

    _controller.forward(from: 0.0).then((_) {
      // 3. Spin complete
      setState(() {
        _isSpinning = false;
        _currentRotation =
            _animation.value % (2 * pi); // Keep rotation within 0-360 deg
      });

      // Determine the winner based on where it landed.
      // Since the wheel rotates clockwise, the top pointer is actually hitting
      // the slice that is rotated *backwards* from the top.
      final normalizedRotation = (2 * pi) - _currentRotation;
      final winningIndex =
          (normalizedRotation / sliceAngle).floor() % _rewards.length;

      final reward = _rewards[winningIndex];

      HapticFeedback.heavyImpact();
      AudioService.playReward(); // Play winning sound

      widget.onRewardDetermined(reward);

      // Add a slight delay before closing or showing next step
      Future.delayed(const Duration(milliseconds: 800), widget.onSpinComplete);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24).withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFFBBF24).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Galaxy Spin! 🎡",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You completed your daily missions!\nSpin to win bonus XP.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // 🎡 The Wheel Mechanism
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // The Rotating Image
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20.0,
                      ), // Space for pointer
                      child: Transform.rotate(
                        angle: _animation.value,
                        child: Image.asset(
                          'assets/Spine_Wheel.jpg', // 👈 Update path if needed
                          width: 250,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // The Pointer (Static at the top)
                    // You might need to adjust this depending on if your image
                    // already includes the top star pointer baked into the background.
                    // If the image HAS the pointer, we need to crop it or use a different
                    // approach. Assuming the image is JUST the wheel for this example.
                    const Icon(
                      Icons.arrow_drop_down_circle_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 🔘 Spin Button
                GestureDetector(
                  onTap: _isSpinning ? null : _spinWheel,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSpinning
                            ? [Colors.grey.shade600, Colors.grey.shade800]
                            : [
                                const Color(0xFFF59E0B),
                                const Color(0xFFD97706),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isSpinning
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        _isSpinning ? "SPINNING..." : "SPIN NOW!",
                        style: TextStyle(
                          color: _isSpinning ? Colors.white54 : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- هدر داشبورد (Dark Galaxy Style) ---
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    this.activeChildName,
  });
  final String userName;
  final String? activeChildName;

  @override
  Widget build(BuildContext context) {
    return Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Hi $userName 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Changed to white
              ),
            ),
            if (activeChildName != null)
              Text(
                '👶 $activeChildName',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF8B5CF6), // Neon Purple
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 15),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, curve: Curves.easeOut);
  }
}

// --- دکمه‌های مخصوص والدین (Glassmorphism Style) ---
class DashboardParentActions extends StatelessWidget {
  const DashboardParentActions({
    super.key,
    required this.isParent,
    required this.onOpenParentPanel,
    required this.onSwitchChild,
  });
  final bool isParent;
  final VoidCallback onOpenParentPanel;
  final VoidCallback onSwitchChild;

  @override
  Widget build(BuildContext context) {
    if (!isParent) return const SizedBox.shrink();
    return Column(
      children: [
        _buildGlassButton(
          '⚙️ Parent Panel',
          const Color(0xFF8B5CF6), // Neon Purple glow
          onOpenParentPanel,
        ),
        const SizedBox(height: 10),
        _buildGlassButton(
          '👶 Switch Child',
          const Color(0xFF3B82F6), // Accent Blue glow
          onSwitchChild,
        ),
        const SizedBox(height: 20),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGlassButton(String text, Color glowColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: 50,
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- بخش موجودی زمان (Glassmorphism Style) ---
class DashboardTimeBalance extends StatelessWidget {
  const DashboardTimeBalance({super.key, required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏳ ', style: TextStyle(fontSize: 28)),
              Text(
                '$minutes min',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white, // Changed to white
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(curve: Curves.elasticOut);
  }
}

// --- آواتار و لول (Dark Theme Style) ---
class DashboardAvatarLevel extends StatelessWidget {
  const DashboardAvatarLevel({
    super.key,
    required this.avatarId,
    required this.level,
    required this.isKid,
    required this.onChangeAvatar,
  });
  final String avatarId;
  final int level;
  final bool isKid;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: isKid ? onChangeAvatar : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                // Replaced outer CircleAvatar with a glowing container
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white12, // Darker inner circle
                  child: CircleAvatar(
                    radius: 42,
                    backgroundImage: AssetImage('assets/avatars/$avatarId.png'),
                  ),
                ),
              ),
              if (isKid)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1A1A2E,
                    ), // Dark background for edit icon
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8B5CF6)),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
            ],
          ),
        ).animate().scale(
          delay: 300.ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        ),
        const SizedBox(height: 10),
        if (isKid)
          const Text(
            'Change Hero',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white54, // Changed to light grey
              fontSize: 12,
            ),
          ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}

// --- دکمه‌های اصلی (Glassmorphism Style) ---
class DashboardMainActions extends StatelessWidget {
  const DashboardMainActions({
    super.key,
    required this.onOpenLeaderboard,
    required this.onOpenLibrary,
    required this.onOpenGames,
    required this.onOpenMathGame,
    required this.onUseTime,
    required this.onLogout,
  });

  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenGames;
  final VoidCallback onOpenMathGame;
  final VoidCallback onUseTime;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 25),
        _buildGlassCard(
          title: "Magic Library",
          subtitle: "Read & Earn Time",
          icon: "📚",
          glowColor: const Color(0xFF4A90E2),
          onTap: onOpenLibrary,
          delay: 0,
        ),
        _buildGlassCard(
          title: "Math Quest",
          subtitle: "Solve & Earn Time",
          icon: "➕",
          glowColor: const Color(0xFFEC4899),
          onTap: onOpenMathGame,
          delay: 100,
        ),
        _buildGlassCard(
          title: "Memory Match",
          subtitle: "Train Your Brain",
          icon: "🧠",
          glowColor: const Color(0xFF4ADE80),
          onTap: onOpenGames,
          delay: 200,
        ),
        _buildGlassCard(
          title: "Leaderboard",
          subtitle: "Top Readers",
          icon: "🏆",
          glowColor: const Color(0xFFF59E0B),
          onTap: onOpenLeaderboard,
          delay: 300,
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          label: const Text(
            "Exit Mode",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildGlassCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color glowColor,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: glowColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: glowColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: glowColor.withOpacity(0.4)),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: glowColor.withOpacity(0.8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms)
        .slideX(begin: 0.1, curve: Curves.easeOut);
  }
}

// --- بخش نشان‌ها (Dark Theme Style) ---
class DashboardBadges extends StatelessWidget {
  const DashboardBadges({super.key, required this.badges});
  final List<String> badges;

  String _badgeText(String badge) {
    switch (badge) {
      case 'first_book':
        return '🥇 First Book';
      case 'streak_3':
        return '🔥 3 Day Streak';
      case 'quiz_master':
        return '🧠 Quiz Master';
      case 'math_genius':
        return '🔢 Math Genius';
      case 'time_60':
        return '⏱️ Time Collector';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text(
            "Achievements",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: badges
                .map(
                  (badge) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _badgeText(badge),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD8B4FE), // Lighter purple text
                        fontSize: 12,
                      ),
                    ),
                  ).animate().scale(curve: Curves.easeOutBack),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DashboardStreak extends StatelessWidget {
  const DashboardStreak({super.key, required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
      ),
      child: Text(
        '🔥 $streak DAY STREAK',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.orangeAccent,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    ).animate().shimmer(delay: 1000.ms, duration: 1500.ms);
  }
}

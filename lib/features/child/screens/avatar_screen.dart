import 'dart:ui'; // For Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import '../data/avatars.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  String? localSelected;
  bool isPurchasing = false;

  Future<void> _handleAvatarTap(
    Map<String, dynamic> avatar,
    int currentLevel,
    int xp, // ⭐️ به جای زمان، اینجا XP رو می‌گیریم
    List<String> unlockedAvatars,
  ) async {
    HapticFeedback.lightImpact();
    final String id = avatar['id'];
    final int cost = avatar['cost'] ?? 0;
    final int reqLevel = avatar['requiredLevel'] ?? 1;
    final String name = avatar['name'] ?? id.toUpperCase();
    final bool isUnlocked = unlockedAvatars.contains(id);

    // ⭐️ ارور لول رو فقط زمانی نشون بده که کاربر این رو هنوز باز نکرده باشه
    if (currentLevel < reqLevel && !isUnlocked) {
      _showProSnackBar(
        "Reach Level $reqLevel to unlock this hero! 🏆",
        Colors.orangeAccent,
      );
      return;
    }

    if (isUnlocked) {
      setState(() => localSelected = id);
      return;
    }

    if (isPurchasing) return;

    // ⭐️ چک می‌کنیم که آیا XP کافی برای خرید داره؟
    if (xp >= cost) {
      final confirm = await _showProConfirmDialog(cost, avatar['image'], name);
      if (confirm != true) return;

      setState(() => isPurchasing = true);

      try {
        // ⭐️ کسر XP و اضافه کردن آواتار مستقیماً در دیتابیس (دقیقاً مثل فروشگاه)
        await AppState.currentChildRef?.update({
          'xp': FieldValue.increment(-cost),
          'unlockedAvatars': FieldValue.arrayUnion([id]),
        });

        if (mounted) {
          setState(() {
            isPurchasing = false;
            localSelected = id;
          });
          _showProSnackBar(
            "New Hero Joined Your Team! 🎉",
            const Color(0xFF4ADE80),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => isPurchasing = false);
          _showProSnackBar("Connection error! 📡", Colors.redAccent);
        }
      }
    } else {
      // ⭐️ پیغام ارور رو برای کمبود XP تغییر دادیم
      _showProSnackBar(
        "Not enough XP! Complete activities! 🔥",
        const Color(0xFFF87171),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 🌌 Galaxy Theme
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.3),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: AppState.currentChildRef == null
                ? const Center(
                    child: Text(
                      "Error: No active explorer found.",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  )
                : StreamBuilder<DocumentSnapshot>(
                    stream: AppState.currentChildRef!.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          ),
                        );
                      if (!snapshot.hasData || !snapshot.data!.exists)
                        return const Center(
                          child: Text(
                            "Data not found.",
                            style: TextStyle(color: Colors.white),
                          ),
                        );

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final int xp = data['xp'] ?? 0;
                      final int currentLevel = (xp ~/ 100) + 1;
                      final int timeBalance = data['timeBalance'] ?? 0;
                      final List<String> unlockedAvatars = List<String>.from(
                        data['unlockedAvatars'] ?? ['boy1'],
                      );
                      final String dbSelected = data['avatar'] ?? 'boy1';
                      final String actualSelected = localSelected ?? dbSelected;

                      return Column(
                        children: [
                          // 🌟 Header
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
                                    Navigator.pop(context);
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
                                const Text(
                                  '🦸‍♂️ Hero Shop',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildProStatusHeader(timeBalance, currentLevel),

                          Expanded(
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ).copyWith(bottom: 40),
                              itemCount: avatars.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 180,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 0.75,
                                  ),
                              itemBuilder: (context, index) {
                                final avatar = Map<String, dynamic>.from(
                                  avatars[index],
                                );
                                final String id = avatar['id'];
                                final bool isUnlocked = unlockedAvatars
                                    .contains(id);
                                // ⭐️ تغییر جادویی: فقط زمانی قفلش کن که هم لولش پایین باشه **و** هم قبلاً نخریده باشتش!
                                final bool isLevelLocked =
                                    (currentLevel <
                                        (avatar['requiredLevel'] ?? 1)) &&
                                    !isUnlocked;
                                final bool isSelected = actualSelected == id;

                                return _buildProAvatarCard(
                                  avatar,
                                  isLevelLocked,
                                  isUnlocked,
                                  isSelected,
                                  currentLevel,
                                  xp,
                                  unlockedAvatars,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildProBottomBar(),
    );
  }

  // --- 🃏 Pro Avatar Cards ---
  Widget _buildProAvatarCard(
    Map<String, dynamic> avatar,
    bool isLevelLocked,
    bool isUnlocked,
    bool isSelected,
    int currentLevel,
    int xp,
    List<String> unlockedAvatars,
  ) {
    final String displayName =
        avatar['name'] ?? avatar['id'].toString().toUpperCase();
    final Color glowColor = isSelected
        ? const Color(0xFF3B82F6)
        : (isUnlocked ? const Color(0xFF4ADE80) : Colors.transparent);

    return GestureDetector(
      onTap: () => _handleAvatarTap(avatar, currentLevel, xp, unlockedAvatars),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6).withOpacity(0.15)
                    : const Color(0xFF2A2A35).withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF60A5FA)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: isLevelLocked
                              ? const Icon(
                                  Icons.lock_rounded,
                                  size: 50,
                                  color: Colors.white24,
                                )
                              : Image.asset(
                                  avatar['image'],
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.face,
                                    size: 50,
                                    color: Colors.white24,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProPriceTag(
                        avatar,
                        isLevelLocked,
                        isUnlocked,
                        isSelected,
                      ),
                    ],
                  ),
                  if (isLevelLocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFFFBBF24),
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProPriceTag(
    Map<String, dynamic> avatar,
    bool isLevelLocked,
    bool isUnlocked,
    bool isSelected,
  ) {
    if (isLevelLocked) {
      return Text(
        "Lvl ${avatar['requiredLevel'] ?? 1} Req",
        style: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }

    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "EQUIPPED",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      );
    }

    if (isUnlocked) {
      return const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF4ADE80),
        size: 22,
      );
    }

    // حالت پیش‌فرض (زمانی که نه قفله، نه انتخاب شده و نه باز شده)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "🔥",
            style: TextStyle(fontSize: 12),
          ), // ⭐️ آیکون رو به آتیش (XP) تغییر دادیم
          const SizedBox(width: 4),
          Text(
            "${avatar['cost'] ?? 0} XP", // ⭐️ حرف m رو به XP تغییر دادیم
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProStatusHeader(int timeBalance, int currentLevel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _proStatusItem(
                  Icons.timer_rounded,
                  "${timeBalance}m",
                  "Time",
                  const Color(0xFF60A5FA),
                ),
                Container(
                  width: 1.5,
                  height: 35,
                  color: Colors.white.withOpacity(0.2),
                ),
                _proStatusItem(
                  Icons.auto_awesome_rounded,
                  "Lvl $currentLevel",
                  "Rank",
                  const Color(0xFFFBBF24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _proStatusItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min, // 👈 این خط مشکل بزرگ شدن رو حل می‌کنه!
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withOpacity(0.9),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: SafeArea(
            top: false, // فقط بخش پایینی (مثل نوار ناوبری آیفون) رو در نظر بگیر
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.heavyImpact();
                  if (localSelected != null) {
                    AppState.avatar = localSelected!;
                    await AppState.save();
                    await AppState.currentChildRef?.update({
                      'avatar': localSelected,
                    });
                  }
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "SAVE & EQUIP HERO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 💬 Pro Dialogs ---
  Future<bool?> _showProConfirmDialog(int cost, String imagePath, String name) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: Dialog(
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
                      color: const Color(0xFFF59E0B).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          imagePath,
                          height: 80,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.face,
                            size: 80,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Unlock $name?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "This will cost $cost XP from your magic wallet.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "Not Now",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                Navigator.pop(context, true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4ADE80,
                                      ).withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Unlock! 🚀",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
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
        );
      },
    );
  }

  void _showProSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
      ),
    );
  }
}

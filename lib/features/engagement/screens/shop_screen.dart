import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/child/data/avatars.dart';

class ShopScreen extends StatefulWidget {
  final int currentXp;
  final int currentLevel;
  final List<dynamic> unlockedAvatars;

  const ShopScreen({
    super.key,
    required this.currentXp,
    required this.currentLevel,
    required this.unlockedAvatars,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Color bgDark = const Color(0xFF0D0D17);
  final Color neonPurple = const Color(0xFF8B5CF6);
  final Color neonBlue = const Color(0xFF3B82F6);
  final Color premiumGold = const Color(0xFFFBBF24);

  late int _localXp;
  late List<dynamic> _localUnlockedAvatars;

  // ⏱️ متغیر برای زمان انتخابی کودک (پیش‌فرض ۱۵ دقیقه)
  int _selectedMinutes = 15;
  final int _xpPerMinute = 5; // قیمت هر ۱ دقیقه = ۵ ایکس‌پی

  // 🔒 قفل جلوگیری از کلیک‌های رگباری و اسپم
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _localXp = widget.currentXp;
    _localUnlockedAvatars = List.from(widget.unlockedAvatars);
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 کل صفحه داخل IgnorePointer قرار می‌گیره تا موقع خرید، لمس‌ها از کار بیفته
    return IgnorePointer(
      ignoring: _isProcessing,
      child: Scaffold(
        backgroundColor: bgDark,
        body: Stack(
          children: [
            // 🌌 هاله‌های نوری
            Positioned(
              top: -150,
              left: -50,
              child: _buildGlowOrb(neonPurple, 400),
            ),
            Positioned(
              bottom: -100,
              right: -50,
              child: _buildGlowOrb(neonBlue, 350),
            ),
            Positioned(
              top: 300,
              left: 100,
              child: _buildGlowOrb(premiumGold.withOpacity(0.3), 200),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    floating: true,
                    leading: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    centerTitle: true,
                    title: const Text(
                      "Galaxy Shop",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 💳 کارت کیف پول
                          _buildElegantWalletCard()
                              .animate()
                              .fade(duration: 600.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 35),

                          // 🦸‍♂️ بخش قهرمانان
                          _buildSectionTitle(
                            "Heroes & Avatars",
                            Icons.face_retouching_natural_rounded,
                          ).animate().fade(delay: 200.ms),
                          const SizedBox(height: 15),
                          _buildAvatarGallery()
                              .animate()
                              .fade(delay: 300.ms)
                              .slideX(begin: 0.1),

                          const SizedBox(height: 40),

                          // ⏳ بخش زمان‌های جادویی
                          _buildSectionTitle(
                            "Craft Magic Time",
                            Icons.hourglass_bottom_rounded,
                          ).animate().fade(delay: 400.ms),
                          const SizedBox(height: 15),
                          _buildInteractiveTimeBoost()
                              .animate()
                              .fade(delay: 500.ms)
                              .slideY(begin: 0.1),

                          const SizedBox(height: 40),

                          // 💎 بخش پریمیوم
                          _buildSectionTitle(
                            "Premium Upgrades",
                            Icons.workspace_premium_rounded,
                          ).animate().fade(delay: 600.ms),
                          const SizedBox(height: 15),
                          _buildPremiumSection()
                              .animate()
                              .fade(delay: 700.ms)
                              .scale(curve: Curves.easeOutBack),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ⏳ لایه لودینگِ زمان خرید (فقط وقتی فعال میشه که کاربر دکمه رو بزنه)
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: premiumGold.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: premiumGold.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 20),
                          const Text(
                                "Processing Magic... 🪄",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: 1500.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fade(duration: 200.ms),
          ],
        ),
      ),
    );
  }

  // =====================================
  // ویجت‌های ظریف و لوکس
  // =====================================

  Widget _buildElegantWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AVAILABLE XP",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$_localXp",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text("🔥", style: TextStyle(fontSize: 24)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: premiumGold, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarGallery() {
    return SizedBox(
      height: 220,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: avatars.length,
          itemBuilder: (context, index) {
            final avatar = avatars[index];
            bool isUnlocked = _localUnlockedAvatars.contains(avatar['id']);
            bool hasLevel = widget.currentLevel >= avatar['requiredLevel'];
            bool canAfford = _localXp >= avatar['cost'];
            return _buildAvatarGlassCard(
              avatar,
              isUnlocked,
              hasLevel,
              canAfford,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarGlassCard(
    Map<String, dynamic> avatar,
    bool isUnlocked,
    bool hasLevel,
    bool canAfford,
  ) {
    // ⭐️ Notun Logic: Jodi level thake othoba age thekei unlocked thake, tahole available
    bool isAvailable = hasLevel || isUnlocked;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF10B981).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow:
                              isAvailable // ⭐️ Ekhane isAvailable use kora hoyeche
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 15,
                                  ),
                                ]
                              : [],
                        ),
                        child: OpityLayer(
                          hasLevel:
                              isAvailable, // ⭐️ Opacity r jonneo isAvailable
                          imagePath: avatar['image'],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        avatar['name'],
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.white
                              : Colors.white54, // ⭐️ Text color update
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      _buildStatusButton(
                        avatar,
                        isUnlocked,
                        hasLevel,
                        canAfford,
                      ),
                    ],
                  ),
                ),
                if (!isAvailable) // ⭐️ Sudhu tokhoni lock dekhabe jodi available na hoy
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    Map<String, dynamic> avatar,
    bool isUnlocked,
    bool hasLevel,
    bool canAfford,
  ) {
    if (isUnlocked) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
          SizedBox(width: 5),
          Text(
            "Owned",
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else if (!hasLevel) {
      return Text(
        "Lvl ${avatar['requiredLevel']} Req",
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => canAfford
            ? _processPurchase('avatar', avatar['id'], avatar['cost'], null)
            : _showError(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: canAfford
                ? premiumGold.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford
                  ? premiumGold.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              "${avatar['cost']} XP",
              style: TextStyle(
                color: canAfford ? premiumGold : Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInteractiveTimeBoost() {
    int totalCost = _selectedMinutes * _xpPerMinute;
    bool canAfford = _localXp >= totalCost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: neonBlue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: neonBlue.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Choose your screen time!",
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAdjustButton(Icons.remove_rounded, () {
                if (_selectedMinutes > 5) {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedMinutes -= 5);
                }
              }),
              Container(
                width: 120,
                alignment: Alignment.center,
                child: Text(
                  "$_selectedMinutes",
                  style: TextStyle(
                    color: neonBlue,
                    fontSize: 45,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              _buildAdjustButton(Icons.add_rounded, () {
                if (_selectedMinutes < 120) {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedMinutes += 5);
                }
              }),
            ],
          ),
          const Text(
            "MINUTES",
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () => canAfford
                ? _processPurchase('time', null, totalCost, _selectedMinutes)
                : _showError(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canAfford
                      ? [neonBlue, const Color(0xFF2563EB)]
                      : [Colors.grey.shade800, Colors.grey.shade900],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: canAfford
                    ? [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "BUY FOR $totalCost XP",
                    style: TextStyle(
                      color: canAfford ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPremiumSection() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Coming Soon! 🚀",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF8B5CF6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Payment Method",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Unlock premium story packs soon.",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    ); // 👈 این همون پرانتزی بود که احتمالاً جا مونده بود!
  }

  // =====================================
  // منطق و پردازش خرید (Anti-Spam + Live Update)
  // =====================================

  Future<void> _processPurchase(
    String type,
    String? itemId,
    int cost,
    int? rewardMins,
  ) async {
    // 🛑 ۱. بررسی قفل ضد اسپم
    if (_isProcessing) return;

    // 🔒 ۲. فعال کردن قفل
    setState(() {
      _isProcessing = true;
    });

    try {
      HapticFeedback.heavyImpact();

      // آپدیت کردنِ ظاهر صفحه (UI) در همون لحظه
      setState(() {
        _localXp -= cost;
        if (type == 'avatar' && itemId != null)
          _localUnlockedAvatars.add(itemId);
      });

      // 🛡️ اگر مهمان بود، فقط کیف پول مجازیش رو آپدیت کن
      if (AppState.isGuest) {
        AppState.guestXp -= cost;
        if (type == 'avatar' && itemId != null) {
          AppState.guestAvatars.add(itemId);
          await AppState.save(); // ⭐️ این خط اضافه شود
          _showSuccessToast("✨ Hero Unlocked Successfully!");
        } else if (type == 'time') {
          AppState.guestTime += rewardMins!;
          await AppState.save(); // ⭐️ این خط اضافه شود
          _showSuccessToast("⏳ +$rewardMins Mins added to your vault!");
          setState(() => _selectedMinutes = 15);
        }
        return;
      }

      // ۳. اگر کاربر واقعی بود، ذخیره در فایربیس
      final parentId = FirebaseAuth.instance.currentUser?.uid;
      if (parentId == null) throw Exception("User not logged in!");

      final docRef = FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(AppState.activeChildId);

      if (type == 'avatar') {
        await docRef.update({
          'xp': FieldValue.increment(-cost),
          'unlockedAvatars': FieldValue.arrayUnion([itemId]),
        });
        _showSuccessToast("✨ Hero Unlocked Successfully!");
      } else if (type == 'time') {
        await docRef.update({
          'xp': FieldValue.increment(-cost),
          'timeBalance': FieldValue.increment(rewardMins!),
        });
        AppState.timeBalance += rewardMins;
        await AppState.save(); // ⭐️ این خط اضافه شود
        _showSuccessToast("⏳ +$rewardMins Mins added to your vault!");
        setState(() => _selectedMinutes = 15);
      }
    } catch (e) {
      // 🚨 ۴. در صورت ارور، پول و آواتار را برگردان
      debugPrint("Purchase Error: $e");
      setState(() {
        _localXp += cost;
        if (type == 'avatar' && itemId != null)
          _localUnlockedAvatars.remove(itemId);
      });
      _showSuccessToast("Connection Error! Try again. 📡", isError: true);
    } finally {
      // 🔓 ۵. باز کردن قفل
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError() {
    HapticFeedback.vibrate();
    _showSuccessToast("Need more XP! Read some books. 📚", isError: true);
  }

  void _showSuccessToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.orange.shade800
            : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        elevation: 10,
      ),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 100)],
      ),
    );
  }
}

class OpityLayer extends StatelessWidget {
  final bool hasLevel;
  final String imagePath;
  const OpityLayer({
    super.key,
    required this.hasLevel,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasLevel ? 1.0 : 0.3,
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white.withOpacity(0.05),
        backgroundImage: AssetImage(imagePath),
      ),
    );
  }
}

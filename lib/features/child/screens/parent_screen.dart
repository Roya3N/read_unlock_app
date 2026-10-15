import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'child_insights_screen.dart';
import 'add_child_screen.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  // 🎨 رنگ‌های تم Pro (Dark Galaxy)
  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color glassCard = const Color(0xFF1E1E24).withOpacity(0.6);

  // 🪄 متد انتخاب فرزند
  Future<void> _selectChild(
    String childId,
    String childName,
    int childAge,
  ) async {
    HapticFeedback.mediumImpact();
    AppState.activeChildId = childId;
    AppState.activeChildName = childName;
    AppState.activeChildAge = childAge;
    await AppState.save();

    if (!mounted) return;
    setState(() {});

    _showProSnackBar(
      'Active Explorer: $childName ($childAge years) 🚀',
      isSuccess: true,
    );
  }

  // متد حذف با دیالوگ شیشه‌ای و سه‌بعدی
  Future<void> _confirmDelete(String childId, String childName) async {
    HapticFeedback.heavyImpact();
    final bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
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
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.2),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Delete Hero?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Are you sure you want to delete $childName?\nAll progress and magic will be lost forever!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(fontWeight: FontWeight.w900),
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

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('children')
          .doc(childId)
          .delete();
      if (mounted) setState(() {});
    }
  }

  // اسنک‌بار شیشه‌ای
  void _showProSnackBar(String message, {bool isSuccess = false}) {
    final color = isSuccess ? const Color(0xFF10B981) : primaryNeon;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
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
    final String? parentId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          // 🌌 هاله‌های نورانی معلق در پس‌زمینه
          Positioned(
            top: -50,
            left: -50,
            child: _buildGlowOrb(primaryNeon, 300),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _buildGlowOrb(accentBlue, 250),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🌟 هدر سفارشی شیشه‌ای (حالا دارای دکمه بازگشت)
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Control Panel',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'Manage your explorers',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildProActionButton(
                    label: "Create New Explorer",
                    icon: Icons.person_add_rounded,
                    color: accentBlue,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddChildScreen(),
                        ),
                      );
                    },
                  ).animate().fade(duration: 400.ms).slideY(begin: -0.2),
                ),

                const SizedBox(height: 10),

                // 📊 لیست فرزندان
                Expanded(
                  child: parentId == null
                      ? const Center(
                          child: Text(
                            "Please log in first.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('parents')
                              .doc(parentId)
                              .collection('children')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return _buildProEmptyState();
                            }

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildProChildCard(doc.id, data)
                                    .animate()
                                    .fade(delay: (100 * index).ms)
                                    .slideX(begin: 0.1);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🃏 کارت اختصاصی شیشه‌ای برای هر فرزند ---
  Widget _buildProChildCard(String id, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Unknown';
    final int xp = data['xp'] ?? 0;
    final String? specialTag = data['specialTag'];
    final bool isSelected = AppState.activeChildId == id;

    String dbAgeGroup = data['ageGroup'] ?? "Kids (5-9 years)";
    int age = 7;
    String displayTag = "Kids";
    String lowerGroup = dbAgeGroup.toLowerCase();

    if (lowerGroup.contains("toddler") || lowerGroup.contains("3-4")) {
      age = 4;
      displayTag = "Toddler";
    } else if (lowerGroup.contains("kids") || lowerGroup.contains("5-9")) {
      age = 7;
      displayTag = "Kids";
    } else if (lowerGroup.contains("pre-teen") ||
        lowerGroup.contains("10-12")) {
      age = 11;
      displayTag = "Pre-teen";
    } else if (lowerGroup.contains("teen") || lowerGroup.contains("13-17")) {
      age = 15;
      displayTag = "Teen";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryNeon.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: () => _selectChild(id, name, age),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? primaryNeon.withOpacity(0.15) : glassCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? primaryNeon
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  // آواتار درخشان
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primaryNeon : Colors.white24,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryNeon.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white12,
                      backgroundImage:
                          data['avatar'] != null &&
                              data['avatar'].toString().isNotEmpty
                          ? AssetImage('assets/avatars/${data['avatar']}.png')
                          : null,
                      child:
                          data['avatar'] == null ||
                              data['avatar'].toString().isEmpty
                          ? Text(
                              name[0],
                              style: TextStyle(
                                color: isSelected ? primaryNeon : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),

                  // اطلاعات
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (specialTag != null && specialTag.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              specialTag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayTag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '🔥 $xp XP',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // دکمه‌های عملیات
                  Column(
                    children: [
                      Row(
                        children: [
                          // 🎁 دکمه جدید برای دادن جایزه (XP / Min)
                          _buildProMiniButton(
                            Icons.card_giftcard_rounded,
                            const Color(0xFFFBBF24),
                            () {
                              // ⭐️ مقادیر فعلی رو هم به پاپ‌آپ می‌فرستیم
                              _showGiftDialog(
                                id,
                                name,
                                data['xp'] ?? 0,
                                data['timeBalance'] ?? 0,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildProMiniButton(
                            Icons.insights_rounded,
                            accentBlue,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildInsightsScreen(
                                    childId: id,
                                    childData: data,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildProMiniButton(
                            Icons.delete_outline_rounded,
                            Colors.redAccent,
                            () => _confirmDelete(id, name),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // نشانگر وضعیت اکتیو بودن
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryNeon
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.touch_app_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSelected ? "Active" : "Select",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
  }

  Widget _buildProMiniButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildProActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 20),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primaryNeon.withOpacity(0.1), blurRadius: 50),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 80,
              color: Colors.white38,
            ),
          ).animate().scale(
            delay: 300.ms,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 25),
          const Text(
            "No Explorers Yet!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Add your first child to start the adventure.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fade(delay: 200.ms),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 150)],
      ),
    );
  }

  // 🎁 پنل شیشه‌ای و حرفه‌ای برای دادن جایزه (XP / زمان) به کودک
  // ⭐️ اینجا currentXp و currentTime رو به ورودی‌ها اضافه کردیم
  void _showGiftDialog(
    String childId,
    String childName,
    int currentXp,
    int currentTime,
  ) {
    HapticFeedback.lightImpact();

    // متغیرهای موقت برای تنظیم مقدار هدیه
    int addXp = 0;
    int addTime = 0;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gift Dialog',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        // ... بقیه استایل‌های Container ... (دست نزن)
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBBF24).withOpacity(0.2),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ... آیکون و متن‌ها (دست نزن) ...
                            const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFFBBF24),
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Reward $childName",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              "Add or remove XP & Screen Time",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // ردیف کنترل XP
                            _buildGiftControlRow(
                              title: "Magic XP",
                              subtitle:
                                  "New Total: ${currentXp + addXp}", // ⭐️ آپدیت زنده مجموع
                              icon: "🔥",
                              color: const Color(0xFFFBBF24),
                              value: addXp,
                              onDecrease: () {
                                setStateDialog(() {
                                  // ⭐️ ترمز هوشمند: نذار از صفر کمتر بشه!
                                  if (currentXp + addXp - 10 < 0) {
                                    addXp = -currentXp;
                                  } else {
                                    addXp -= 10;
                                  }
                                });
                              },
                              onIncrease: () =>
                                  setStateDialog(() => addXp += 10),
                            ),

                            const SizedBox(height: 20),

                            // ردیف کنترل زمان
                            _buildGiftControlRow(
                              title: "Screen Time",
                              subtitle:
                                  "New Total: ${currentTime + addTime} min", // ⭐️ آپدیت زنده مجموع
                              icon: "⏱️",
                              color: const Color(0xFF3B82F6),
                              value: addTime,
                              onDecrease: () {
                                setStateDialog(() {
                                  // ⭐️ ترمز هوشمند: نذار از صفر کمتر بشه!
                                  if (currentTime + addTime - 5 < 0) {
                                    addTime = -currentTime;
                                  } else {
                                    addTime -= 5;
                                  }
                                });
                              },
                              onIncrease: () =>
                                  setStateDialog(() => addTime += 5),
                            ),
                            const SizedBox(height: 35),

                            // ⭐️ دکمه ارسال به دیتابیس (تغییرات اصلی اینجاست)
                            GestureDetector(
                              onTap: () async {
                                if (addXp == 0 && addTime == 0) {
                                  Navigator.pop(context);
                                  return;
                                }

                                // ⭐️ شرط جادویی برای جلوگیری از منفی شدن:
                                // اگر مقدار فعلی + تغییری که والدین دادن کمتر از صفر میشه،
                                // پس فقط به اندازه‌ای کم کن که دارایی بچه صفر بشه.
                                if (currentXp + addXp < 0) {
                                  addXp = -currentXp;
                                }
                                if (currentTime + addTime < 0) {
                                  addTime = -currentTime;
                                }

                                HapticFeedback.heavyImpact();
                                Navigator.pop(context); // بستن دیالوگ

                                // آپدیت مستقیم در فایربیس با مقادیر اصلاح شده
                                await FirebaseFirestore.instance
                                    .collection('parents')
                                    .doc(FirebaseAuth.instance.currentUser?.uid)
                                    .collection('children')
                                    .doc(childId)
                                    .update({
                                      'xp': FieldValue.increment(addXp),
                                      'timeBalance': FieldValue.increment(
                                        addTime,
                                      ),
                                    });

                                _showProSnackBar(
                                  "Success! $childName received the updates. 🎉",
                                  isSuccess: true,
                                );
                              },
                              child: Container(
                                // ... استایل دکمه Apply (دست نزن)
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFBBF24),
                                      Color(0xFFD97706),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFBBF24,
                                      ).withOpacity(0.4),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Apply Changes 🚀",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎛️ ویجت کمکی برای ساخت دکمه‌های + و -
  Widget _buildGiftControlRow({
    required String title,
    required String subtitle, // ⭐️ این خط اضافه شد
    required String icon,
    required Color color,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              // ⭐️ اینجا رو تبدیل به Column کردیم تا دو خط متن داشته باشیم
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle, // ⭐️ نمایش زنده مجموع جدید
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // کنترلرها (- مقدار +)
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDecrease();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),

              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    value > 0 ? "+$value" : "$value",
                    style: TextStyle(
                      color: value < 0 ? Colors.redAccent : color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onIncrease();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

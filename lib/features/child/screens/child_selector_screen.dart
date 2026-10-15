import 'dart:ui'; // For Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';

class ChildSelectorScreen extends StatelessWidget {
  const ChildSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? parentId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 🌌 Dark Galaxy Theme
      body: Stack(
        children: [
          // 🎨 Glowing Background Orbs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 Header Pro (همراه با دکمه برگشت)
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 🔙 دکمه برگشت شیشه‌ای
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

                          // عنوان صفحه
                          const Expanded(
                            child: Text(
                              "Set Up Device 🚀",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    28, // یکم سایز رو متناسب کردم که با دکمه قشنگ بشینه
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15), // فاصله بین عنوان و زیرنویس
                      const Text(
                        "Who is playing today? Select a profile to lock this device in Kid Mode.",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // ... بقیه کدهای بدنه اصلی (مثل لیست بچه‌ها) از اینجا به بعد قرار می‌گیره

                // 👦 Child List
                Expanded(
                  child: parentId == null
                      ? const Center(
                          child: Text(
                            "Error: Parent not logged in.",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('parents')
                              .doc(parentId)
                              .collection('children')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3B82F6),
                                ),
                              );
                            if (snapshot.hasError)
                              return const Center(
                                child: Text(
                                  "Error loading profiles.",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              );

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "📭",
                                        style: TextStyle(fontSize: 50),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        "No heroes found.\nPlease add a child from your phone first.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final childrenDocs = snapshot.data!.docs;

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              itemCount: childrenDocs.length,
                              itemBuilder: (context, index) {
                                final childData =
                                    childrenDocs[index].data()
                                        as Map<String, dynamic>;
                                final childName =
                                    childData['name'] ?? 'Unknown';
                                final childId = childrenDocs[index].id;
                                final ageGroup = childData['ageGroup'] ?? '';
                                final String avatar =
                                    childData['avatar'] ?? 'boy_1';

                                return _buildGlassChildCard(
                                  context,
                                  childName,
                                  ageGroup,
                                  childId,
                                  childData,
                                  avatar,
                                );
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

  // 🃏 Glassmorphism Child Card
  Widget _buildGlassChildCard(
    BuildContext context,
    String name,
    String ageGroup,
    String childId,
    Map<String, dynamic> childData,
    String avatar,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showProLockConfirmation(context, name, childId, childData, avatar);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A35).withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // 👇 بخش آواتار
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 🔥 رنگ حاشیه‌ی دایره‌ای دور آواتار را اینجا تغییر دهید
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                        width: 2,
                      ),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Colors.transparent, // 👈 پس‌زمینه‌ی CircleAvatar
                      backgroundImage: AssetImage('assets/avatars/$avatar.png'),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ageGroup,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lock Icon Button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF60A5FA),
                      size: 24,
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

  // ==========================================
  // 🔥 Sleek Pro Lock Confirmation Dialog
  // ==========================================
  void _showProLockConfirmation(
    BuildContext context,
    String childName,
    String childId,
    Map<String, dynamic> childData,
    String avatar,
  ) {
    showGeneralDialog(
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
                      color: const Color(0xFFF87171).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF87171).withOpacity(0.3),
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
                          color: const Color(0xFFF87171).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Color(0xFFFCA5A5),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Lock Device?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "You are setting up this device for $childName.\n\nIt will be locked in 'Kid Mode'. You will need your Parent PIN to change settings later.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                HapticFeedback.heavyImpact();
                                Navigator.pop(context);

                                AppState.role = 'kid';
                                AppState.activeChildName = childName;
                                AppState.activeChildId = childId;
                                List<dynamic> rawAvatars =
                                    childData['unlockedAvatars'] ?? [];
                                AppState.unlockedAvatars = rawAvatars
                                    .map((e) => e.toString())
                                    .toList();
                                AppState.timeBalance =
                                    (childData['timeBalance'] ?? 0).toInt();
                                AppState.avatar =
                                    childData['avatar'] ?? 'default_avatar';
                                await AppState.save();

                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DashboardScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Yes, Lock It",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
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
}

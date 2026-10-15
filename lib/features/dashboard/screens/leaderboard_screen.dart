import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  // رنگ‌های تم VIP
  final Color gold = const Color(0xFFFBBF24);
  final Color silver = const Color(0xFF94A3B8);
  final Color bronze = const Color(0xFFD97706);
  final Color bgDark = const Color(0xFF0D0D17);

  ImageProvider _getAvatar(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) {
      return const AssetImage('assets/avatars/boy1.png');
    }
    return AssetImage('assets/avatars/$avatarId.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // 🌌 ۱. پس‌زمینه متحرک کهکشانی
          _buildAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // 👑 هدر پرو
                _buildProHeader(context),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('children')
                        .orderBy('xp', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ⭐️ سیستم ضد کرش: اگر فایربیس ارور داد (مثل ارور Index)، اینجا نشونش میده
                      if (snapshot.hasError) {
                        debugPrint("Leaderboard Error: ${snapshot.error}");
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "⚠️ Firebase Error:\n${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white24,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) return _buildEmptyState();

                      List<Map<String, dynamic>> top3 = [];
                      List<Map<String, dynamic>> others = [];
                      Map<String, dynamic>? myData;
                      int myRank = 0;

                      for (int i = 0; i < docs.length; i++) {
                        // ⭐️ جادوی ضد کرش: کپی کردن لیست قفل شده فایربیس
                        var firestoreData =
                            docs[i].data() as Map<String, dynamic>;
                        var data = Map<String, dynamic>.from(firestoreData);

                        data['id'] = docs[i].id;
                        data['rank'] = i + 1;

                        if (docs[i].id == AppState.activeChildId) {
                          myData = data;
                          myRank = i + 1;
                        }
                        if (i < 3) {
                          top3.add(data);
                        } else {
                          others.add(data);
                        }
                      }

                      return Column(
                        children: [
                          // 🥇 بخش سکوهای VIP
                          if (top3.isNotEmpty) _buildVIPPodium(top3),

                          const SizedBox(height: 10),

                          // 🥈 لیست قهرمانان
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount: others.length,
                              itemBuilder: (context, index) {
                                final data = others[index];
                                return _buildProListCard(
                                  data['rank'],
                                  data['name']?.toString() ?? 'Hero',
                                  data['xp'] ?? 0,
                                  data['avatar']?.toString() ?? '',
                                  data['id'] == AppState.activeChildId,
                                );
                              },
                            ),
                          ),

                          // 🟦 نوار وضعیت من
                          if (myData != null)
                            _buildMyProStickyBar(myRank, myData, context),
                        ],
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

  // --- ویجت‌های اختصاصی نسخه Pro ---

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: _buildGlowOrb(const Color(0xFF6366F1), 400)
              .animate(onPlay: (c) => c.repeat())
              .scale(duration: 3.seconds, curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 100,
          right: -100,
          child: _buildGlowOrb(const Color(0xFF8B5CF6), 350)
              .animate(onPlay: (c) => c.repeat())
              .scale(duration: 4.seconds, curve: Curves.easeInOut),
        ),
      ],
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

  Widget _buildProHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TOP HEROES",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "The Hall of Legends",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVIPPodium(List<Map<String, dynamic>> top3) {
    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length >= 2)
            _buildPodiumPillar(
              top3[1],
              2,
              silver,
              110,
            ).animate().slideY(begin: 0.5, duration: 600.ms),
          const SizedBox(width: 15),
          if (top3.isNotEmpty)
            _buildPodiumPillar(
              top3[0],
              1,
              gold,
              150,
            ).animate().slideY(begin: 0.5, duration: 800.ms),
          const SizedBox(width: 15),
          if (top3.length >= 3)
            _buildPodiumPillar(
              top3[2],
              3,
              bronze,
              85,
            ).animate().slideY(begin: 0.5, duration: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar(
    Map<String, dynamic> data,
    int rank,
    Color color,
    double height,
  ) {
    bool isFirst = rank == 1;
    String rawName = data['name']?.toString() ?? 'Hero';
    String firstName = rawName.isNotEmpty ? rawName.split(' ').first : 'Hero';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // آواتار معلق
        Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isFirst ? 3 : 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 15),
                ],
              ),
              child: CircleAvatar(
                radius: isFirst ? 38 : 30,
                backgroundImage: _getAvatar(data['avatar']),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: 2.seconds),

        const SizedBox(height: 10),
        Text(
          firstName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),

        // ستون شیشه‌ای
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 95,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.4), color.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFirst ? "👑" : "#$rank",
                    style: TextStyle(fontSize: isFirst ? 28 : 20),
                  ),
                  Text(
                    "${data['xp'] ?? 0}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    "XP",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProListCard(
    int rank,
    String name,
    int xp,
    String avatar,
    bool isMe,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isMe
                    ? gold.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    "#$rank",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                CircleAvatar(radius: 22, backgroundImage: _getAvatar(avatar)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$xp XP",
                    style: TextStyle(
                      color: isMe ? gold : Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(delay: (rank * 50).ms).slideX(begin: 0.1);
  }

  Widget _buildMyProStickyBar(
    int myRank,
    Map<String, dynamic> myData,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF1E1E2E), bgDark]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: _getAvatar(myData['avatar']?.toString() ?? ''),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myRank == 1 ? "YOU ARE THE CHAMPION!" : "YOUR CURRENT RANK",
                  style: TextStyle(
                    color: myRank == 1 ? gold : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  myRank == 1 ? "Top Legend 👑" : "Global Rank #$myRank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // ⭐️ شرط جادویی: اگه اول بود یه تگ تبریک نشون بده، اگه نبود دکمه بازی!
          if (myRank == 1)
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: gold),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("🏆", style: TextStyle(fontSize: 18)),
                      SizedBox(width: 5),
                      Text(
                        "KING",
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1.seconds,
                )
          else
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context); // بستن لیدربورد و برگشت به بازی
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
              ),
              child: const Text(
                "KEEP PLAYING!",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 80),
          SizedBox(height: 20),
          Text(
            "No Legends Yet",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

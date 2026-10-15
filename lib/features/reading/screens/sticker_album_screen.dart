import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StickerAlbumScreen extends StatelessWidget {
  const StickerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> letters = List.generate(
      26,
      (index) => String.fromCharCode(65 + index),
    );
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "🌟 Magical Album",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: StarryBackgroundPainter()),
          ),

          // ⭐️ وصل شدیم به فایربیس تا زنده چک کنه کدوم کارت‌ها باز شدن
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parents')
                .doc(user?.uid)
                .collection('children')
                .doc(AppState.activeChildId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                );
              }

              // گرفتن لیست کارت‌های باز شده از دیتابیس (اگر خالی بود، یه لیست خالی میده)
              var data = snapshot.data?.data() as Map<String, dynamic>?;
              List<dynamic> unlockedCards =
                  data != null && data.containsKey('unlockedCards')
                  ? data['unlockedCards']
                  : [];

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: letters.length,
                itemBuilder: (context, index) {
                  String currentLetter = letters[index];

                  // ⭐️ چک می‌کنه آیا این حرف تو لیست جایزه‌هاش هست یا نه
                  bool isUnlocked = unlockedCards.contains(currentLetter);

                  return HolographicCard(
                        letter: currentLetter,
                        isUnlocked: isUnlocked,
                      )
                      .animate()
                      .fade(delay: (index * 20).ms)
                      .scale(begin: const Offset(0.8, 0.8));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ✨ نقاشِ ستاره‌های پس‌زمینه (بدون نیاز به عکس)
// ==========================================
class StarryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15);
    final random = Random(42); // عدد ثابت برای اینکه جای ستاره‌ها عوض نشه

    for (int i = 0; i < 150; i++) {
      double dx = random.nextDouble() * size.width;
      double dy = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 🃏 ویجت کارت جادویی سه‌بعدی (Holographic Card)
// ==========================================
class HolographicCard extends StatefulWidget {
  final String letter;
  final bool isUnlocked;

  const HolographicCard({
    super.key,
    required this.letter,
    required this.isUnlocked,
  });

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with SingleTickerProviderStateMixin {
  double _rotationX = 0;
  double _rotationY = 0;
  double _lightPositionX = 0;
  double _lightPositionY = 0;

  late AnimationController _resetController;
  late Animation<double> _resetAnimationX;
  late Animation<double> _resetAnimationY;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      setState(() {
        _rotationX = _resetAnimationX.value;
        _rotationY = _resetAnimationY.value;
        // نور هم باهاش برگرده سر جاش
        _lightPositionX = _resetAnimationY.value * 2;
        _lightPositionY = _resetAnimationX.value * 2;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  // محاسبه چرخش بر اساس حرکت دست
  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.isUnlocked) return; // کارت قفل تکون نمی‌خوره

    setState(() {
      // محاسبه زاویه چرخش
      _rotationX =
          -((details.localPosition.dy - size.height / 2) / size.height) * 0.5;
      _rotationY =
          ((details.localPosition.dx - size.width / 2) / size.width) * 0.5;

      // حرکت دادن بازتاب نور برعکس حرکت کارت
      _lightPositionX = ((details.localPosition.dx / size.width) * 2) - 1;
      _lightPositionY = ((details.localPosition.dy / size.height) * 2) - 1;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isUnlocked) return;

    // وقتی دست رو برمیداره، کارت با انیمیشن نرم برگرده سر جاش
    _resetAnimationX = Tween<double>(
      begin: _rotationX,
      end: 0,
    ).animate(CurvedAnimation(parent: _resetController, curve: Curves.easeOut));
    _resetAnimationY = Tween<double>(
      begin: _rotationY,
      end: 0,
    ).animate(CurvedAnimation(parent: _resetController, curve: Curves.easeOut));
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, size),
          onPanEnd: _onPanEnd,
          child: Transform(
            // ⭐️ جادوی 3D
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(_rotationX)
              ..rotateY(_rotationY),
            alignment: FractionalOffset.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (widget.isUnlocked)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(-_rotationY * 30, -_rotationX * 30),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // ۱. پس‌زمینه کارت (برای کارت‌های قفل شده)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isUnlocked
                              ? [
                                  const Color(0xFF2E1065),
                                  const Color(0xFF4C1D95),
                                ]
                              : [
                                  const Color(0xFF1E1E24),
                                  const Color(0xFF121212),
                                ],
                        ),
                        border: Border.all(
                          color: widget.isUnlocked
                              ? const Color(0xFF8B5CF6).withOpacity(0.5)
                              : Colors.white12,
                          width: 2,
                        ),
                      ),
                    ),

                    // ۲. 🖼️ عکس پوستر از سوپابیس (فقط وقتی قفلش بازه)
                    if (widget.isUnlocked)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // لبه‌های عکس گرد بشه
                          child: CachedNetworkImage(
                            // ⭐️ آدرس سوپابیس خودت رو اینجا جایگزین کن ⭐️
                            // فرض کردم اسم عکس‌ها A.png و B.png و... هست
                            imageUrl:
                                "https://esruowjvnottjknrkubg.supabase.co/storage/v1/object/public/images/academy/3-4-toddlers/alphabet/posters/${widget.letter.toLowerCase()}.png",
                            fit: BoxFit.cover,

                            // موقع لود شدن یه دایره چرخان نشون میده
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                              ),
                            ),

                            // اگر اینترنت قطع بود یا عکس نبود، همون حرف رو نشون میده
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                widget.letter,
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 10,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ۳. آیکون قفل (وقتی کارت هنوز قفله)
                    if (!widget.isUnlocked)
                      const Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),

                    // ۴. ⭐️ افکت نور هولوگرامی رنگین‌کمانی (می‌افته روی عکس!)
                    if (widget.isUnlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(
                                -_lightPositionX - 1,
                                -_lightPositionY - 1,
                              ),
                              end: Alignment(
                                _lightPositionX + 1,
                                _lightPositionY + 1,
                              ),
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.pinkAccent.withOpacity(0.15),
                                Colors.blueAccent.withOpacity(0.15),
                                Colors.white.withOpacity(0.4), // خط نور اصلی
                                Colors.purpleAccent.withOpacity(0.15),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.3, 0.4, 0.5, 0.6, 1.0],
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
      },
    );
  }
}

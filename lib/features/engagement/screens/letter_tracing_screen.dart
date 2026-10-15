import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ⭐️ پکیج صدا اضافه شد

class DrawingStroke {
  final List<Offset> normalizedPoints;
  final Color color;
  final double width;
  final bool isEraser;

  DrawingStroke({
    required this.normalizedPoints,
    required this.color,
    required this.width,
    required this.isEraser,
  });
}

class LetterTracingScreen extends StatefulWidget {
  final String letter;
  final String tracingUrl;
  final VoidCallback onComplete;

  const LetterTracingScreen({
    super.key,
    required this.letter,
    required this.tracingUrl,
    required this.onComplete,
  });

  @override
  State<LetterTracingScreen> createState() => _LetterTracingScreenState();
}

class _LetterTracingScreenState extends State<LetterTracingScreen> {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _undoHistory = [];
  DrawingStroke? _currentStroke;

  Color _selectedColor = const Color(0xFF8B5CF6);
  double _strokeWidth = 12.0;
  double _eraserWidth = 35.0;
  bool _isEraser = false;
  bool _isDrawingMode = true;

  bool _isToolbarOpen = true;
  bool _canShowDoneButton = false;

  final List<Color> _colors = [
    const Color(0xFF8B5CF6),
    const Color(0xFF3B82F6),
    const Color(0xFFEF4444),
    const Color(0xFF10B981),
    const Color(0xFFFBBF24),
    const Color(0xFF1F2937),
  ];

  // ⭐️ موتور رباتیک صدا
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  // ⭐️ تنظیم صدای لطیف برای خوندن حروف
  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.8);
    await flutterTts.setSpeechRate(0.4);
  }

  @override
  void dispose() {
    flutterTts.stop(); // ⭐️ خاموش کردن ربات موقع خروج
    super.dispose();
  }

  // ⭐️ متد پخش صدای حرف (مثلا میگه: B)
  void _playLetterSound() async {
    HapticFeedback.lightImpact();
    await flutterTts.speak(widget.letter.toUpperCase());
  }

  Offset _normalize(Offset localPos, Size size) {
    return Offset(localPos.dx / size.width, localPos.dy / size.height);
  }

  void _checkInkRequirement() {
    double totalInk = 0;
    for (var stroke in _strokes) {
      if (stroke.isEraser) continue;
      for (int i = 0; i < stroke.normalizedPoints.length - 1; i++) {
        totalInk +=
            (stroke.normalizedPoints[i] - stroke.normalizedPoints[i + 1])
                .distance;
      }
    }

    if (totalInk >= 5.0 && !_canShowDoneButton) {
      setState(() => _canShowDoneButton = true);
      HapticFeedback.mediumImpact();
    } else if (totalInk < 5.0 && _canShowDoneButton) {
      setState(() => _canShowDoneButton = false);
    }
  }

  void _startStroke(DragStartDetails details, Size size) {
    if (!_isDrawingMode) return;
    setState(() {
      _currentStroke = DrawingStroke(
        normalizedPoints: [_normalize(details.localPosition, size)],
        color: _selectedColor,
        width: _isEraser ? _eraserWidth : _strokeWidth,
        isEraser: _isEraser,
      );
      _undoHistory.clear();
    });
  }

  void _updateStroke(DragUpdateDetails details, Size size) {
    if (!_isDrawingMode || _currentStroke == null) return;
    setState(() {
      _currentStroke!.normalizedPoints.add(
        _normalize(details.localPosition, size),
      );
    });
  }

  void _endStroke(DragEndDetails details) {
    if (_currentStroke != null) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
      _checkInkRequirement();
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _undoHistory.add(_strokes.removeLast()));
      _checkInkRequirement();
    }
  }

  void _redo() {
    if (_undoHistory.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _strokes.add(_undoHistory.removeLast()));
      _checkInkRequirement();
    }
  }

  Future<void> _finishTracing() async {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4ADE80),
          strokeWidth: 6,
        ),
      ),
    );

    int earnedXp = 2;
    int earnedTime = 0;

    try {
      if (AppState.activeChildId.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('parents')
              .doc(user.uid)
              .collection('children')
              .doc(AppState.activeChildId)
              .update({
                'xp': FieldValue.increment(earnedXp),
                // ⭐️ این خط جادویی رو اضافه کنید: حرف رو تو کیف کارت‌هاش ذخیره می‌کنه
                'unlockedCards': FieldValue.arrayUnion([
                  widget.letter.toUpperCase(),
                ]),
              });
        }
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        _showProRewardPopup(earnedXp, earnedTime);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        _showProRewardPopup(earnedXp, earnedTime);
      }
    }
  }

  void _showProRewardPopup(int xp, int time) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(a1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🏆",
                    style: TextStyle(fontSize: 70),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 15),
                  const Text(
                    "Well Done!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.orangeAccent,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "+$xp XP",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Tracer Pro: ${widget.letter}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            // ⭐️ دکمه بلندگو با افکت تپش قلب که به ربات وصله
            IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFFFBBF24),
                    size: 28,
                  ),
                  onPressed: _playLetterSound,
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.2, 1.2),
                  duration: 800.ms,
                ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _strokes.clear();
                _checkInkRequirement();
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(
            constraints.maxWidth - 1,
            constraints.maxHeight - 1,
          );
          return Stack(
            children: [
              Center(
                child: Container(
                  width: canvasSize.width,
                  height: canvasSize.height,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 234, 236, 205),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: InteractiveViewer(
                      panEnabled: !_isDrawingMode,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 0.75,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: widget.tracingUrl,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    final innerSize = Size(
                                      innerConstraints.maxWidth,
                                      innerConstraints.maxHeight,
                                    );
                                    return GestureDetector(
                                      onPanStart: _isDrawingMode
                                          ? (d) => _startStroke(d, innerSize)
                                          : null,
                                      onPanUpdate: _isDrawingMode
                                          ? (d) => _updateStroke(d, innerSize)
                                          : null,
                                      onPanEnd: _isDrawingMode
                                          ? _endStroke
                                          : null,
                                      onTapDown: _isDrawingMode
                                          ? (d) {
                                              _startStroke(
                                                DragStartDetails(
                                                  localPosition:
                                                      d.localPosition,
                                                ),
                                                innerSize,
                                              );
                                              _endStroke(DragEndDetails());
                                            }
                                          : null,
                                      child: CustomPaint(
                                        painter: ProTracingPainter(
                                          strokes: _strokes,
                                          currentStroke: _currentStroke,
                                          canvasSize: innerSize,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: 300.ms,
                curve: Curves.easeInOut,
                right: _isToolbarOpen ? 15 : -65,
                top: 20,
                bottom: 120,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isToolbarOpen = !_isToolbarOpen);
                      },
                      child: Container(
                        width: 35,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E24),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        child: Icon(
                          _isToolbarOpen
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.brush_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildProSidebar(),
                  ],
                ),
              ),

              if (_canShowDoneButton)
                Positioned(
                  bottom: 20,
                  left: 100,
                  right: 100,
                  child:
                      ElevatedButton(
                            onPressed: _finishTracing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ADE80),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 10,
                              shadowColor: const Color(
                                0xFF4ADE80,
                              ).withOpacity(0.5),
                            ),
                            child: const Text(
                              "I'M DONE! ✨",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 20,
                                letterSpacing: 1.2,
                              ),
                            ),
                          )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut)
                          .fadeIn(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProSidebar() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24).withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildSidebarIcon(
              Icons.edit_rounded,
              _isDrawingMode && !_isEraser,
              () => setState(() {
                _isDrawingMode = true;
                _isEraser = false;
              }),
            ),
            _buildSidebarIcon(
              Icons.pan_tool_rounded,
              !_isDrawingMode,
              () => setState(() => _isDrawingMode = false),
            ),
            _buildSidebarIcon(
              Icons.cleaning_services_rounded,
              _isEraser && _isDrawingMode,
              () => setState(() {
                _isEraser = true;
                _isDrawingMode = true;
              }),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white10, indent: 10, endIndent: 10),
            ),
            _buildSidebarIcon(Icons.undo_rounded, false, _undo),
            _buildSidebarIcon(Icons.redo_rounded, false, _redo),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white10, indent: 10, endIndent: 10),
            ),
            SizedBox(
              height: 120,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: _isEraser ? _eraserWidth : _strokeWidth,
                    min: 2.0,
                    max: 40.0,
                    activeColor: _isEraser ? Colors.white70 : _selectedColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() {
                        if (_isEraser) {
                          _eraserWidth = val;
                        } else {
                          _strokeWidth = val;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white10, indent: 10, endIndent: 10),
            ),
            ..._colors.map(
              (c) => GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedColor = c;
                    _isEraser = false;
                    _isDrawingMode = true;
                  });
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.only(bottom: 15),
                  width: _selectedColor == c && !_isEraser ? 34 : 24,
                  height: _selectedColor == c && !_isEraser ? 34 : 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == c && !_isEraser
                          ? Colors.white
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? const Color(0xFF4ADE80) : Colors.white54,
          size: isActive ? 28 : 24,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}

class ProTracingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Size canvasSize;
  ProTracingPainter({
    required this.strokes,
    this.currentStroke,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    for (final stroke in strokes) _drawSmoothStroke(canvas, stroke, size);
    if (currentStroke != null) _drawSmoothStroke(canvas, currentStroke!, size);
    canvas.restore();
  }

  void _drawSmoothStroke(Canvas canvas, DrawingStroke stroke, Size size) {
    if (stroke.normalizedPoints.isEmpty) return;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;
    if (stroke.isEraser)
      paint.blendMode = BlendMode.clear;
    else
      paint.color = stroke.color;
    final path = Path();
    if (stroke.normalizedPoints.length == 1) {
      Offset p = Offset(
        stroke.normalizedPoints.first.dx * size.width,
        stroke.normalizedPoints.first.dy * size.height,
      );
      path.moveTo(p.dx, p.dy);
      path.lineTo(p.dx, p.dy + 0.1);
    } else {
      Offset startPoint = Offset(
        stroke.normalizedPoints[0].dx * size.width,
        stroke.normalizedPoints[0].dy * size.height,
      );
      path.moveTo(startPoint.dx, startPoint.dy);
      for (int i = 1; i < stroke.normalizedPoints.length - 1; i++) {
        Offset p0 = Offset(
          stroke.normalizedPoints[i].dx * size.width,
          stroke.normalizedPoints[i].dy * size.height,
        );
        Offset p1 = Offset(
          stroke.normalizedPoints[i + 1].dx * size.width,
          stroke.normalizedPoints[i + 1].dy * size.height,
        );
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ProTracingPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';

class ActivityStroke {
  final List<Offset> normalizedPoints;
  final Color color;
  final double width;
  final bool isEraser;

  ActivityStroke({
    required this.normalizedPoints,
    required this.color,
    required this.width,
    required this.isEraser,
  });
}

class ActivityScreen extends StatefulWidget {
  final String letter;
  final String imageUrl;
  final VoidCallback onComplete;

  const ActivityScreen({
    super.key,
    required this.letter,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<Map<String, dynamic>> touchPoints = [
    {'id': 1, 'x': 0.131, 'y': 0.744, 'isCorrect': true, 'status': 'none'},
    {'id': 2, 'x': 0.264, 'y': 0.803, 'isCorrect': true, 'status': 'none'},
    {'id': 3, 'x': 0.505, 'y': 0.746, 'isCorrect': true, 'status': 'none'},
    {'id': 4, 'x': 0.521, 'y': 0.799, 'isCorrect': true, 'status': 'none'},
    {'id': 5, 'x': 0.758, 'y': 0.743, 'isCorrect': true, 'status': 'none'},
    {'id': 6, 'x': 0.863, 'y': 0.798, 'isCorrect': true, 'status': 'none'},
  ];

  int correctAnswersFound = 0;
  final int totalCorrectAnswers = 6;

  final List<ActivityStroke> _strokes = [];
  final List<ActivityStroke> _undoHistory = [];
  ActivityStroke? _currentStroke;

  Color _selectedColor = const Color(0xFFEF4444);
  double _strokeWidth = 6.0;
  double _eraserWidth = 35.0;
  bool _isEraser = false;
  bool _isDrawingMode = true;

  // ⭐️ متغیرهای جدید: سایدبار در ابتدا بسته است
  bool _isToolbarOpen = false;

  final List<Color> _colors = [
    const Color(0xFF8B5CF6),
    const Color(0xFF3B82F6),
    const Color(0xFFEF4444),
    const Color(0xFF10B981),
    const Color(0xFFFBBF24),
    const Color(0xFF1F2937),
  ];

  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now(); // 🌟 شروع تایمر
  }

  void _handleTap(int index) {
    if (touchPoints[index]['status'] != 'none') return;

    setState(() {
      if (touchPoints[index]['isCorrect']) {
        touchPoints[index]['status'] = 'correct';
        correctAnswersFound++;

        // اگر همه رو پیدا کرد، یه ویبره خاص بده
        if (correctAnswersFound == totalCorrectAnswers) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      } else {
        touchPoints[index]['status'] = 'wrong';
        HapticFeedback.vibrate();
      }
    });
  }

  void _submitActivity() {
    double totalInkLength = 0;
    for (var stroke in _strokes) {
      if (stroke.isEraser) continue;
      for (int i = 0; i < stroke.normalizedPoints.length - 1; i++) {
        totalInkLength +=
            (stroke.normalizedPoints[i] - stroke.normalizedPoints[i + 1])
                .distance;
      }
    }

    if (totalInkLength < 0.6) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🖍️ Great! Now circle the letters with your pen!"),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // منو رو اتوماتیک براش باز می‌کنیم تا بتونه قلم برداره!
      if (!_isToolbarOpen) {
        setState(() => _isToolbarOpen = true);
      }
      return;
    }

    HapticFeedback.heavyImpact();
    _finishActivity();
  }

  Future<void> _finishActivity() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
      ),
    );

    int earnedXp = 5; // ⭐️ یه کم امتیازش رو بردیم بالاتر تا انگیزه بگیره
    int timeSpent = 2; // ⏱️ فرض می‌کنیم این کاربرگ حدود ۲ دقیقه وقتش رو گرفته

    int actualSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
    int actualMinutes = (actualSeconds / 60).ceil();
    if (actualMinutes < 1) actualMinutes = 1;

    try {
      if (AppState.activeChildId.isNotEmpty) {
        // 🌟 جادوی مرکز فرماندهی: ثبت امتیاز و زمان در نمودار داشبورد!
        await ProgressService.logActivity(
          xpEarned: earnedXp,
          playedMinutes: actualMinutes,
          activityName: 'tracing',
        );
      }

      if (mounted) {
        Navigator.pop(context); // بستن لودینگ
        widget
            .onComplete(); // اعلام به صفحه قبلی که کار تموم شد (برای رفتن به مرحله بعد)
        Navigator.pop(context); // خروج از صفحه بازی
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        Navigator.pop(context);
      }
    }
  }

  Offset _normalize(Offset localPos, Size size) {
    return Offset(localPos.dx / size.width, localPos.dy / size.height);
  }

  void _startStroke(DragStartDetails details, Size size) {
    if (!_isDrawingMode) return;
    setState(() {
      _currentStroke = ActivityStroke(
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
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _undoHistory.add(_strokes.removeLast()));
    }
  }

  void _redo() {
    if (_undoHistory.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _strokes.add(_undoHistory.removeLast()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          "Find & Circle!",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              setState(() => _strokes.clear());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // عکس با سایز کامل و حفظ تناسب
          Center(
            child: AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final innerSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: _isDrawingMode
                              ? (d) => _startStroke(d, innerSize)
                              : null,
                          onPanUpdate: _isDrawingMode
                              ? (d) => _updateStroke(d, innerSize)
                              : null,
                          onPanEnd: _isDrawingMode ? _endStroke : null,
                          onTapDown: _isDrawingMode
                              ? (d) {
                                  _startStroke(
                                    DragStartDetails(
                                      localPosition: d.localPosition,
                                    ),
                                    innerSize,
                                  );
                                  _endStroke(DragEndDetails());
                                }
                              : null,
                          child: CustomPaint(
                            painter: ActivityPainter(
                              strokes: _strokes,
                              currentStroke: _currentStroke,
                              canvasSize: innerSize,
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(touchPoints.length, (index) {
                        final point = touchPoints[index];
                        return Positioned(
                          left: (constraints.maxWidth * point['x']) - 25,
                          top: (constraints.maxHeight * point['y']) - 25,
                          child: GestureDetector(
                            onTap: () => _handleTap(index),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.transparent,
                              child: _buildFeedbackIcon(point['status']),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          // ⭐️ سایدبار متحرک و هوشمند
          AnimatedPositioned(
            duration: 300.ms,
            curve: Curves.easeInOut,
            right: _isToolbarOpen ? 15 : -65, // عرض سایدبار تقریبا 60 هست
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
                      color: Color.fromARGB(255, 155, 165, 190),
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

          // ⭐️ دکمه تایید فقط وقتی ظاهر میشه که هر ۶ تا پیدا بشن
          if (correctAnswersFound == totalCorrectAnswers)
            Positioned(
              bottom: 20,
              left: 100,
              right: 100,
              child:
                  ElevatedButton(
                        onPressed: _submitActivity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ADE80),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 10,
                          shadowColor: const Color(0xFF4ADE80).withOpacity(0.5),
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
      ),
    );
  }

  Widget _buildFeedbackIcon(String status) {
    if (status == 'correct')
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 40,
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fade();
    else if (status == 'wrong')
      return const Icon(
        Icons.cancel,
        color: Colors.red,
        size: 40,
      ).animate().shake().fade();
    return const SizedBox();
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

class ActivityPainter extends CustomPainter {
  final List<ActivityStroke> strokes;
  final ActivityStroke? currentStroke;
  final Size canvasSize;
  ActivityPainter({
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

  void _drawSmoothStroke(Canvas canvas, ActivityStroke stroke, Size size) {
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
  bool shouldRepaint(ActivityPainter oldDelegate) => true;
}

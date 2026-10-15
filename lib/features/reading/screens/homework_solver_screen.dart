import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

enum ToolType { pan, pen, pencil, highlighter, straightLine, eraser }

enum DocumentMode { pdf, image, blank }

class PaperStyle {
  final Color backgroundColor;
  final String pattern;
  final Color lineColor;
  final String name;

  PaperStyle({
    required this.backgroundColor,
    required this.pattern,
    required this.lineColor,
    required this.name,
  });
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double weight;
  final ToolType toolType;
  final double opacity;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.weight,
    required this.toolType,
    this.opacity = 1.0,
  });
}

class HomeworkSolverScreen extends StatefulWidget {
  final String fileName;
  final String? filePath;
  final Uint8List? fileBytes;
  final PaperStyle?
  selectedPaper; // 👈 این متغیر اضافه شد تا ارور قرمز برطرف بشه

  const HomeworkSolverScreen({
    super.key,
    required this.fileName,
    this.filePath,
    this.fileBytes,
    this.selectedPaper, // 👈 اضافه شد
  });

  @override
  State<HomeworkSolverScreen> createState() => _HomeworkSolverScreenState();
}

class _HomeworkSolverScreenState extends State<HomeworkSolverScreen>
    with SingleTickerProviderStateMixin {
  late PdfViewerController _pdfViewerController;
  late AnimationController _panelAnimController;
  late Animation<double> _panelAnimation;
  late TransformationController _imageTransformController;

  final List<Color> _palette = [
    const Color(0xFF000000),
    const Color(0xFFFFFFFF),
    const Color(0xFF94A3B8),
    const Color(0xFFEF4444),
    const Color(0xFFF97316),
    const Color(0xFFF59E0B),
    const Color(0xFF84CC16),
    const Color(0xFF10B981),
    const Color(0xFF06B6D4),
    const Color(0xFF3B82F6),
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
    const Color(0xFFD946EF),
    const Color(0xFFF43F5E),
    const Color(0xFF8B4513),
  ];

  ToolType _activeTool = ToolType.pen;
  Color _activeColor = const Color(0xFF3B82F6);

  final Map<ToolType, double> _toolWidths = {
    ToolType.pan: 2.0,
    ToolType.pen: 2.5,
    ToolType.pencil: 4.0,
    ToolType.highlighter: 25.0,
    ToolType.straightLine: 3.0,
    ToolType.eraser: 30.0,
  };
  final Map<ToolType, double> _toolOpacities = {
    ToolType.pan: 1.0,
    ToolType.pen: 1.0,
    ToolType.pencil: 0.7,
    ToolType.highlighter: 0.4,
    ToolType.straightLine: 1.0,
    ToolType.eraser: 1.0,
  };

  int _currentPage = 1;
  int _totalPages = 1;
  final Map<int, List<DrawingStroke>> _allPageStrokes = {};
  List<DrawingStroke> _currentStrokes = [];

  double _pdfZoom = 1.0;
  Offset _pdfScroll = Offset.zero;
  bool _isPdfLoaded = false;
  bool _showSettingsPanel = false;
  bool _isFullscreen = false;

  late DocumentMode _docMode;
  late PaperStyle _activePaper;

  final List<PaperStyle> _templates = [
    PaperStyle(
      name: "Blank White",
      backgroundColor: Colors.white,
      pattern: 'blank',
      lineColor: Colors.transparent,
    ),
    PaperStyle(
      name: "Ruled White",
      backgroundColor: const Color(0xFFFAFAFA),
      pattern: 'ruled',
      lineColor: Colors.blue.withOpacity(0.2),
    ),
    PaperStyle(
      name: "Grid Paper",
      backgroundColor: const Color(0xFFFAFAFA),
      pattern: 'grid',
      lineColor: Colors.grey.withOpacity(0.25),
    ),
    PaperStyle(
      name: "Dot Grid",
      backgroundColor: const Color(0xFFFAFAFA),
      pattern: 'dotted',
      lineColor: Colors.grey.withOpacity(0.4),
    ),
    PaperStyle(
      name: "Cornell",
      backgroundColor: Colors.white,
      pattern: 'cornell',
      lineColor: Colors.red.withOpacity(0.5),
    ),
    PaperStyle(
      name: "Legal Yellow",
      backgroundColor: const Color(0xFFFDF2CC),
      pattern: 'ruled',
      lineColor: Colors.lightBlue.withOpacity(0.3),
    ),
    PaperStyle(
      name: "Kraft Brown",
      backgroundColor: const Color(0xFFE1C699),
      pattern: 'blank',
      lineColor: Colors.transparent,
    ),
    PaperStyle(
      name: "Dark Canvas",
      backgroundColor: const Color(0xFF252525),
      pattern: 'blank',
      lineColor: Colors.transparent,
    ),
    PaperStyle(
      name: "Dark Grid",
      backgroundColor: const Color(0xFF252525),
      pattern: 'grid',
      lineColor: Colors.white.withOpacity(0.05),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _imageTransformController = TransformationController();
    _panelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimController,
      curve: Curves.easeOutCubic,
    );

    if (widget.filePath == null && widget.fileBytes == null) {
      _docMode = DocumentMode.blank;
      // 👈 دریافت کاغذ از گالری، وگرنه کاغذ پیش‌فرض
      _activePaper = widget.selectedPaper ?? _templates[1];
    } else {
      final ext = widget.fileName.split('.').last.toLowerCase();
      _docMode = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'].contains(ext)
          ? DocumentMode.image
          : DocumentMode.pdf;
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _imageTransformController.dispose();
    _panelAnimController.dispose();
    super.dispose();
  }

  void _changePage(int newPage) {
    if (_docMode != DocumentMode.pdf) return;
    if (newPage < 1 || newPage > _totalPages) return;
    _pdfViewerController.jumpToPage(newPage);
  }

  void _undo() {
    if (_currentStrokes.isNotEmpty)
      setState(() => _currentStrokes.removeLast());
  }

  void _zoomIn() {
    if (_docMode != DocumentMode.pdf) {
      final currentScale = _imageTransformController.value.getMaxScaleOnAxis();
      if (currentScale < 5.0)
        setState(() {
          _imageTransformController.value = Matrix4.identity()
            ..scale((currentScale + 0.25).clamp(1.0, 5.0));
          _pdfZoom = (currentScale + 0.25).clamp(1.0, 5.0);
        });
    } else if (_pdfZoom < 5.0)
      _pdfViewerController.zoomLevel = (_pdfZoom + 0.25).clamp(1.0, 5.0);
  }

  void _zoomOut() {
    if (_docMode != DocumentMode.pdf) {
      final currentScale = _imageTransformController.value.getMaxScaleOnAxis();
      if (currentScale > 1.0)
        setState(() {
          _imageTransformController.value = Matrix4.identity()
            ..scale((currentScale - 0.25).clamp(1.0, 5.0));
          _pdfZoom = (currentScale - 0.25).clamp(1.0, 5.0);
        });
    } else if (_pdfZoom > 1.0)
      _pdfViewerController.zoomLevel = (_pdfZoom - 0.25).clamp(1.0, 5.0);
  }

  void _startStroke(Offset position) {
    setState(() {
      if (_showSettingsPanel) _toggleSettingsPanel();
      _currentStrokes.add(
        DrawingStroke(
          points: [position],
          color: _activeTool == ToolType.eraser
              ? Colors.transparent
              : _activeColor,
          weight: _toolWidths[_activeTool]!,
          toolType: _activeTool,
          opacity: _toolOpacities[_activeTool]!,
        ),
      );
    });
  }

  void _updateStroke(Offset position) {
    setState(() {
      if (_activeTool == ToolType.straightLine) {
        if (_currentStrokes.last.points.length > 1)
          _currentStrokes.last.points.last = position;
        else
          _currentStrokes.last.points.add(position);
      } else {
        _currentStrokes.last.points.add(position);
      }
    });
  }

  void _toggleSettingsPanel() {
    setState(() {
      _showSettingsPanel = !_showSettingsPanel;
      if (_showSettingsPanel)
        _panelAnimController.forward();
      else
        _panelAnimController.reverse();
    });
  }

  // 👈 متد شبیه‌ساز پردازش Save
  Future<void> _processSaving({
    required String fileName,
    required String path,
  }) async {
    _allPageStrokes[_currentPage] = List.from(_currentStrokes);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              "Saving $fileName...",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "To: $path",
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    // 🌟 جادوی مرکز فرماندهی: ثبت فعالیت برای حل تکلیف!
    // فرض می‌کنیم حل تکلیف حداقل ۱۰ دقیقه طول می‌کشه و چون کار سختیه، ۲۰ امتیاز (XP) داره
    await ProgressService.logActivity(xpEarned: 20, playedMinutes: 10);

    if (mounted) {
      Navigator.pop(context); // بستن لودینگ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Success! Saved to $path/$fileName 🌟 +20 XP!",
          ), // 👈 یه اشاره کوچیک به جایزه تو پیام
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 👈 متد دیالوگ انتخاب مسیر و نام برای Save As
  Future<void> _showSaveAsLocationDialog() async {
    TextEditingController nameCtrl = TextEditingController(
      text: "Solved_${widget.fileName}",
    );
    String selectedPath = "/Downloads/My_Files";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white12),
            ),
            title: const Row(
              children: [
                Icon(Icons.create_new_folder_rounded, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  "Save Document As",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "File Name",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2A2A35),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Save Location",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => setStateModal(
                    () => selectedPath = selectedPath == "/Downloads/My_Files"
                        ? "/Documents/Work"
                        : "/Downloads/My_Files",
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedPath,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.ads_click_rounded,
                          color: Colors.white24,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tap path to change folder",
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processSaving(fileName: nameCtrl.text, path: selectedPath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text(
                  "Save Here",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _downloadFileOnWeb(String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              "Preparing $fileName for download...",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Downloading $fileName..."),
            backgroundColor: Colors.green.shade800,
          ),
        );

        final bytes = Uint8List.fromList([0]);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.Url.revokeObjectUrl(url);
      }
    });
  }

  void _showPaperSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Choose Paper Template",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final paper = _templates[index];
                  final isSelected = _activePaper == paper;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _activePaper = paper);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: PaperBackgroundPainter(paper),
                            size: Size.infinite,
                          ),
                          if (isSelected)
                            const Positioned(
                              bottom: 5,
                              right: 5,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankMode() {
    return InteractiveViewer(
      transformationController: _imageTransformController,
      panEnabled: _activeTool == ToolType.pan,
      scaleEnabled: _activeTool == ToolType.pan,
      minScale: 0.5,
      maxScale: 5.0,
      onInteractionUpdate: (_) => setState(
        () => _pdfZoom = _imageTransformController.value.getMaxScaleOnAxis(),
      ),
      child: Center(
        child: GestureDetector(
          onPanStart: (d) {
            if (_activeTool != ToolType.pan) _startStroke(d.localPosition);
          },
          onPanUpdate: (d) {
            if (_activeTool != ToolType.pan) _updateStroke(d.localPosition);
          },
          child: Container(
            width: 850,
            height: 1200,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: PaperBackgroundPainter(_activePaper),
                  size: Size.infinite,
                ),
                CustomPaint(
                  painter: ProDrawingPainter(
                    strokes: _currentStrokes,
                    zoom: 1.0,
                    scroll: Offset.zero,
                  ),
                  size: Size.infinite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfMode() {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (_isPdfLoaded && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  try {
                    _pdfScroll = _pdfViewerController.scrollOffset;
                  } catch (e) {}
                });
              });
            }
            return false;
          },
          child: widget.fileBytes != null
              ? SfPdfViewer.memory(
                  widget.fileBytes!,
                  controller: _pdfViewerController,
                  pageLayoutMode: PdfPageLayoutMode.single,
                  canShowScrollHead: false,
                  onDocumentLoaded: (d) => setState(() {
                    _totalPages = d.document.pages.count;
                    _isPdfLoaded = true;
                  }),
                  onZoomLevelChanged: (d) =>
                      setState(() => _pdfZoom = d.newZoomLevel),
                  onPageChanged: (d) => setState(() {
                    _allPageStrokes[d.oldPageNumber] = List.from(
                      _currentStrokes,
                    );
                    _currentPage = d.newPageNumber;
                    _currentStrokes = _allPageStrokes[_currentPage] ?? [];
                  }),
                )
              : SfPdfViewer.file(
                  File(widget.filePath!),
                  controller: _pdfViewerController,
                  pageLayoutMode: PdfPageLayoutMode.single,
                  canShowScrollHead: false,
                  onDocumentLoaded: (d) => setState(() {
                    _totalPages = d.document.pages.count;
                    _isPdfLoaded = true;
                  }),
                  onZoomLevelChanged: (d) =>
                      setState(() => _pdfZoom = d.newZoomLevel),
                  onPageChanged: (d) => setState(() {
                    _allPageStrokes[d.oldPageNumber] = List.from(
                      _currentStrokes,
                    );
                    _currentPage = d.newPageNumber;
                    _currentStrokes = _allPageStrokes[_currentPage] ?? [];
                  }),
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _activeTool == ToolType.pan,
            child: GestureDetector(
              onPanStart: (details) =>
                  _startStroke((details.localPosition + _pdfScroll) / _pdfZoom),
              onPanUpdate: (details) => _updateStroke(
                (details.localPosition + _pdfScroll) / _pdfZoom,
              ),
              child: CustomPaint(
                painter: ProDrawingPainter(
                  strokes: _currentStrokes,
                  zoom: _pdfZoom,
                  scroll: _pdfScroll,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageMode() {
    return InteractiveViewer(
      transformationController: _imageTransformController,
      panEnabled: _activeTool == ToolType.pan,
      scaleEnabled: _activeTool == ToolType.pan,
      minScale: 0.5,
      maxScale: 5.0,
      onInteractionUpdate: (_) => setState(
        () => _pdfZoom = _imageTransformController.value.getMaxScaleOnAxis(),
      ),
      child: Center(
        child: GestureDetector(
          onPanStart: (d) {
            if (_activeTool != ToolType.pan) _startStroke(d.localPosition);
          },
          onPanUpdate: (d) {
            if (_activeTool != ToolType.pan) _updateStroke(d.localPosition);
          },
          child: Stack(
            children: [
              widget.fileBytes != null
                  ? Image.memory(widget.fileBytes!)
                  : Image.file(File(widget.filePath!)),
              Positioned.fill(
                child: CustomPaint(
                  painter: ProDrawingPainter(
                    strokes: _currentStrokes,
                    zoom: 1.0,
                    scroll: Offset.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isFullscreen)
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                color: const Color(0xFF1C1C22),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (_docMode == DocumentMode.blank)
                      IconButton(
                        icon: const Icon(
                          Icons.style_rounded,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        tooltip: "Choose Paper",
                        onPressed: _showPaperSelector,
                      ),

                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: _zoomOut,
                    ),
                    Text(
                      "${(_pdfZoom * 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: _zoomIn,
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() {
                        _isFullscreen = true;
                        _activeTool = ToolType.pan;
                        if (_showSettingsPanel) _toggleSettingsPanel();
                      }),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.undo_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: _undo,
                    ),
                    const SizedBox(width: 8),

                    PopupMenuButton<String>(
                      tooltip: "Save Options",
                      color: const Color(0xFF2A2A35),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      offset: const Offset(0, 40),
                      onSelected: (val) {
                        if (val == 'save') {
                          _processSaving(
                            fileName: widget.fileName,
                            path: "Original Folder",
                          );
                        } else if (val == 'save_as') {
                          _showSaveAsLocationDialog();
                        } else if (val == 'download') {
                          _downloadFileOnWeb(widget.fileName);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'save',
                          child: Row(
                            children: [
                              Icon(
                                Icons.save_rounded,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Save",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Overwrite original file",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'save_as',
                          child: Row(
                            children: [
                              Icon(
                                Icons.create_new_folder_rounded,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Save As...",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Choose location & rename",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(
                                Icons.download_rounded,
                                color: Colors.orangeAccent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Download",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Save to your device",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Text(
                              "Save",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.black87,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Stack(
                children: [
                  if (_docMode == DocumentMode.pdf)
                    _buildPdfMode()
                  else if (_docMode == DocumentMode.image)
                    _buildImageMode()
                  else
                    _buildBlankMode(),

                  Positioned(
                    bottom: 15,
                    left: 30,
                    right: 30,
                    child: SizeTransition(
                      sizeFactor: _panelAnimation,
                      axisAlignment: -1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.line_weight_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.0,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6.0,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 12.0,
                                          ),
                                    ),
                                    child: Slider(
                                      value: _toolWidths[_activeTool]!,
                                      min: 1.0,
                                      max:
                                          (_activeTool ==
                                                  ToolType.highlighter ||
                                              _activeTool == ToolType.eraser)
                                          ? 50.0
                                          : 15.0,
                                      activeColor: _activeColor,
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(
                                        () => _toolWidths[_activeTool] = v,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 25,
                                  child: Text(
                                    _toolWidths[_activeTool]!
                                        .toInt()
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_activeTool != ToolType.eraser &&
                                _activeTool != ToolType.straightLine &&
                                _activeTool != ToolType.pan) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.opacity_rounded,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2.0,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6.0,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 12.0,
                                            ),
                                      ),
                                      child: Slider(
                                        value: _toolOpacities[_activeTool]!,
                                        min: 0.1,
                                        max: 1.0,
                                        activeColor: _activeColor.withOpacity(
                                          _toolOpacities[_activeTool]!,
                                        ),
                                        inactiveColor: Colors.white12,
                                        onChanged: (v) => setState(
                                          () => _toolOpacities[_activeTool] = v,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      "${(_toolOpacities[_activeTool]! * 100).toInt()}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_isFullscreen)
                    Positioned(
                      top: 15,
                      right: 15,
                      child: FloatingActionButton(
                        heroTag: "exitFS",
                        mini: true,
                        backgroundColor: const Color(
                          0xFF1C1C22,
                        ).withOpacity(0.8),
                        child: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _isFullscreen = false),
                      ),
                    ),
                  if (_isFullscreen)
                    Positioned(
                      bottom: 20,
                      right: 15,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton(
                            heroTag: "zoomIn",
                            mini: true,
                            backgroundColor: const Color(
                              0xFF1C1C22,
                            ).withOpacity(0.8),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _zoomIn,
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            heroTag: "zoomOut",
                            mini: true,
                            backgroundColor: const Color(
                              0xFF1C1C22,
                            ).withOpacity(0.8),
                            child: const Icon(
                              Icons.remove_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _zoomOut,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (!_isFullscreen)
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1C22),
                  border: Border(
                    top: BorderSide(color: Colors.white10, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_activeTool != ToolType.eraser &&
                        _activeTool != ToolType.pan)
                      Container(
                        height: 20,
                        margin: const EdgeInsets.only(bottom: 5),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _palette.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final color = _palette[index];
                            final isSel = _activeColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _activeColor = color),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: isSel ? 20 : 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMainTool(Icons.pan_tool_rounded, ToolType.pan),
                        _buildMainTool(Icons.edit_rounded, ToolType.pen),
                        _buildMainTool(Icons.gesture_rounded, ToolType.pencil),
                        _buildMainTool(
                          Icons.format_color_fill_rounded,
                          ToolType.highlighter,
                        ),
                        _buildMainTool(
                          Icons.straighten_rounded,
                          ToolType.straightLine,
                        ),
                        _buildMainTool(
                          Icons.cleaning_services_rounded,
                          ToolType.eraser,
                        ),
                        if (_docMode == DocumentMode.pdf) ...[
                          Container(
                            width: 1,
                            height: 25,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                          ),
                          GestureDetector(
                            onTap: () => _changePage(_currentPage - 1),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white54,
                              size: 28,
                            ),
                          ),
                          Text(
                            "$_currentPage/$_totalPages",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _changePage(_currentPage + 1),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white54,
                              size: 28,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTool(IconData icon, ToolType type) {
    bool isSelected = _activeTool == type;
    return GestureDetector(
      onTap: () {
        if (isSelected && type != ToolType.pan) {
          _toggleSettingsPanel();
        } else {
          setState(() {
            _activeTool = type;
            if (_showSettingsPanel) _toggleSettingsPanel();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? (_activeColor == Colors.black
                    ? Colors.white24
                    : _activeColor.withOpacity(0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? (_activeColor == Colors.black ? Colors.white : _activeColor)
              : Colors.white54,
          size: 22,
        ),
      ),
    );
  }
}

class PaperBackgroundPainter extends CustomPainter {
  final PaperStyle style;
  PaperBackgroundPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..color = style.backgroundColor);

    if (style.pattern == 'ruled') {
      final linePaint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 1.5;
      for (double i = 80; i < size.height; i += 35)
        canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
      canvas.drawLine(
        Offset(70, 0),
        Offset(70, size.height),
        Paint()
          ..color = Colors.red.withOpacity(0.4)
          ..strokeWidth = 1.5,
      );
    } else if (style.pattern == 'grid') {
      final gridPaint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 1.0;
      for (double i = 0; i < size.height; i += 25)
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      for (double i = 0; i < size.width; i += 25)
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    } else if (style.pattern == 'dotted') {
      // 👈 موتور رسم کاغذ نقطه‌ای
      final dotPaint = Paint()
        ..color = style.lineColor
        ..style = PaintingStyle.fill;
      for (double y = 25; y < size.height; y += 25) {
        for (double x = 25; x < size.width; x += 25) {
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    } else if (style.pattern == 'cornell') {
      // 👈 موتور رسم کاغذ یادداشت‌برداری کُرنل
      final cPaint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(0, 120),
        Offset(size.width, 120),
        cPaint,
      ); // خط بالای صفحه (Title)
      canvas.drawLine(
        Offset(100, 120),
        Offset(100, size.height - 150),
        cPaint,
      ); // خط حاشیه چپ (Cue Column)
      canvas.drawLine(
        Offset(0, size.height - 150),
        Offset(size.width, size.height - 150),
        cPaint,
      ); // خط پایین (Summary)
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final double zoom;
  final Offset scroll;
  ProDrawingPainter({
    required this.strokes,
    required this.zoom,
    required this.scroll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.translate(-scroll.dx, -scroll.dy);
    canvas.scale(zoom);

    for (var stroke in strokes) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.weight;
      switch (stroke.toolType) {
        case ToolType.pen:
          paint.color = stroke.color.withOpacity(stroke.opacity);
          paint.strokeCap = StrokeCap.round;
          paint.strokeJoin = StrokeJoin.round;
          break;
        case ToolType.pencil:
          paint.color = stroke.color.withOpacity(stroke.opacity);
          paint.strokeCap = StrokeCap.square;
          break;
        case ToolType.highlighter:
          paint.color = stroke.color.withOpacity(stroke.opacity);
          paint.blendMode = BlendMode.multiply;
          paint.strokeCap = StrokeCap.round;
          paint.strokeJoin = StrokeJoin.round;
          break;
        case ToolType.straightLine:
          paint.color = stroke.color.withOpacity(stroke.opacity);
          paint.strokeCap = StrokeCap.round;
          break;
        case ToolType.eraser:
          paint.color = Colors.transparent;
          paint.blendMode = BlendMode.clear;
          paint.strokeCap = StrokeCap.round;
          paint.strokeJoin = StrokeJoin.round;
          break;
        default:
          break;
      }
      if (stroke.points.isEmpty) continue;
      if (stroke.toolType == ToolType.straightLine &&
          stroke.points.length > 1) {
        canvas.drawLine(stroke.points.first, stroke.points.last, paint);
      } else if (stroke.points.length > 1) {
        final path = Path()
          ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final p0 = stroke.points[i],
              p1 = stroke.points[i + 1],
              mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
          if (i == stroke.points.length - 2)
            path.quadraticBezierTo(p0.dx, p0.dy, p1.dx, p1.dy);
          else
            path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        }
        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(stroke.points.first, stroke.points.first, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

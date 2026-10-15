import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'homework_solver_screen.dart';

class PaperSelectorScreen extends StatelessWidget {
  const PaperSelectorScreen({super.key});

  // 👈 لیست ۹ قالب جذاب با کاغذهای جدید
  List<PaperStyle> get _templates => [
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
    ), // 👈 کاغذ نقطه‌ای
    PaperStyle(
      name: "Cornell",
      backgroundColor: Colors.white,
      pattern: 'cornell',
      lineColor: Colors.red.withOpacity(0.5),
    ), // 👈 کاغذ دانشگاهی کُرنل
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
    ), // 👈 کاغذ کاهی
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white54,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notebook Gallery",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Text(
              "Choose a template to start writing...",
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 👈 تغییر به ۳ ستون برای کوچیک شدن کارت‌ها
                childAspectRatio: 0.72,
                crossAxisSpacing: 15, // فاصله کمتر شد
                mainAxisSpacing: 25,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final paper = _templates[index];
                return _buildNotebookCard(context, paper, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookCard(BuildContext context, PaperStyle paper, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeworkSolverScreen(
              fileName: "New Note",
              selectedPaper: paper,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: paper.backgroundColor == Colors.white
                        ? const Color(0x1AFFFFFF)
                        : Colors.black54,
                    blurRadius: 15,
                    offset: const Offset(4, 8),
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
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x99000000),
                            Color(0x33000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeworkSolverScreen(
                                fileName: "New Note",
                                selectedPaper: paper,
                              ),
                            ),
                          );
                        },
                        splashColor: const Color(0x1A000000),
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            paper.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class SeedService {
  // ==============================================================
  // 📚 دیتای کلمات (Vocab Master)
  // ==============================================================
  static const List<Map<String, dynamic>> _rawWords = [
    // کلمات رو اینجا اضافه کن
  ];

  // ==============================================================
  // ⚖️ دیتای بازی (Fact vs Fake)
  // ==============================================================
  static const List<Map<String, dynamic>> _rawScenarios = [
    // سناریوها رو اینجا اضافه کن
  ];

  // ==============================================================
  // 🚀 دیتای تندخوانی (Speed Reading)
  // ==============================================================
  static const List<Map<String, dynamic>> _rawSpeedReading = [
    {
      "title": "The Falcon's Dive",
      "content":
          "The peregrine falcon is the fastest bird in the world. It is capable of reaching speeds over 200 miles per hour during its characteristic hunting stoop. This incredible speed is achieved through a combination of a streamlined body shape and powerful chest muscles.",
      "question": "What is the top speed of a peregrine falcon during a dive?",
      "options": ["100 mph", "150 mph", "Over 200 mph", "300 mph"],
      "correct_index": 2,
      "xp": 50,
      "difficulty": "medium",
    },
    {
      "title": "Ocean's Depths",
      "content":
          "The Mariana Trench is the deepest part of the world's oceans. It is located in the western Pacific Ocean. The maximum known depth is about 36,000 feet. Very few humans have ever descended to its bottom.",
      "question": "Where is the Mariana Trench located?",
      "options": [
        "Atlantic Ocean",
        "Indian Ocean",
        "Western Pacific Ocean",
        "Arctic Ocean",
      ],
      "correct_index": 2,
      "xp": 40,
      "difficulty": "easy",
    },
  ];

  // ==============================================================
  // 🧠 موتور تزریق هوشمند (Smart Seed PRO)
  // ==============================================================
  static Future<void> smartSeed() async {
    print("🧠 Initiating Smart Seed...");
    bool seededSomething = false;

    if (_rawWords.isNotEmpty) {
      await uploadWords();
      seededSomething = true;
    }
    if (_rawScenarios.isNotEmpty) {
      await uploadFactVsFake();
      seededSomething = true;
    }
    // 🔥 اضافه شدن بخش تندخوانی به تزریق هوشمند
    if (_rawSpeedReading.isNotEmpty) {
      await uploadSpeedReading();
      seededSomething = true;
    }

    if (!seededSomething) {
      print("🤷‍♂️ All lists are empty. Nothing to inject!");
    } else {
      print("✨ Smart Seed completed successfully!");
    }
  }

  // ==============================================================
  // ⚙️ متدهای تزریق اختصاصی
  // ==============================================================
  static Future<void> uploadWords() async {
    if (_rawWords.isEmpty) return;
    final supabase = Supabase.instance.client;
    int inserted = 0;
    int skipped = 0;
    int failed = 0;
    List<Map<String, dynamic>> errorLog = [];

    for (var data in _rawWords) {
      try {
        final existing = await supabase
            .from('words')
            .select('word')
            .eq('word', data['word'])
            .maybeSingle();
        if (existing != null) {
          skipped++;
          continue;
        }
        await supabase.from('words').insert(data);
        inserted++;
      } catch (e) {
        failed++;
        errorLog.add({"error": e.toString()});
      }
    }
    _printReport(
      "WORDS",
      inserted,
      skipped,
      failed,
      _rawWords.length,
      errorLog,
    );
  }

  static Future<void> uploadFactVsFake() async {
    if (_rawScenarios.isEmpty) return;
    final supabase = Supabase.instance.client;
    int inserted = 0;
    int skipped = 0;
    int failed = 0;
    List<Map<String, dynamic>> errorLog = [];

    for (var data in _rawScenarios) {
      try {
        final existing = await supabase
            .from('fact_vs_fake')
            .select('statement')
            .eq('statement', data['statement'])
            .maybeSingle();
        if (existing != null) {
          skipped++;
          continue;
        }
        await supabase.from('fact_vs_fake').insert(data);
        inserted++;
      } catch (e) {
        failed++;
        errorLog.add({"error": e.toString()});
      }
    }
    _printReport(
      "FACT VS FAKE",
      inserted,
      skipped,
      failed,
      _rawScenarios.length,
      errorLog,
    );
  }

  // 🔥 متد جدید برای تزریق داستان‌های تندخوانی
  static Future<void> uploadSpeedReading() async {
    if (_rawSpeedReading.isEmpty) return;
    final supabase = Supabase.instance.client;
    print("🚀 Starting Speed Reading seed process...");
    int inserted = 0;
    int skipped = 0;
    int failed = 0;
    List<Map<String, dynamic>> errorLog = [];

    for (var data in _rawSpeedReading) {
      try {
        final existing = await supabase
            .from('speed_reading')
            .select('title')
            .eq('title', data['title'])
            .maybeSingle();
        if (existing != null) {
          skipped++;
          continue;
        }

        await supabase.from('speed_reading').insert({
          'title': data['title'],
          'content': data['content'],
          'question': data['question'],
          'options': data['options'], // به صورت لیست jsonb ارسال میشه
          'correct_index': data['correct_index'],
          'xp': data['xp'] ?? 50,
          'difficulty': data['difficulty'] ?? 'medium',
        });
        print("✅ Story inserted");
        inserted++;
      } catch (e) {
        errorLog.add({"title": data['title'], "error": e.toString()});
        failed++;
      }
    }
    _printReport(
      "SPEED READING",
      inserted,
      skipped,
      failed,
      _rawSpeedReading.length,
      errorLog,
    );
  }

  static void _printReport(
    String title,
    int inserted,
    int skipped,
    int failed,
    int total,
    List<Map<String, dynamic>> errorLog,
  ) {
    print("\n📊 ===== $title FINAL REPORT =====");
    print("✅ Inserted: $inserted");
    print("⚠️ Skipped: $skipped");
    print("❌ Failed: $failed");
    print("📦 Total: $total");
    if (errorLog.isNotEmpty) {
      for (var e in errorLog) print("🧨 $e");
    }
    print("===========================\n");
  }
}

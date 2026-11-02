class Book {
  final String id;
  final String title;
  final String level;
  final String coverImage;
  final int xpReward;
  final int timeReward;
  final String minAge;
  final String category;
  final List<String> pages;
  final List<String> pageTexts;
  final List<Map<String, dynamic>> quiz;

  // 🌱 اینجا رو مشخص کردیم که حتماً لیستی از متن (String) باشه
  final List<String> vocabulary;

  Book({
    required this.id,
    required this.title,
    required this.level,
    required this.coverImage,
    required this.xpReward,
    required this.timeReward,
    required this.minAge,
    required this.category,
    required this.pages,
    required this.pageTexts,
    required this.quiz,
    this.vocabulary = const [],
  });

  /// Builds a book from a `books` row. Fields without their own column
  /// (level, minAge, pageTexts) live in `extra`.
  factory Book.fromRow(Map<String, dynamic> r) {
    final extra = r['extra'] is Map
        ? Map<String, dynamic>.from(r['extra'] as Map)
        : <String, dynamic>{};
    List<String> strings(Object? v) =>
        v is Iterable ? v.map((e) => e.toString()).toList() : <String>[];
    int number(Object? v, int fallback) =>
        v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? fallback;

    return Book(
      id: r['id']?.toString() ?? '',
      title: r['title']?.toString() ?? '',
      level: extra['level']?.toString() ?? 'Easy',
      coverImage: r['cover_url']?.toString() ?? '',
      xpReward: number(r['xp_reward'], 0),
      timeReward: number(r['time_reward'], 10),
      minAge: extra['minAge']?.toString() ??
          (r['min_age'] != null ? '${r['min_age']}+' : '4+'),
      category: r['category']?.toString() ?? 'Kids',
      pages: strings(r['pages']),
      pageTexts: strings(extra['pageTexts']),
      quiz: r['quiz'] is Iterable
          ? (r['quiz'] as Iterable)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
          : <Map<String, dynamic>>[],
      vocabulary: strings(r['vocabulary']),
    );
  }

  /// Turns the admin uploader's JSON (same keys as the old Firestore
  /// documents) into a `books` row.
  static Map<String, dynamic> rowFromJson(Map<String, dynamic> j) {
    final minAgeText = j['minAge']?.toString();
    return <String, dynamic>{
      'title': j['title']?.toString() ?? '',
      'category': j['category']?.toString(),
      'cover_url': j['coverImage']?.toString(),
      'min_age': int.tryParse(
        (minAgeText ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
      ),
      'pages': j['pages'] ?? [],
      'quiz': j['quiz'] ?? [],
      'vocabulary': j['vocabulary'] ?? [],
      'xp_reward': (j['xpReward'] as num?)?.toInt() ?? 0,
      'time_reward': (j['timeReward'] as num?)?.toInt() ?? 0,
      'extra': {
        'level': j['level'],
        'minAge': minAgeText,
        'pageTexts': j['pageTexts'] ?? [],
      },
    };
  }
}

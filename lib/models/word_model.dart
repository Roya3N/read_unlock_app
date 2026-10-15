class WordModel {
  final String word;
  final String type;
  final String phonetic;
  final String definition;
  final String example;
  final String level;
  final String category;
  final List<String> tags;
  final List<String> synonyms;
  final List<String> antonyms;
  final String imageUrl;
  final String audioUrl;

  WordModel({
    required this.word,
    required this.type,
    required this.phonetic,
    required this.definition,
    required this.example,
    this.level = '',
    this.category = '',
    this.tags = const [],
    this.synonyms = const [],
    this.antonyms = const [],
    required this.imageUrl,
    required this.audioUrl,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    // 🛡️ safe parsing
    List<String> parsedTags =
        (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];

    List<String> parsedSynonyms =
        (json['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [];

    List<String> parsedAntonyms =
        (json['antonyms'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return WordModel(
      word: json['word'] ?? '',
      type: json['type'] ?? '',
      phonetic: json['phonetic'] ?? '',
      definition: json['definition'] ?? '',
      example: json['example'] ?? '',
      level: json['level'] ?? '',
      category: json['category'] ?? '',
      tags: parsedTags,
      synonyms: parsedSynonyms,
      antonyms: parsedAntonyms,
      imageUrl:
          json['image_url'] ??
          json['imageUrl'] ??
          'https://picsum.photos/600/400',
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? '',
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      level: data['level'] ?? 'Easy',
      coverImage: data['coverImage'] ?? '',
      xpReward: data['xpReward'] ?? 0,
      timeReward: data['timeReward'] ?? 10,
      minAge: data['minAge']?.toString() ?? '4+',
      category: data['category'] ?? 'Kids',
      pages: List<String>.from(data['pages'] ?? []),
      pageTexts: List<String>.from(data['pageTexts'] ?? []),
      quiz: List<Map<String, dynamic>>.from(data['quiz'] ?? []),

      // 🪄 آپگرید طلایی: تبدیل دقیق دیتای فایربیس به لیست کلمات
      vocabulary: data['vocabulary'] is Iterable
          ? List<String>.from(data['vocabulary'])
          : [],
    );
  }
}

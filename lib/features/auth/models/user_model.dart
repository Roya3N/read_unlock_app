class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'parent' یا 'child'
  final int score;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.score = 0,
  });

  // تبدیل اطلاعات دیتابیس (JSON/Map) به آبجکت دارت
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      score: map['score'] ?? 0,
    );
  }

  // تبدیل آبجکت دارت به فرمت قابل فهم برای فایربیس
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'role': role, 'score': score};
  }
}

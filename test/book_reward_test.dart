import 'package:flutter_test/flutter_test.dart';
import 'package:read_unlock_app/core/utils/book_reward.dart';

void main() {
  BookRewardDecision decide({
    bool alreadyRead = false,
    int secondsSpent = 600,
    int pageCount = 10,
    int xpReward = 50,
    int timeReward = 10,
    int correctAnswers = 0,
  }) {
    return BookRewardRules.decide(
      alreadyRead: alreadyRead,
      secondsSpent: secondsSpent,
      pageCount: pageCount,
      xpReward: xpReward,
      timeReward: timeReward,
      correctAnswers: correctAnswers,
    );
  }

  test('first read gives XP, quiz bonus and minutes', () {
    final d = decide(correctAnswers: 3);
    expect(d.granted, isTrue);
    expect(d.firstRead, isTrue);
    expect(d.xp, 50 + 3 * BookRewardRules.xpPerCorrectAnswer);
    expect(d.minutes, 10);
  });

  test('reading too fast gives nothing', () {
    final d = decide(secondsSpent: 49, pageCount: 10);
    expect(d.granted, isFalse);
    expect(d.xp, 0);
    expect(d.minutes, 0);
    expect(d.rejectionMessage, isNotNull);
  });

  test('exactly the minimum time is accepted', () {
    expect(decide(secondsSpent: 50, pageCount: 10).granted, isTrue);
  });

  test('re-reading gives 1 XP and no minutes', () {
    final d = decide(alreadyRead: true, correctAnswers: 5);
    expect(d.granted, isTrue);
    expect(d.firstRead, isFalse);
    expect(d.xp, BookRewardRules.repeatReadXp);
    expect(d.minutes, 0);
  });

  test('negative inputs never produce negative rewards', () {
    final d = decide(xpReward: -10, timeReward: -5, correctAnswers: -2);
    expect(d.xp, 0);
    expect(d.minutes, 0);
  });
}

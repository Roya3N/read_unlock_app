/// Pure reward rules for finishing a book, kept free of the backend so they can
/// be unit tested.
class BookRewardDecision {
  final bool granted;
  final bool firstRead;
  final int xp;
  final int minutes;
  final String? rejectionMessage;

  const BookRewardDecision._({
    required this.granted,
    required this.firstRead,
    required this.xp,
    required this.minutes,
    this.rejectionMessage,
  });

  /// What the server granted (see finish_reading in the Supabase
  /// migrations, which applies [BookRewardRules]).
  const BookRewardDecision.fromServer({
    required bool firstRead,
    required int xp,
    required int minutes,
  }) : this._(granted: true, firstRead: firstRead, xp: xp, minutes: minutes);

  const BookRewardDecision.rejected(String message)
    : this._(
        granted: false,
        firstRead: false,
        xp: 0,
        minutes: 0,
        rejectionMessage: message,
      );
}

class BookRewardRules {
  /// Minimum reading time per page before a reward is given.
  static const int minSecondsPerPage = 5;

  /// XP for re-reading a book that was already rewarded. No minutes.
  static const int repeatReadXp = 1;

  /// Extra XP per correct quiz answer on a first read.
  static const int xpPerCorrectAnswer = 2;

  static BookRewardDecision decide({
    required bool alreadyRead,
    required int secondsSpent,
    required int pageCount,
    required int xpReward,
    required int timeReward,
    required int correctAnswers,
  }) {
    if (secondsSpent < pageCount * minSecondsPerPage) {
      return const BookRewardDecision.rejected(
        "You read too fast! Take your time to earn rewards. 🐢",
      );
    }

    if (alreadyRead) {
      return const BookRewardDecision._(
        granted: true,
        firstRead: false,
        xp: repeatReadXp,
        minutes: 0,
      );
    }

    final safeXp = xpReward < 0 ? 0 : xpReward;
    final safeMinutes = timeReward < 0 ? 0 : timeReward;
    final bonus =
        (correctAnswers < 0 ? 0 : correctAnswers) * xpPerCorrectAnswer;

    return BookRewardDecision._(
      granted: true,
      firstRead: true,
      xp: safeXp + bonus,
      minutes: safeMinutes,
    );
  }
}

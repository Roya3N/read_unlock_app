/// Pure screen-time rules, kept free of the backend so they can be tested.
class ScreenTimeRules {
  /// Daily limit choices a parent can pick. 0 means no daily limit.
  static const List<int> dailyLimitChoices = [0, 30, 45, 60, 90, 120, 180];

  /// Minutes the child may start right now: never more than the balance,
  /// and never past the parent's daily limit (0 = no limit).
  static int availableNow({
    required int balance,
    required int dailyLimit,
    required int usedToday,
  }) {
    final safeBalance = balance < 0 ? 0 : balance;
    if (dailyLimit <= 0) return safeBalance;
    final leftToday = dailyLimit - (usedToday < 0 ? 0 : usedToday);
    if (leftToday <= 0) return 0;
    return leftToday < safeBalance ? leftToday : safeBalance;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:read_unlock_app/core/utils/screen_time_rules.dart';

void main() {
  int avail(int balance, int limit, int used) => ScreenTimeRules.availableNow(
    balance: balance,
    dailyLimit: limit,
    usedToday: used,
  );

  test('no limit: whole balance is available', () {
    expect(avail(100, 0, 500), 100);
  });

  test('limit caps what can be started today', () {
    expect(avail(100, 60, 20), 40);
  });

  test('balance caps when it is smaller than what is left today', () {
    expect(avail(10, 60, 20), 10);
  });

  test('limit reached or passed gives 0', () {
    expect(avail(100, 60, 60), 0);
    expect(avail(100, 60, 75), 0);
  });

  test('negative values never give negative minutes', () {
    expect(avail(-5, 0, 0), 0);
    expect(avail(30, 60, -10), 30);
  });
}

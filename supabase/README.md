# Supabase

The app is moving from Firebase to Supabase in stages (one PR each):
schema and security, server reward functions, sign-in, app code, data copy,
then retiring Firebase.

## Migrations

`migrations/` holds the SQL, applied in file-name order. Every file is safe to
run twice and none deletes data. Apply a file by pasting it into the Supabase
SQL Editor, only after its PR is approved.

## Where Firestore data goes

| Firestore | Supabase |
| --- | --- |
| `parents/{uid}` | `parents` (row created on sign-up by a trigger) |
| `parents/{uid}/children/{id}` | `children` |
| `readBooksHistory` on a child | `read_books` |
| `children/{id}/daily_activity/{day}` | `daily_activity` (`learning_minutes` and `screen_minutes` kept apart) |
| `children/{id}/letters/{letter}` | `letters` |
| `books` | `books` (`firestore_id` keeps the old id) |
| `config/economy`, `config/global` | `app_config` rows `economy`, `global` |
| `game_settings/*` | `game_settings` |
| `system_logs` | `system_logs` |
| `leaderboard` | not needed: `leaderboard_top()` reads `children` |
| admin email in rules | `admins` table |

XP, time balance and unlocks can't be changed from the app directly. They
change only through server functions that record each reward in
`reward_events` with a unique key, so the same reward can't be claimed twice.

## Server functions (stage 2)

| Function | Replaces in the app |
| --- | --- |
| `start_reading`, `finish_reading` | `ReadingController.claimBookReward` (server clock decides reading time) |
| `log_activity` | `ProgressService.logActivity` (game XP capped per game and per day; games give no minutes) |
| `save_record` | personal bests in `records` |
| `complete_letter` | letter journey big reward and sticker card |
| `buy_minutes`, `buy_avatar` | shop purchases (prices from `app_config.economy` and `shop_items`) |
| `start_screen_session`, `end_screen_session` | time wallet timer and refund |
| `parent_adjust` | parent gift dialog |
| `admin_set_child_rewards` | admin users screen |

Settings read from `app_config` row `economy` (defaults in brackets):
`minute_cost_xp` (5), `activity_xp_cap` (100), `daily_activity_xp_cap`
(1000), `letter_reward_xp` (50), `letter_reward_minutes` (10). The daily
limit resets at midnight in `parents.timezone` (UTC by default).

## Tests

`tests/run_local.sh` applies all migrations (twice) to a throwaway local
Postgres with a stub of Supabase's `auth` schema, then runs every `tests/*_test.sql`. CI runs it on every PR. Set `PGHOST`, `PGPORT`,
`PGUSER` first. Never point it at the real project.

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

## Tests

`tests/run_local.sh` applies all migrations (twice) to a throwaway local
Postgres with a stub of Supabase's `auth` schema, then runs the RLS tests in
`tests/schema_rls_test.sql`. CI runs it on every PR. Set `PGHOST`, `PGPORT`,
`PGUSER` first. Never point it at the real project.

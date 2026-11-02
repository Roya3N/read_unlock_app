#!/usr/bin/env bash
# Applies every migration to a throwaway local Postgres (with a stub of
# Supabase's auth schema) and runs the RLS tests. Needs psql and a running
# Postgres; set PGHOST/PGPORT/PGUSER. Never point this at the real project.
set -euo pipefail
cd "$(dirname "$0")/.."
DB=rls_test_$$
createdb "$DB"
trap 'dropdb --if-exists "$DB"' EXIT
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f tests/local_stub.sql
for f in migrations/*.sql; do
  echo "apply $f"
  PGOPTIONS="-c client_min_messages=warning" psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$f"
  # Migrations must be safe to run twice.
  PGOPTIONS="-c client_min_messages=warning" psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$f"
done
for t in tests/*_test.sql; do
  echo "run $t"
  psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$t"
done

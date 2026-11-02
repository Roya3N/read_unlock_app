-- Shared test helpers, loaded with \i by each *_test.sql file.
set client_min_messages = warning;

-- Helper: run a statement as a role/user and report whether it was allowed.
create or replace function pg_temp.try(p_role text, p_uid text, p_sql text)
returns text language plpgsql as $$
declare n bigint;
begin
  execute format('set local role %I', p_role);
  perform set_config('request.jwt.claim.sub', coalesce(p_uid, ''), true);
  execute p_sql;
  get diagnostics n = row_count;
  reset role;
  return 'ok:' || n;
exception when others then
  reset role;
  return 'denied';
end $$;

create or replace function pg_temp.expect(p_name text, p_got text, p_want text)
returns void language plpgsql as $$
begin
  if p_got is distinct from p_want then
    raise exception 'FAIL %: got %, want %', p_name, p_got, p_want;
  end if;
  raise notice 'pass  %', p_name;
end $$;

-- Run a query as a user and return its single value as text, or the error.
create or replace function pg_temp.val(p_uid text, p_sql text)
returns text language plpgsql as $$
declare v text;
begin
  set local role authenticated;
  perform set_config('request.jwt.claim.sub', coalesce(p_uid, ''), true);
  execute p_sql into v;
  reset role;
  return v;
exception when others then
  reset role;
  return 'error: ' || sqlerrm;
end $$;

set client_min_messages = notice;

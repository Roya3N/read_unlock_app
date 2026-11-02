-- RLS and privilege tests for the app schema. Run with supabase/tests/run_local.sh.
\set ON_ERROR_STOP 1
\o /dev/null
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
set client_min_messages = notice;

-- Two families and an admin.
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test', '{"name":"Parent A"}'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test', '{}'),
  ('00000000-0000-0000-0000-0000000000ad', 'admin@test', '{}');
insert into public.admins values ('00000000-0000-0000-0000-0000000000ad');
insert into public.children (id, parent_id, name, xp, time_balance) values
  ('11111111-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'Sara Ahmadi', 120, 30),
  ('11111111-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'Ali', 300, 10);

\set A '''00000000-0000-0000-0000-00000000000a'''
\set B '''00000000-0000-0000-0000-00000000000b'''
\set AD '''00000000-0000-0000-0000-0000000000ad'''
\set CA '''11111111-0000-0000-0000-00000000000a'''
\set CB '''11111111-0000-0000-0000-00000000000b'''

begin;
select pg_temp.expect('signup trigger creates parent row with name',
  (select name from public.parents where id = :A), 'Parent A');

-- Parents
select pg_temp.expect('parent sees only own parent row',
  pg_temp.try('authenticated', :A, 'select * from public.parents'), 'ok:1');
select pg_temp.expect('parent can set own PIN hash',
  pg_temp.try('authenticated', :A, 'update public.parents set pin_hash = ''h''  where id = ' || quote_literal(:A)), 'ok:1');
select pg_temp.expect('parent cannot change another parent',
  pg_temp.try('authenticated', :A, 'update public.parents set name = ''x'' where id = ' || quote_literal(:B)), 'ok:0');
select pg_temp.expect('parent cannot change own email column',
  pg_temp.try('authenticated', :A, 'update public.parents set email = ''x'' where id = ' || quote_literal(:A)), 'denied');
select pg_temp.expect('anon cannot read parents',
  pg_temp.try('anon', null, 'select * from public.parents'), 'denied');

-- Children
select pg_temp.expect('parent sees only own children',
  pg_temp.try('authenticated', :A, 'select * from public.children'), 'ok:1');
select pg_temp.expect('parent cannot read other family child',
  pg_temp.try('authenticated', :A, 'select * from public.children where id = ' || quote_literal(:CB)), 'ok:0');
select pg_temp.expect('parent can add a child',
  pg_temp.try('authenticated', :A, 'insert into public.children (parent_id, name) values (' || quote_literal(:A) || ', ''Nika'')'), 'ok:1');
select pg_temp.expect('new child starts at 0 xp and 0 minutes',
  (select xp || '/' || time_balance from public.children where name = 'Nika'), '0/0');
select pg_temp.expect('parent cannot add a child to another family',
  pg_temp.try('authenticated', :A, 'insert into public.children (parent_id, name) values (' || quote_literal(:B) || ', ''X'')'), 'denied');
select pg_temp.expect('parent cannot insert a child with xp',
  pg_temp.try('authenticated', :A, 'insert into public.children (parent_id, name, xp) values (' || quote_literal(:A) || ', ''X'', 999)'), 'denied');
select pg_temp.expect('client cannot set xp',
  pg_temp.try('authenticated', :A, 'update public.children set xp = 99999 where id = ' || quote_literal(:CA)), 'denied');
select pg_temp.expect('client cannot set time_balance',
  pg_temp.try('authenticated', :A, 'update public.children set time_balance = 999 where id = ' || quote_literal(:CA)), 'denied');
select pg_temp.expect('client cannot unlock avatars directly',
  pg_temp.try('authenticated', :A, 'update public.children set unlocked_avatars = ''{dragon}'' where id = ' || quote_literal(:CA)), 'denied');
select pg_temp.expect('parent can set daily limit',
  pg_temp.try('authenticated', :A, 'update public.children set daily_limit_minutes = 60 where id = ' || quote_literal(:CA)), 'ok:1');
select pg_temp.expect('daily limit above 1440 rejected',
  pg_temp.try('authenticated', :A, 'update public.children set daily_limit_minutes = 5000 where id = ' || quote_literal(:CA)), 'denied');
select pg_temp.expect('parent cannot rename other family child',
  pg_temp.try('authenticated', :A, 'update public.children set name = ''x'' where id = ' || quote_literal(:CB)), 'ok:0');
select pg_temp.expect('parent cannot move child to another family',
  pg_temp.try('authenticated', :A, 'update public.children set parent_id = ' || quote_literal(:B) || ' where id = ' || quote_literal(:CA)), 'denied');
select pg_temp.expect('parent cannot delete other family child',
  pg_temp.try('authenticated', :A, 'delete from public.children where id = ' || quote_literal(:CB)), 'ok:0');
select pg_temp.expect('admin can read all children',
  pg_temp.try('authenticated', :AD, 'select * from public.children'), 'ok:3');
select pg_temp.expect('admin still cannot set xp directly',
  pg_temp.try('authenticated', :AD, 'update public.children set xp = 1 where id = ' || quote_literal(:CA)), 'denied');

-- Server-written tables are read-only for clients
select pg_temp.expect('client cannot write reward ledger',
  pg_temp.try('authenticated', :A, 'insert into public.reward_events (child_id, idempotency_key, source, xp_delta) values (' || quote_literal(:CA) || ', ''k'', ''x'', 500)'), 'denied');
select pg_temp.expect('client cannot mark book read',
  pg_temp.try('authenticated', :A, 'insert into public.read_books values (' || quote_literal(:CA) || ', ''b1'')'), 'denied');
select pg_temp.expect('client cannot write daily activity',
  pg_temp.try('authenticated', :A, 'insert into public.daily_activity (child_id, day) values (' || quote_literal(:CA) || ', current_date)'), 'denied');
select pg_temp.expect('client cannot open screen sessions',
  pg_temp.try('authenticated', :A, 'insert into public.screen_sessions (child_id, minutes_bought, ends_at) values (' || quote_literal(:CA) || ', 10, now())'), 'denied');
insert into public.reward_events (child_id, idempotency_key, source, xp_delta)
  values (:CA, 'book:1', 'reading', 50), (:CB, 'book:1', 'reading', 50);
select pg_temp.expect('parent reads only own ledger',
  pg_temp.try('authenticated', :A, 'select * from public.reward_events'), 'ok:1');
select pg_temp.expect('same reward key cannot be stored twice',
  pg_temp.try('postgres', null, 'insert into public.reward_events (child_id, idempotency_key, source) values (' || quote_literal(:CA) || ', ''book:1'', ''reading'')'), 'denied');

-- Letters
select pg_temp.expect('parent can save letter progress',
  pg_temp.try('authenticated', :A, 'insert into public.letters (child_id, letter, level) values (' || quote_literal(:CA) || ', ''A'', 1)'), 'ok:1');
select pg_temp.expect('parent cannot save letters for other family',
  pg_temp.try('authenticated', :A, 'insert into public.letters (child_id, letter, level) values (' || quote_literal(:CB) || ', ''A'', 1)'), 'denied');

-- Content and config
insert into public.books (title, xp_reward, time_reward) values ('Demo', 10, 5);
insert into public.app_config (key, value) values ('economy', '{"maintenance_mode": false}');
select pg_temp.expect('signed-in user reads books',
  pg_temp.try('authenticated', :A, 'select * from public.books'), 'ok:1');
select pg_temp.expect('anon cannot read books',
  pg_temp.try('anon', null, 'select * from public.books'), 'denied');
select pg_temp.expect('anon reads app config (before login)',
  pg_temp.try('anon', null, 'select * from public.app_config'), 'ok:1');
select pg_temp.expect('parent cannot add books',
  pg_temp.try('authenticated', :A, 'insert into public.books (title) values (''x'')'), 'denied');
select pg_temp.expect('parent cannot change config',
  pg_temp.try('authenticated', :A, 'update public.app_config set value = ''{}'''), 'ok:0');
select pg_temp.expect('admin can add books',
  pg_temp.try('authenticated', :AD, 'insert into public.books (title) values (''y'')'), 'ok:1');
select pg_temp.expect('admin can change config',
  pg_temp.try('authenticated', :AD, 'update public.app_config set value = ''{}'''), 'ok:1');
select pg_temp.expect('book xp reward capped at 500',
  pg_temp.try('authenticated', :AD, 'insert into public.books (title, xp_reward) values (''z'', 9999)'), 'denied');

-- Logs
select pg_temp.expect('user appends a log as self',
  pg_temp.try('authenticated', :A, 'insert into public.system_logs (message) values (''hi'')'), 'ok:1');
select pg_temp.expect('user cannot log as someone else',
  pg_temp.try('authenticated', :A, 'insert into public.system_logs (user_id, message) values (' || quote_literal(:B) || ', ''x'')'), 'denied');
select pg_temp.expect('user cannot read logs',
  pg_temp.try('authenticated', :A, 'select * from public.system_logs'), 'ok:0');
select pg_temp.expect('admin reads logs',
  pg_temp.try('authenticated', :AD, 'select * from public.system_logs'), 'ok:1');

-- Admin list
select pg_temp.expect('client cannot read admins',
  pg_temp.try('authenticated', :A, 'select * from public.admins'), 'denied');
select pg_temp.expect('client cannot make self admin',
  pg_temp.try('authenticated', :A, 'insert into public.admins values (' || quote_literal(:A) || ')'), 'denied');

-- Leaderboard
select pg_temp.expect('leaderboard shows first name only, best first',
  (select string_agg(name || ':' || xp, ',' order by xp desc)
   from (select * from public.leaderboard_top(2)) t), 'Ali:300,Sara:120');
select pg_temp.expect('anon cannot call leaderboard',
  pg_temp.try('anon', null, 'select * from public.leaderboard_top(10)'), 'denied');
select pg_temp.expect('signed-in user calls leaderboard',
  pg_temp.try('authenticated', :A, 'select * from public.leaderboard_top(10)'), 'ok:3');
update public.children set show_on_leaderboard = false where id = :CB;
select pg_temp.expect('hidden child left off leaderboard',
  pg_temp.try('authenticated', :A, 'select * from public.leaderboard_top(10)'), 'ok:2');
rollback;
\echo ALL SCHEMA TESTS PASSED

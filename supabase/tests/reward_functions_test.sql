-- Tests for the stage 2 server functions. Run with supabase/tests/run_local.sh.
\set ON_ERROR_STOP 1
\o /dev/null
\i tests/helpers.sql
begin;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test'),
  ('00000000-0000-0000-0000-0000000000ad', 'admin@test');
insert into public.admins values ('00000000-0000-0000-0000-0000000000ad');
insert into public.children (id, parent_id, name) values
  ('11111111-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'Sara'),
  ('11111111-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'Ali');
insert into public.books (id, title, pages, quiz, xp_reward, time_reward) values
  ('22222222-0000-0000-0000-000000000001', 'Demo',
   '["p1","p2","p3"]', '[{"q":1},{"q":2}]', 20, 10);

\set A '00000000-0000-0000-0000-00000000000a'
\set B '00000000-0000-0000-0000-00000000000b'
\set AD '00000000-0000-0000-0000-0000000000ad'
\set CA '11111111-0000-0000-0000-00000000000a'
\set BOOK '22222222-0000-0000-0000-000000000001'

create temp table t (k text primary key, v text);
grant all on t to authenticated;
create function pg_temp.child(p text) returns text language sql as $$
  select xp || '/' || time_balance from public.children
  where id = '11111111-0000-0000-0000-00000000000a' $$;

-- Reading -------------------------------------------------------------------
select pg_temp.expect('other parent cannot start reading for my child',
  left(pg_temp.val(:'B', $$select public.start_reading('$$ || :'CA' || $$', '$$ || :'BOOK' || $$')$$), 5), 'error');
insert into t select 's1', pg_temp.val(:'A', $$select public.start_reading('$$ || :'CA' || $$', '$$ || :'BOOK' || $$')$$);
select pg_temp.expect('finishing right away is too fast',
  pg_temp.val(:'A', $$select public.finish_reading('$$ || (select v from t where k = 's1') || $$', 2) ->> 'reason'$$), 'too_fast');
select pg_temp.expect('too fast pays nothing', pg_temp.child(''), '0/0');

insert into t select 's2', pg_temp.val(:'A', $$select public.start_reading('$$ || :'CA' || $$', '$$ || :'BOOK' || $$')$$);
update public.reading_sessions set started_at = now() - interval '60 seconds'
  where id = (select v::uuid from t where k = 's2');
select pg_temp.expect('first read pays XP + capped quiz bonus + minutes',
  pg_temp.val(:'A', $$select public.finish_reading('$$ || (select v from t where k = 's2') || $$', 99)::text$$),
  '{"xp": 24, "granted": true, "minutes": 10, "first_read": true}');
select pg_temp.expect('finishing the same session again pays nothing more',
  pg_temp.val(:'A', $$select public.finish_reading('$$ || (select v from t where k = 's2') || $$', 2) ->> 'xp'$$)
  || ' ' || pg_temp.child(''), '24 24/10');
select pg_temp.expect('other parent cannot finish my session',
  left(pg_temp.val(:'B', $$select public.finish_reading('$$ || (select v from t where k = 's2') || $$', 2)::text$$), 5), 'error');

insert into t select 's3', pg_temp.val(:'A', $$select public.start_reading('$$ || :'CA' || $$', '$$ || :'BOOK' || $$')$$);
update public.reading_sessions set started_at = now() - interval '60 seconds'
  where id = (select v::uuid from t where k = 's3');
select pg_temp.expect('re-reading gives 1 XP and no minutes',
  pg_temp.val(:'A', $$select public.finish_reading('$$ || (select v from t where k = 's3') || $$', 2)::text$$),
  '{"xp": 1, "granted": true, "minutes": 0, "first_read": false}');
select pg_temp.expect('reading counted as learning minutes',
  (select learning_minutes || ' ' || (breakdown ->> 'reading') from public.daily_activity where child_id = :'CA'), '2 2');

-- Games ---------------------------------------------------------------------
select pg_temp.expect('game XP is capped at 100',
  pg_temp.val(:'A', $$select public.log_activity('$$ || :'CA' || $$', 'math', 5000, 3, 'game-key-0001') ->> 'xp'$$), '100');
select pg_temp.expect('same game key pays once',
  pg_temp.val(:'A', $$select public.log_activity('$$ || :'CA' || $$', 'math', 50, 3, 'game-key-0001')::text$$),
  '{"xp": 0, "duplicate": true}');
select pg_temp.expect('games never give minutes', pg_temp.child(''), '125/10');
insert into public.app_config (key, value) values ('economy', '{"daily_activity_xp_cap": 150}');
select pg_temp.expect('daily game XP cap leaves only what is left',
  pg_temp.val(:'A', $$select public.log_activity('$$ || :'CA' || $$', 'memory', 100, 1, 'game-key-0002') ->> 'xp'$$), '50');
select pg_temp.expect('nothing once the daily cap is reached',
  pg_temp.val(:'A', $$select public.log_activity('$$ || :'CA' || $$', 'memory', 100, 1, 'game-key-0003') ->> 'xp'$$), '0');
select pg_temp.expect('bad activity name is refused',
  left(pg_temp.val(:'A', $$select public.log_activity('$$ || :'CA' || $$', 'X; drop', 1, 1, 'game-key-0004')::text$$), 5), 'error');
select pg_temp.expect('game minutes logged per activity, even past the XP cap',
  (select (breakdown ->> 'math') || ' ' || (breakdown ->> 'memory') from public.daily_activity where child_id = :'CA'), '3 2');

-- Records -------------------------------------------------------------------
select pg_temp.val(:'A', $$select public.save_record('$$ || :'CA' || $$', 'hunter', 'maxCombo', 7)::text$$);
select pg_temp.val(:'A', $$select public.save_record('$$ || :'CA' || $$', 'hunter', 'maxCombo', 3)::text$$);
select pg_temp.expect('personal best only goes up',
  (select records #>> '{hunter,maxCombo}' from public.children where id = :'CA'), '7');
select pg_temp.expect('records cannot be written directly any more',
  pg_temp.try('authenticated', :'A', $$update public.children set records = '{}' where id = '$$ || :'CA' || $$'$$), 'denied');

-- Letters -------------------------------------------------------------------
select pg_temp.expect('letter reward paid once',
  pg_temp.val(:'A', $$select public.complete_letter('$$ || :'CA' || $$', 'a') ->> 'xp'$$) || ' ' ||
  pg_temp.val(:'A', $$select public.complete_letter('$$ || :'CA' || $$', 'A') ->> 'xp'$$), '50 0');
select pg_temp.expect('letter unlocks its card and level 3',
  (select array_to_string(unlocked_cards, ',') from public.children where id = :'CA') || ' ' ||
  (select level from public.letters where child_id = :'CA' and letter = 'A'), 'A 3');
select pg_temp.expect('XP and minutes after letter', pg_temp.child(''), '225/20');

-- Shop ----------------------------------------------------------------------
select pg_temp.expect('buying 10 minutes costs 50 XP',
  pg_temp.val(:'A', $$select public.buy_minutes('$$ || :'CA' || $$', 10, 'buy-key-0001') ->> 'cost'$$)
  || ' ' || pg_temp.child(''), '50 175/30');
select pg_temp.expect('retrying the same purchase charges once',
  pg_temp.val(:'A', $$select public.buy_minutes('$$ || :'CA' || $$', 10, 'buy-key-0001') ->> 'duplicate'$$)
  || ' ' || pg_temp.child(''), 'true 175/30');
select pg_temp.expect('cannot buy more minutes than XP allows',
  pg_temp.val(:'A', $$select public.buy_minutes('$$ || :'CA' || $$', 120, 'buy-key-0002') ->> 'reason'$$), 'not_enough_xp');
select pg_temp.expect('minutes outside 5..120 refused',
  left(pg_temp.val(:'A', $$select public.buy_minutes('$$ || :'CA' || $$', 500, 'buy-key-0003')::text$$), 5), 'error');
select pg_temp.expect('avatar needs the level',
  pg_temp.val(:'A', $$select public.buy_avatar('$$ || :'CA' || $$', 'boy2') ->> 'reason'$$), 'level_too_low');
update public.children set level = 2 where id = :'CA';
select pg_temp.expect('avatar bought at the database price',
  pg_temp.val(:'A', $$select public.buy_avatar('$$ || :'CA' || $$', 'boy2') ->> 'cost'$$)
  || ' ' || pg_temp.child(''), '50 125/30');
select pg_temp.expect('buying an owned avatar charges nothing',
  pg_temp.val(:'A', $$select public.buy_avatar('$$ || :'CA' || $$', 'boy2') ->> 'already_owned'$$)
  || ' ' || pg_temp.child(''), 'true 125/30');
select pg_temp.expect('unknown avatar refused',
  left(pg_temp.val(:'A', $$select public.buy_avatar('$$ || :'CA' || $$', 'dragon')::text$$), 5), 'error');

-- Screen time ---------------------------------------------------------------
update public.children set daily_limit_minutes = 20 where id = :'CA';
insert into t select 'x1', pg_temp.val(:'A', $$select public.start_screen_session('$$ || :'CA' || $$', 20) ->> 'session_id'$$);
select pg_temp.expect('starting a session takes the minutes', pg_temp.child(''), '125/10');
select pg_temp.expect('only one session at a time',
  pg_temp.val(:'A', $$select public.start_screen_session('$$ || :'CA' || $$', 5) ->> 'reason'$$), 'session_running');
-- The whole test is one transaction, so now() doesn't move: pretend 30
-- seconds have passed.
update public.screen_sessions set started_at = started_at - interval '30 seconds',
  ends_at = ends_at - interval '30 seconds'
  where id = (select v::uuid from t where k = 'x1');
select pg_temp.expect('ending early refunds unused whole minutes',
  pg_temp.val(:'A', $$select public.end_screen_session('$$ || (select v from t where k = 'x1') || $$') ->> 'refunded'$$)
  || ' ' || pg_temp.child(''), '19 125/29');
select pg_temp.expect('ending twice refunds nothing',
  pg_temp.val(:'A', $$select public.end_screen_session('$$ || (select v from t where k = 'x1') || $$') ->> 'refunded'$$), '0');
select pg_temp.expect('only the used minute counts toward today',
  (select screen_minutes::text from public.daily_activity where child_id = :'CA'), '1');
select pg_temp.expect('daily limit blocks a session that would pass it',
  pg_temp.val(:'A', $$select public.start_screen_session('$$ || :'CA' || $$', 20) ->> 'left_today'$$), '19');
update public.children set daily_limit_minutes = 0 where id = :'CA';
select pg_temp.expect('not enough minutes',
  pg_temp.val(:'A', $$select public.start_screen_session('$$ || :'CA' || $$', 200) ->> 'reason'$$), 'not_enough_minutes');
insert into t select 'x2', pg_temp.val(:'A', $$select public.start_screen_session('$$ || :'CA' || $$', 5) ->> 'session_id'$$);
update public.screen_sessions set ends_at = now() - interval '1 minute'
  where id = (select v::uuid from t where k = 'x2');
select pg_temp.expect('a finished session does not block the next one',
  pg_temp.val(:'A', $$select public.start_screen_session('$$ || :'CA' || $$', 5) ->> 'ok'$$), 'true');
select pg_temp.expect('other parent cannot end my session',
  left(pg_temp.val(:'B', $$select public.end_screen_session('$$ || (select v from t where k = 'x2') || $$')::text$$), 5), 'error');

-- Parent and admin ----------------------------------------------------------
select pg_temp.expect('parent gift capped at +500 XP / +120 min',
  pg_temp.val(:'A', $$select public.parent_adjust('$$ || :'CA' || $$', 9999, 9999, 'gift-key-0001')::text$$),
  '{"xp": 500, "minutes": 120, "duplicate": false}');
select pg_temp.expect('parent can take back, never below zero',
  pg_temp.val(:'A', $$select public.parent_adjust('$$ || :'CA' || $$', -99999, 0, 'gift-key-0002') ->> 'xp'$$)
  || ' ' || pg_temp.child(''), '-625 0/139');
select pg_temp.expect('other parent cannot gift my child',
  left(pg_temp.val(:'B', $$select public.parent_adjust('$$ || :'CA' || $$', 10, 0, 'gift-key-0003')::text$$), 5), 'error');
select pg_temp.expect('parent cannot use the admin tool',
  left(pg_temp.val(:'A', $$select public.admin_set_child_rewards('$$ || :'CA' || $$', 9, 9, 'x')::text$$), 5), 'error');
select pg_temp.val(:'AD', $$select public.admin_set_child_rewards('$$ || :'CA' || $$', 7, 8, 'fix')::text$$);
select pg_temp.expect('admin sets exact values', pg_temp.child(''), '7/8');

-- Ledger and access ---------------------------------------------------------
select pg_temp.expect('ledger adds up to the balances',
  (select sum(xp_delta) || '/' || sum(minutes_delta) from public.reward_events where child_id = :'CA'),
  pg_temp.child(''));
select pg_temp.expect('app cannot call internal helpers',
  left(pg_temp.val(:'A', $$select public._apply_reward('$$ || :'CA' || $$', 'k', 's', 999, 999, true)::text$$), 5), 'error');
select pg_temp.expect('signed-out users cannot call reward functions',
  pg_temp.try('anon', null, $$select public.buy_minutes('$$ || :'CA' || $$', 10, 'buy-key-0009')$$), 'denied');
select pg_temp.expect('parent can set own timezone',
  pg_temp.try('authenticated', :'A', $$update public.parents set timezone = 'Asia/Tehran' where id = '$$ || :'A' || $$'$$), 'ok:1');
select pg_temp.expect('shop prices readable, not writable by parents',
  pg_temp.try('authenticated', :'A', $$select * from public.shop_items$$) || ' ' ||
  pg_temp.try('authenticated', :'A', $$update public.shop_items set cost_xp = 0$$), 'ok:7 ok:0');

rollback;
\echo ALL REWARD FUNCTION TESTS PASSED

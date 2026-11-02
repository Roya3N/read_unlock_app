-- Tests for 20261102030000_app_support.sql.
\set ON_ERROR_STOP 1
\o /dev/null
\i tests/helpers.sql
begin;
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test');
insert into public.children (id, parent_id, name) values
  ('11111111-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'Sara');
\set A '00000000-0000-0000-0000-00000000000a'
\set B '00000000-0000-0000-0000-00000000000b'
\set CA '11111111-0000-0000-0000-00000000000a'

select pg_temp.val(:'A', $$select public.add_learned_words('$$ || :'CA' || $$', '["cat","dog"]')::text$$);
select pg_temp.val(:'A', $$select public.add_learned_words('$$ || :'CA' || $$', '["dog","sun"]')::text$$);
select pg_temp.expect('learned words merged without duplicates, in order',
  (select learned_words::text from public.children where id = :'CA'), '["cat", "dog", "sun"]');
select pg_temp.expect('other parent cannot add words to my child',
  left(pg_temp.val(:'B', $$select public.add_learned_words('$$ || :'CA' || $$', '["x"]')::text$$), 5), 'error');
select pg_temp.expect('words must be a list',
  left(pg_temp.val(:'A', $$select public.add_learned_words('$$ || :'CA' || $$', '{"a":1}')::text$$), 5), 'error');
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000c', 'c@test', '{"name":"Mina","dob":"1990-04-05"}'),
  ('00000000-0000-0000-0000-00000000000d', 'd@test', '{"dob":"not a date"}');
select pg_temp.expect('sign-up saves name and date of birth',
  (select name || ' ' || dob from public.parents where email = 'c@test'), 'Mina 1990-04-05');
select pg_temp.expect('bad date of birth does not block sign-up',
  (select coalesce(dob::text, 'none') from public.parents where email = 'd@test'), 'none');
select pg_temp.expect('long age group label accepted',
  pg_temp.try('authenticated', :'A', $$update public.children set age_group = 'Pre-teens (10-12 years)' where id = '$$ || :'CA' || $$'$$), 'ok:1');
select pg_temp.expect('signed-out user cannot delete an account',
  pg_temp.try('anon', null, 'select public.delete_my_account()'), 'denied');
insert into public.reward_events (child_id, idempotency_key, source) values (:'CA', 'k-del', 'x');
select pg_temp.val(:'A', 'select public.delete_my_account()::text');
select pg_temp.expect('deleting my account removes me, my children and their data',
  (select count(*) from auth.users where id = :'A') || ' ' ||
  (select count(*) from public.parents where id = :'A') || ' ' ||
  (select count(*) from public.children where id = :'CA') || ' ' ||
  (select count(*) from public.reward_events where child_id = :'CA'), '0 0 0 0');
select pg_temp.expect('other accounts are untouched',
  (select count(*)::text from auth.users where id = :'B'), '1');
rollback;
\echo ALL APP SUPPORT TESTS PASSED

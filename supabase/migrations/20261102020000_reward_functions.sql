-- Stage 2 of the Firebase -> Supabase move: server functions for rewards,
-- purchases and screen time. These are the only way XP, time balance,
-- unlocks and daily usage change.
--
--  * Every change is written to reward_events with a unique key, so retrying
--    a call (bad network, double tap) never pays twice.
--  * The server clock decides how long a book was read and how long a
--    screen session ran. Client timestamps are never used.
--  * Prices come from the database (shop_items, app_config 'economy').
--  * XP and minutes stay separate. Time is only taken when a session is
--    started, and unused whole minutes are refunded when it ends.
--
-- Nothing in this file deletes or rewrites existing data.

-- ---------------------------------------------------------------------------
-- Supporting tables
-- ---------------------------------------------------------------------------
alter table public.parents
  add column if not exists timezone text not null default 'UTC';

create table if not exists public.shop_items (
  id text primary key,
  kind text not null check (kind in ('avatar')),
  cost_xp integer not null check (cost_xp >= 0),
  required_level integer not null default 1 check (required_level >= 1),
  active boolean not null default true
);
alter table public.shop_items enable row level security;

-- Prices as they are in lib/features/child/data/avatars.dart today.
insert into public.shop_items (id, kind, cost_xp, required_level) values
  ('boy1', 'avatar', 0, 1),
  ('girl1', 'avatar', 0, 1),
  ('boy2', 'avatar', 50, 2),
  ('girl2', 'avatar', 50, 2),
  ('man1', 'avatar', 100, 3),
  ('woman1', 'avatar', 100, 3),
  ('man2', 'avatar', 150, 4)
on conflict (id) do nothing;

create table if not exists public.reading_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  result jsonb
);
create index if not exists reading_sessions_child_idx
  on public.reading_sessions (child_id, started_at desc);
alter table public.reading_sessions enable row level security;

alter table public.screen_sessions
  add column if not exists day date;

revoke all on public.shop_items, public.reading_sessions from anon, authenticated;
grant select on public.shop_items, public.reading_sessions to authenticated;

drop policy if exists "shop_items: read" on public.shop_items;
create policy "shop_items: read" on public.shop_items
  for select to authenticated using (true);
drop policy if exists "shop_items: admin write" on public.shop_items;
create policy "shop_items: admin write" on public.shop_items
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
grant insert, update, delete on public.shop_items to authenticated;

drop policy if exists "reading_sessions: read own" on public.reading_sessions;
create policy "reading_sessions: read own" on public.reading_sessions
  for select to authenticated
  using ((select public.owns_child(child_id)));

-- ---------------------------------------------------------------------------
-- Internal helpers (not callable from the app)
-- ---------------------------------------------------------------------------
create or replace function public._economy_int(p_key text, p_default integer)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select case when jsonb_typeof(value -> p_key) = 'number'
                 then (value ->> p_key)::numeric::integer end
     from public.app_config where key = 'economy'),
    p_default);
$$;

-- Locks the child row and checks the caller is the child's parent.
create or replace function public._lock_own_child(p_child_id uuid)
returns public.children
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
begin
  select * into c from public.children
  where id = p_child_id
  for update;
  if not found or c.parent_id is distinct from (select auth.uid()) then
    raise exception 'child not found' using errcode = '42501';
  end if;
  return c;
end;
$$;

-- The family's local date, so the daily limit resets at their midnight.
create or replace function public._family_today(p_parent_id uuid)
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select (now() at time zone coalesce(
    (select p.timezone from public.parents p
     where p.id = p_parent_id
       and exists (select 1 from pg_catalog.pg_timezone_names t
                   where t.name = p.timezone)),
    'UTC'))::date;
$$;

-- Records one reward and applies it. Returns false (and changes nothing)
-- when this key was already used for this child.
create or replace function public._apply_reward(
  p_child_id uuid,
  p_key text,
  p_source text,
  p_xp integer,
  p_minutes integer,
  p_earned boolean,
  p_details jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.reward_events
    (child_id, idempotency_key, source, xp_delta, minutes_delta, details)
  values (p_child_id, p_key, p_source, p_xp, p_minutes, p_details)
  on conflict (child_id, idempotency_key) do nothing;
  if not found then
    return false;
  end if;

  update public.children c
  set xp = c.xp + p_xp,
      time_balance = c.time_balance + p_minutes,
      total_earned_time = c.total_earned_time
        + case when p_earned and p_minutes > 0 then p_minutes else 0 end,
      level = ((c.total_earned_time
        + case when p_earned and p_minutes > 0 then p_minutes else 0 end)
        / 50) + 1,
      updated_at = now()
  where c.id = p_child_id;
  return true;
end;
$$;

create or replace function public._add_daily(
  p_child_id uuid,
  p_day date,
  p_learning integer,
  p_screen integer,
  p_activity text
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.daily_activity as d
    (child_id, day, learning_minutes, screen_minutes, breakdown)
  values (
    p_child_id, p_day, greatest(p_learning, 0), greatest(p_screen, 0),
    case when p_activity is not null and p_learning > 0
         then jsonb_build_object(p_activity, p_learning)
         else '{}'::jsonb end)
  on conflict (child_id, day) do update
  set learning_minutes = greatest(d.learning_minutes + p_learning, 0),
      screen_minutes = greatest(d.screen_minutes + p_screen, 0),
      breakdown = case
        when p_activity is not null and p_learning > 0 then
          d.breakdown || jsonb_build_object(p_activity,
            coalesce((d.breakdown ->> p_activity)::integer, 0) + p_learning)
        else d.breakdown end,
      updated_at = now();
$$;

-- ---------------------------------------------------------------------------
-- Reading
-- ---------------------------------------------------------------------------
create or replace function public.start_reading(p_child_id uuid, p_book_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  perform public._lock_own_child(p_child_id);
  if not exists (select 1 from public.books where id = p_book_id) then
    raise exception 'book not found' using errcode = 'P0002';
  end if;
  insert into public.reading_sessions (child_id, book_id)
  values (p_child_id, p_book_id)
  returning id into v_id;
  return v_id;
end;
$$;

-- Same rules as lib/core/utils/book_reward.dart: at least 5 seconds per
-- page, full reward on the first read (+2 XP per correct quiz answer),
-- 1 XP and no minutes on a re-read. Calling it again for the same session
-- returns the first answer and pays nothing more.
create or replace function public.finish_reading(
  p_session_id uuid,
  p_correct_answers integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s public.reading_sessions;
  b public.books;
  v_pages integer;
  v_quiz integer;
  v_seconds integer;
  v_first boolean;
  v_xp integer;
  v_minutes integer;
  v_result jsonb;
begin
  select * into s from public.reading_sessions where id = p_session_id;
  if not found then
    raise exception 'session not found' using errcode = '42501';
  end if;
  perform public._lock_own_child(s.child_id);
  select * into s from public.reading_sessions
  where id = p_session_id for update;
  if s.finished_at is not null then
    return s.result;
  end if;

  select * into b from public.books where id = s.book_id;
  v_pages := greatest(coalesce(jsonb_array_length(b.pages), 0), 1);
  v_quiz := coalesce(jsonb_array_length(b.quiz), 0);
  v_seconds := floor(extract(epoch from now() - s.started_at))::integer;

  if v_seconds < v_pages * 5 then
    v_result := jsonb_build_object(
      'granted', false, 'first_read', false, 'xp', 0, 'minutes', 0,
      'reason', 'too_fast');
  else
    insert into public.read_books (child_id, book_id)
    values (s.child_id, b.id::text)
    on conflict do nothing;
    v_first := found;
    if v_first then
      v_xp := b.xp_reward
        + least(greatest(coalesce(p_correct_answers, 0), 0), v_quiz) * 2;
      v_minutes := b.time_reward;
    else
      v_xp := 1;
      v_minutes := 0;
    end if;
    perform public._apply_reward(
      s.child_id, 'reading:' || s.id, 'reading', v_xp, v_minutes, true,
      jsonb_build_object('book_id', b.id, 'seconds', v_seconds));
    update public.children
    set last_book_read_id = b.id::text, last_read_at = now()
    where id = s.child_id;
    perform public._add_daily(
      s.child_id, public._family_today((select auth.uid())),
      greatest(v_seconds / 60, 1), 0, 'reading');
    v_result := jsonb_build_object(
      'granted', true, 'first_read', v_first, 'xp', v_xp,
      'minutes', v_minutes);
  end if;

  update public.reading_sessions
  set finished_at = now(), result = v_result
  where id = s.id;
  return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- Games and activities
-- ---------------------------------------------------------------------------
-- Games run on the device, so their XP can't be proven. It is capped per
-- game (activity_xp_cap, default 100, the largest game reward today) and per
-- day (daily_activity_xp_cap, default 1000). Games never give minutes.
create or replace function public.log_activity(
  p_child_id uuid,
  p_activity text,
  p_xp integer,
  p_played_minutes integer,
  p_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
  v_day date;
  v_today_xp integer;
  v_xp integer;
  v_minutes integer;
  v_new boolean;
begin
  if p_activity is null or p_activity !~ '^[a-z_]{1,30}$' then
    raise exception 'bad activity name' using errcode = '22023';
  end if;
  if p_key is null or char_length(p_key) not between 8 and 100 then
    raise exception 'bad key' using errcode = '22023';
  end if;
  c := public._lock_own_child(p_child_id);
  v_day := public._family_today(c.parent_id);

  select coalesce(sum(e.xp_delta), 0) into v_today_xp
  from public.reward_events e
  where e.child_id = p_child_id
    and e.source = 'activity'
    and e.created_at >= now() - interval '24 hours';

  v_xp := least(greatest(coalesce(p_xp, 0), 0),
                public._economy_int('activity_xp_cap', 100));
  v_xp := greatest(least(v_xp,
                public._economy_int('daily_activity_xp_cap', 1000) - v_today_xp), 0);
  v_minutes := least(greatest(coalesce(p_played_minutes, 0), 0), 120);

  v_new := public._apply_reward(
    p_child_id, 'activity:' || p_key, 'activity', v_xp, 0, false,
    jsonb_build_object('activity', p_activity, 'asked_xp', p_xp));
  if v_new and v_minutes > 0 then
    perform public._add_daily(p_child_id, v_day, v_minutes, 0, p_activity);
  end if;
  return jsonb_build_object('xp', case when v_new then v_xp else 0 end,
                            'duplicate', not v_new);
end;
$$;

-- Personal best for a game, e.g. Letter Hunter's max combo. Only goes up.
create or replace function public.save_record(
  p_child_id uuid,
  p_game text,
  p_field text,
  p_value integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_game !~ '^[a-z_]{1,30}$' or p_field !~ '^[A-Za-z_]{1,30}$' then
    raise exception 'bad record name' using errcode = '22023';
  end if;
  perform public._lock_own_child(p_child_id);
  update public.children c
  set records = jsonb_set(
        c.records || jsonb_build_object(p_game,
          coalesce(c.records -> p_game, '{}'::jsonb)),
        array[p_game, p_field],
        to_jsonb(greatest(
          coalesce((c.records #>> array[p_game, p_field])::integer, 0),
          least(greatest(p_value, 0), 1000000)))),
      updated_at = now()
  where c.id = p_child_id;
end;
$$;

-- Letter journey: the big reward is paid once per letter.
create or replace function public.complete_letter(p_child_id uuid, p_letter text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_letter text := upper(btrim(p_letter));
  v_xp integer := public._economy_int('letter_reward_xp', 50);
  v_minutes integer := public._economy_int('letter_reward_minutes', 10);
  v_new boolean;
begin
  if v_letter !~ '^[A-Z]$' then
    raise exception 'bad letter' using errcode = '22023';
  end if;
  perform public._lock_own_child(p_child_id);
  v_new := public._apply_reward(
    p_child_id, 'letter:' || v_letter, 'letter', v_xp, v_minutes, true,
    jsonb_build_object('letter', v_letter));
  if v_new then
    update public.children c
    set unlocked_cards = array_append(c.unlocked_cards, v_letter)
    where c.id = p_child_id and not (v_letter = any (c.unlocked_cards));
  end if;
  insert into public.letters as l (child_id, letter, level)
  values (p_child_id, v_letter, 3)
  on conflict (child_id, letter) do update
  set level = greatest(l.level, 3), updated_at = now();
  return jsonb_build_object(
    'granted', v_new,
    'xp', case when v_new then v_xp else 0 end,
    'minutes', case when v_new then v_minutes else 0 end);
end;
$$;

-- ---------------------------------------------------------------------------
-- Shop
-- ---------------------------------------------------------------------------
create or replace function public.buy_minutes(
  p_child_id uuid,
  p_minutes integer,
  p_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
  v_cost integer;
  v_new boolean;
begin
  if p_minutes is null or p_minutes not between 5 and 120 then
    raise exception 'minutes must be 5 to 120' using errcode = '22023';
  end if;
  if p_key is null or char_length(p_key) not between 8 and 100 then
    raise exception 'bad key' using errcode = '22023';
  end if;
  c := public._lock_own_child(p_child_id);
  if exists (select 1 from public.reward_events
             where child_id = p_child_id
               and idempotency_key = 'buy_minutes:' || p_key) then
    return jsonb_build_object('ok', true, 'duplicate', true);
  end if;
  v_cost := p_minutes * greatest(public._economy_int('minute_cost_xp', 5), 1);
  if c.xp < v_cost then
    return jsonb_build_object('ok', false, 'reason', 'not_enough_xp',
                              'cost', v_cost);
  end if;
  v_new := public._apply_reward(
    p_child_id, 'buy_minutes:' || p_key, 'buy_minutes', -v_cost, p_minutes,
    false, '{}'::jsonb);
  return jsonb_build_object('ok', true, 'cost', v_cost, 'minutes', p_minutes);
end;
$$;

create or replace function public.buy_avatar(p_child_id uuid, p_avatar_id text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
  i public.shop_items;
begin
  c := public._lock_own_child(p_child_id);
  select * into i from public.shop_items
  where id = p_avatar_id and kind = 'avatar' and active;
  if not found then
    raise exception 'item not found' using errcode = 'P0002';
  end if;
  if p_avatar_id = any (c.unlocked_avatars) then
    return jsonb_build_object('ok', true, 'already_owned', true);
  end if;
  if c.level < i.required_level then
    return jsonb_build_object('ok', false, 'reason', 'level_too_low');
  end if;
  if c.xp < i.cost_xp then
    return jsonb_build_object('ok', false, 'reason', 'not_enough_xp');
  end if;
  perform public._apply_reward(
    p_child_id, 'avatar:' || i.id, 'buy_avatar', -i.cost_xp, 0, false,
    jsonb_build_object('item', i.id));
  update public.children c2
  set unlocked_avatars = array_append(c2.unlocked_avatars, i.id)
  where c2.id = p_child_id;
  return jsonb_build_object('ok', true, 'cost', i.cost_xp);
end;
$$;

-- ---------------------------------------------------------------------------
-- Screen time
-- ---------------------------------------------------------------------------
-- Takes the minutes up front, after checking the balance and the parent's
-- daily limit. Only one session runs at a time.
create or replace function public.start_screen_session(
  p_child_id uuid,
  p_minutes integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
  v_day date;
  v_used integer;
  v_id uuid;
  v_ends timestamptz;
begin
  if p_minutes is null or p_minutes not between 1 and 240 then
    raise exception 'minutes must be 1 to 240' using errcode = '22023';
  end if;
  c := public._lock_own_child(p_child_id);
  v_day := public._family_today(c.parent_id);

  -- Sessions whose time has run out are closed with no refund.
  update public.screen_sessions
  set ended_at = ends_at
  where child_id = p_child_id and ended_at is null and ends_at <= now();
  if exists (select 1 from public.screen_sessions
             where child_id = p_child_id and ended_at is null) then
    return jsonb_build_object('ok', false, 'reason', 'session_running');
  end if;

  if c.time_balance < p_minutes then
    return jsonb_build_object('ok', false, 'reason', 'not_enough_minutes');
  end if;
  if c.daily_limit_minutes > 0 then
    select coalesce(d.screen_minutes, 0) into v_used
    from public.daily_activity d
    where d.child_id = p_child_id and d.day = v_day;
    if coalesce(v_used, 0) + p_minutes > c.daily_limit_minutes then
      return jsonb_build_object(
        'ok', false, 'reason', 'daily_limit',
        'left_today', greatest(c.daily_limit_minutes - coalesce(v_used, 0), 0));
    end if;
  end if;

  v_id := gen_random_uuid();
  v_ends := now() + make_interval(mins => p_minutes);
  insert into public.screen_sessions (id, child_id, minutes_bought, ends_at, day)
  values (v_id, p_child_id, p_minutes, v_ends, v_day);
  perform public._apply_reward(
    p_child_id, 'screen:' || v_id, 'screen_session', 0, -p_minutes, false,
    '{}'::jsonb);
  perform public._add_daily(p_child_id, v_day, 0, p_minutes, null);
  return jsonb_build_object('ok', true, 'session_id', v_id, 'ends_at', v_ends);
end;
$$;

-- Ends a session early and gives back the whole minutes not used, by the
-- server clock. Calling it again does nothing.
create or replace function public.end_screen_session(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s public.screen_sessions;
  v_refund integer;
begin
  select * into s from public.screen_sessions where id = p_session_id;
  if not found then
    raise exception 'session not found' using errcode = '42501';
  end if;
  perform public._lock_own_child(s.child_id);
  select * into s from public.screen_sessions
  where id = p_session_id for update;
  if s.ended_at is not null then
    return jsonb_build_object('refunded', 0, 'already_ended', true);
  end if;

  v_refund := least(greatest(
    floor(extract(epoch from s.ends_at - now()) / 60)::integer, 0),
    s.minutes_bought);
  update public.screen_sessions
  set ended_at = least(now(), s.ends_at), minutes_refunded = v_refund
  where id = s.id;
  if v_refund > 0 then
    perform public._apply_reward(
      s.child_id, 'refund:' || s.id, 'screen_refund', 0, v_refund, false,
      '{}'::jsonb);
    perform public._add_daily(s.child_id, s.day, 0, -v_refund, null);
  end if;
  return jsonb_build_object('refunded', v_refund);
end;
$$;

-- ---------------------------------------------------------------------------
-- Parent and admin changes
-- ---------------------------------------------------------------------------
-- The parent's gift dialog: up to +500 XP and +120 minutes per gift, or
-- taking some back (never below zero). Not counted as earned time.
create or replace function public.parent_adjust(
  p_child_id uuid,
  p_xp integer,
  p_minutes integer,
  p_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
  v_xp integer;
  v_minutes integer;
  v_new boolean;
begin
  if p_key is null or char_length(p_key) not between 8 and 100 then
    raise exception 'bad key' using errcode = '22023';
  end if;
  c := public._lock_own_child(p_child_id);
  v_xp := greatest(least(coalesce(p_xp, 0), 500), -c.xp);
  v_minutes := greatest(least(coalesce(p_minutes, 0), 120), -c.time_balance);
  v_new := public._apply_reward(
    p_child_id, 'parent:' || p_key, 'parent_adjust', v_xp, v_minutes, false,
    '{}'::jsonb);
  return jsonb_build_object('xp', v_xp, 'minutes', v_minutes,
                            'duplicate', not v_new);
end;
$$;

-- Admin tool (admin_users_screen): set absolute values, logged as a delta.
create or replace function public.admin_set_child_rewards(
  p_child_id uuid,
  p_xp integer,
  p_time_balance integer,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.children;
begin
  if not public.is_admin() then
    raise exception 'admins only' using errcode = '42501';
  end if;
  if p_xp < 0 or p_time_balance < 0 then
    raise exception 'values must be zero or more' using errcode = '22023';
  end if;
  select * into c from public.children where id = p_child_id for update;
  if not found then
    raise exception 'child not found' using errcode = 'P0002';
  end if;
  perform public._apply_reward(
    p_child_id, 'admin:' || gen_random_uuid(), 'admin_set',
    p_xp - c.xp, p_time_balance - c.time_balance, false,
    jsonb_build_object('reason', left(coalesce(p_reason, ''), 200)));
end;
$$;

-- ---------------------------------------------------------------------------
-- Who may call what
-- ---------------------------------------------------------------------------
revoke all on function
  public._economy_int(text, integer),
  public._lock_own_child(uuid),
  public._family_today(uuid),
  public._apply_reward(uuid, text, text, integer, integer, boolean, jsonb),
  public._add_daily(uuid, date, integer, integer, text)
from public, anon, authenticated;

revoke all on function
  public.start_reading(uuid, uuid),
  public.finish_reading(uuid, integer),
  public.log_activity(uuid, text, integer, integer, text),
  public.save_record(uuid, text, text, integer),
  public.complete_letter(uuid, text),
  public.buy_minutes(uuid, integer, text),
  public.buy_avatar(uuid, text),
  public.start_screen_session(uuid, integer),
  public.end_screen_session(uuid),
  public.parent_adjust(uuid, integer, integer, text),
  public.admin_set_child_rewards(uuid, integer, integer, text)
from public, anon;

grant execute on function
  public.start_reading(uuid, uuid),
  public.finish_reading(uuid, integer),
  public.log_activity(uuid, text, integer, integer, text),
  public.save_record(uuid, text, text, integer),
  public.complete_letter(uuid, text),
  public.buy_minutes(uuid, integer, text),
  public.buy_avatar(uuid, text),
  public.start_screen_session(uuid, integer),
  public.end_screen_session(uuid),
  public.parent_adjust(uuid, integer, integer, text),
  public.admin_set_child_rewards(uuid, integer, integer, text)
to authenticated;

-- Parents may now set their timezone.
grant update (timezone) on public.parents to authenticated;
-- Records change only through save_record from now on.
revoke update (records) on public.children from authenticated;

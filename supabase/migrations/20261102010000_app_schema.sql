-- Stage 1 of the Firebase -> Supabase move (plan: supabase-migration.md).
-- App tables that replace Firestore, with row-level security.
--
-- Rules this schema enforces:
--  * A parent only sees and changes their own family (parent_id = auth.uid()).
--  * Clients can never write XP, time balance, unlocks, the reward ledger or
--    daily usage directly. Those change only through server functions
--    (stage 2), which validate and use an idempotency key so a reward can't
--    be claimed twice.
--  * XP and screen-time minutes are separate columns and separate ledger
--    fields. Nothing here subtracts time on its own.
--  * Admins are listed in public.admins (not hardcoded emails).
--
-- Nothing in this file deletes or rewrites existing data.

-- ---------------------------------------------------------------------------
-- Admins
-- ---------------------------------------------------------------------------
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;
-- No policies: only server functions (security definer) and the dashboard
-- read this table.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins a where a.user_id = (select auth.uid())
  );
$$;

-- ---------------------------------------------------------------------------
-- Parents (one row per signed-in account)
-- ---------------------------------------------------------------------------
create table if not exists public.parents (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '' check (char_length(name) <= 80),
  email text,
  dob date,
  pin_hash text check (pin_hash is null or char_length(pin_hash) <= 200),
  setup_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.parents enable row level security;

-- Create the parent row when an account is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.parents (id, email, name)
  values (
    new.id,
    new.email,
    left(coalesce(new.raw_user_meta_data ->> 'name', ''), 80)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Children
-- ---------------------------------------------------------------------------
create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.parents (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 40),
  age_group text check (age_group is null or char_length(age_group) <= 20),
  avatar text check (avatar is null or char_length(avatar) <= 300),
  -- Rewards: written only by server functions.
  xp integer not null default 0 check (xp >= 0),
  level integer not null default 1 check (level >= 1),
  time_balance integer not null default 0 check (time_balance >= 0),
  total_earned_time integer not null default 0 check (total_earned_time >= 0),
  unlocked_avatars text[] not null default '{}',
  unlocked_cards text[] not null default '{}',
  -- Parent setting: 0 means no daily limit.
  daily_limit_minutes integer not null default 0
    check (daily_limit_minutes between 0 and 1440),
  show_on_leaderboard boolean not null default true,
  -- Progress the client may save itself (no reward value).
  learned_words jsonb not null default '[]'::jsonb,
  records jsonb not null default '{}'::jsonb,
  last_book_read_id text,
  last_read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists children_parent_id_idx on public.children (parent_id);
create index if not exists children_leaderboard_idx
  on public.children (xp desc) where show_on_leaderboard;
alter table public.children enable row level security;

-- ---------------------------------------------------------------------------
-- Reward ledger: every XP or minute change, with a unique key per claim.
-- ---------------------------------------------------------------------------
create table if not exists public.reward_events (
  id bigint generated always as identity primary key,
  child_id uuid not null references public.children (id) on delete cascade,
  idempotency_key text not null check (char_length(idempotency_key) <= 200),
  source text not null check (char_length(source) <= 60),
  xp_delta integer not null default 0,
  minutes_delta integer not null default 0,
  details jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  unique (child_id, idempotency_key)
);
create index if not exists reward_events_child_created_idx
  on public.reward_events (child_id, created_at desc);
alter table public.reward_events enable row level security;

-- Books a child has been rewarded for (first read only).
create table if not exists public.read_books (
  child_id uuid not null references public.children (id) on delete cascade,
  book_id text not null,
  first_read_at timestamptz not null default now(),
  primary key (child_id, book_id)
);
alter table public.read_books enable row level security;

-- ---------------------------------------------------------------------------
-- Daily activity (learning minutes and screen minutes kept apart)
-- ---------------------------------------------------------------------------
create table if not exists public.daily_activity (
  child_id uuid not null references public.children (id) on delete cascade,
  day date not null,
  learning_minutes integer not null default 0 check (learning_minutes >= 0),
  screen_minutes integer not null default 0 check (screen_minutes >= 0),
  breakdown jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (child_id, day)
);
alter table public.daily_activity enable row level security;

-- Screen-time sessions, started and ended by server functions (stage 2).
create table if not exists public.screen_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  minutes_bought integer not null check (minutes_bought between 1 and 1440),
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  ended_at timestamptz,
  minutes_refunded integer not null default 0 check (minutes_refunded >= 0)
);
create index if not exists screen_sessions_child_idx
  on public.screen_sessions (child_id, started_at desc);
alter table public.screen_sessions enable row level security;

-- Letter journey progress (no reward value).
create table if not exists public.letters (
  child_id uuid not null references public.children (id) on delete cascade,
  letter text not null check (char_length(letter) between 1 and 4),
  level integer not null default 0 check (level between 0 and 20),
  updated_at timestamptz not null default now(),
  primary key (child_id, letter)
);
alter table public.letters enable row level security;

-- ---------------------------------------------------------------------------
-- Shared content and settings
-- ---------------------------------------------------------------------------
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text not null,
  category text,
  cover_url text,
  min_age integer,
  pages jsonb not null default '[]'::jsonb,
  quiz jsonb not null default '[]'::jsonb,
  vocabulary jsonb not null default '[]'::jsonb,
  xp_reward integer not null default 0 check (xp_reward between 0 and 500),
  time_reward integer not null default 0 check (time_reward between 0 and 120),
  extra jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.books enable row level security;

-- Firestore `config/*` documents (economy, global) and `game_settings/*`.
create table if not exists public.app_config (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.app_config enable row level security;

create table if not exists public.game_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.game_settings enable row level security;

create table if not exists public.system_logs (
  id bigint generated always as identity primary key,
  user_id uuid default auth.uid(),
  level text not null default 'info' check (char_length(level) <= 20),
  message text not null check (char_length(message) <= 2000),
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists system_logs_created_idx
  on public.system_logs (created_at desc);
alter table public.system_logs enable row level security;

-- ---------------------------------------------------------------------------
-- Table privileges. Supabase grants everything to anon/authenticated by
-- default, so start from nothing and grant only what the app needs.
-- ---------------------------------------------------------------------------
revoke all on
  public.admins, public.parents, public.children, public.reward_events,
  public.read_books, public.daily_activity, public.screen_sessions,
  public.letters, public.books, public.app_config, public.game_settings,
  public.system_logs
from anon, authenticated;

grant select, update (name, dob, pin_hash, setup_completed)
  on public.parents to authenticated;

grant select, delete on public.children to authenticated;
grant insert (parent_id, name, age_group, avatar)
  on public.children to authenticated;
grant update (name, age_group, avatar, daily_limit_minutes,
              show_on_leaderboard, learned_words, records)
  on public.children to authenticated;

grant select on public.reward_events, public.read_books,
  public.daily_activity, public.screen_sessions to authenticated;

grant select, insert (child_id, letter, level), update (level)
  on public.letters to authenticated;

grant select on public.books, public.game_settings to authenticated;
grant select on public.app_config to anon, authenticated;
grant insert, update, delete on public.books, public.app_config,
  public.game_settings to authenticated;  -- limited to admins by policy

grant insert (level, message, context) on public.system_logs to authenticated;
grant select, delete on public.system_logs to authenticated; -- admins only

-- ---------------------------------------------------------------------------
-- Policies
-- ---------------------------------------------------------------------------
-- Parents
drop policy if exists "parents: own row" on public.parents;
create policy "parents: own row" on public.parents
  for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "parents: update own row" on public.parents;
create policy "parents: update own row" on public.parents
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Children
drop policy if exists "children: read own" on public.children;
create policy "children: read own" on public.children
  for select to authenticated
  using (parent_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "children: add own" on public.children;
create policy "children: add own" on public.children
  for insert to authenticated
  with check (parent_id = (select auth.uid()));
drop policy if exists "children: edit own" on public.children;
create policy "children: edit own" on public.children
  for update to authenticated
  using (parent_id = (select auth.uid()))
  with check (parent_id = (select auth.uid()));
drop policy if exists "children: delete own" on public.children;
create policy "children: delete own" on public.children
  for delete to authenticated
  using (parent_id = (select auth.uid()));

-- Read-only child data (written by server functions)
create or replace function public.owns_child(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.children c
    where c.id = p_child_id and c.parent_id = (select auth.uid())
  );
$$;

drop policy if exists "reward_events: read own" on public.reward_events;
create policy "reward_events: read own" on public.reward_events
  for select to authenticated
  using ((select public.owns_child(child_id)) or (select public.is_admin()));

drop policy if exists "read_books: read own" on public.read_books;
create policy "read_books: read own" on public.read_books
  for select to authenticated
  using ((select public.owns_child(child_id)));

drop policy if exists "daily_activity: read own" on public.daily_activity;
create policy "daily_activity: read own" on public.daily_activity
  for select to authenticated
  using ((select public.owns_child(child_id)));

drop policy if exists "screen_sessions: read own" on public.screen_sessions;
create policy "screen_sessions: read own" on public.screen_sessions
  for select to authenticated
  using ((select public.owns_child(child_id)));

-- Letters
drop policy if exists "letters: read own" on public.letters;
create policy "letters: read own" on public.letters
  for select to authenticated
  using ((select public.owns_child(child_id)));
drop policy if exists "letters: add own" on public.letters;
create policy "letters: add own" on public.letters
  for insert to authenticated
  with check ((select public.owns_child(child_id)));
drop policy if exists "letters: edit own" on public.letters;
create policy "letters: edit own" on public.letters
  for update to authenticated
  using ((select public.owns_child(child_id)))
  with check ((select public.owns_child(child_id)));

-- Content: everyone signed in reads, admins write
drop policy if exists "books: read" on public.books;
create policy "books: read" on public.books
  for select to authenticated using (true);
drop policy if exists "books: admin write" on public.books;
create policy "books: admin write" on public.books
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop policy if exists "app_config: read" on public.app_config;
create policy "app_config: read" on public.app_config
  for select to anon, authenticated using (true);
drop policy if exists "app_config: admin write" on public.app_config;
create policy "app_config: admin write" on public.app_config
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop policy if exists "game_settings: read" on public.game_settings;
create policy "game_settings: read" on public.game_settings
  for select to authenticated using (true);
drop policy if exists "game_settings: admin write" on public.game_settings;
create policy "game_settings: admin write" on public.game_settings
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- Logs: anyone signed in appends as themselves; admins read and clear
drop policy if exists "system_logs: append own" on public.system_logs;
create policy "system_logs: append own" on public.system_logs
  for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists "system_logs: admin read" on public.system_logs;
create policy "system_logs: admin read" on public.system_logs
  for select to authenticated using ((select public.is_admin()));
drop policy if exists "system_logs: admin delete" on public.system_logs;
create policy "system_logs: admin delete" on public.system_logs
  for delete to authenticated using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- Leaderboard: first name, avatar and XP only, for signed-in users.
-- ---------------------------------------------------------------------------
create or replace function public.leaderboard_top(p_limit integer default 50)
returns table (child_id uuid, name text, avatar text, xp integer, is_mine boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id,
         left(split_part(btrim(c.name), ' ', 1), 20),
         c.avatar,
         c.xp,
         c.parent_id = (select auth.uid())
  from public.children c
  where c.show_on_leaderboard
  order by c.xp desc, c.created_at
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

revoke all on function public.leaderboard_top(integer) from public, anon;
grant execute on function public.leaderboard_top(integer) to authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
revoke all on function public.owns_child(uuid) from public, anon;
grant execute on function public.owns_child(uuid) to authenticated;

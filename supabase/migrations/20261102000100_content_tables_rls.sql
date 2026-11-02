-- Content tables are public game content: anyone may read, nobody may
-- write through the public (anon/authenticated) API keys.
-- Writes go through the Supabase dashboard / SQL editor (service role),
-- until admin writes are wired to Firebase Auth (third-party auth).

alter table public.words enable row level security;
alter table public.fact_vs_fake enable row level security;
alter table public.speed_reading enable row level security;

drop policy if exists "Public read" on public.words;
create policy "Public read" on public.words
  for select to anon, authenticated using (true);

drop policy if exists "Public read" on public.fact_vs_fake;
create policy "Public read" on public.fact_vs_fake
  for select to anon, authenticated using (true);

drop policy if exists "Public read" on public.speed_reading;
create policy "Public read" on public.speed_reading
  for select to anon, authenticated using (true);

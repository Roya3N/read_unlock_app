-- Stage 4 support for the app switch: live updates and learned words.
-- Nothing in this file deletes or rewrites existing data.

-- Live updates for the child's balance and the parent's dashboard.
-- Realtime still applies row-level security, so parents only receive their
-- own children.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public' and tablename = 'children')
  then
    alter publication supabase_realtime add table public.children;
  end if;
end $$;

-- Adds words to a child's vocabulary without duplicates, in one step.
create or replace function public.add_learned_words(
  p_child_id uuid,
  p_words jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if jsonb_typeof(p_words) <> 'array' or jsonb_array_length(p_words) > 200 then
    raise exception 'words must be a list of at most 200' using errcode = '22023';
  end if;
  perform public._lock_own_child(p_child_id);
  update public.children c
  set learned_words = (
        select coalesce(jsonb_agg(w order by first_seen), '[]'::jsonb)
        from (
          select w, min(ord) as first_seen
          from (
            select e.w, e.ord from jsonb_array_elements(c.learned_words)
              with ordinality as e(w, ord)
            union all
            select n.w, n.ord + 1000000 from jsonb_array_elements(p_words)
              with ordinality as n(w, ord)
          ) all_words
          group by w
        ) d
        limit 5000),
      updated_at = now()
  where c.id = p_child_id;
end;
$$;

revoke all on function public.add_learned_words(uuid, jsonb) from public, anon;
grant execute on function public.add_learned_words(uuid, jsonb) to authenticated;

-- Sign-up sends the parent's name and date of birth as metadata; the parent
-- row is created from it (the app may not have a session yet when email
-- confirmation is on). A bad date is ignored rather than blocking sign-up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_dob date;
begin
  begin
    v_dob := nullif(new.raw_user_meta_data ->> 'dob', '')::date;
  exception when others then
    v_dob := null;
  end;
  insert into public.parents (id, email, name, dob)
  values (
    new.id,
    new.email,
    left(coalesce(new.raw_user_meta_data ->> 'name', ''), 80),
    v_dob
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- Age group labels such as "Pre-teens (10-12 years)" are longer than 20.
alter table public.children drop constraint if exists children_age_group_check;
alter table public.children add constraint children_age_group_check
  check (age_group is null or char_length(age_group) <= 40);

-- Lets a parent delete their own account from the app (app stores require
-- this). Removing the sign-in account removes the parent row and, through
-- the cascades, their children and all of the children's data.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  delete from auth.users where id = v_uid;
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

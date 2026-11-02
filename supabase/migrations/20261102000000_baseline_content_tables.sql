-- Baseline: the content tables as they exist in the live project
-- (read from information_schema on 2026-11-02). They were created by hand
-- in the dashboard; this file records them so the schema lives in Git.
-- Safe to run on the live project: every statement is "if not exists".

create table if not exists public.words (
  id uuid primary key default gen_random_uuid(),
  word text not null unique,
  type text,
  phonetic text,
  definition text,
  example text,
  level text,
  category text,
  tags text[] default '{}'::text[],
  synonyms text[] default '{}'::text[],
  antonyms text[] default '{}'::text[],
  image_url text,
  audio_url text,
  created_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.fact_vs_fake (
  id uuid primary key default gen_random_uuid(),
  statement text not null,
  is_fact boolean not null,
  explanation text,
  category text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  difficulty text default 'easy'::text,
  xp integer default 10
);

create table if not exists public.speed_reading (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  question text not null,
  options jsonb not null,
  correct_index integer not null,
  xp integer default 50,
  difficulty text default 'medium'::text,
  created_at timestamptz not null default timezone('utc'::text, now())
);

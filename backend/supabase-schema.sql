-- Genesis - Character Gacha V16.0
-- Supabase Account & Cloud Save Foundation
-- Run this in the Supabase SQL Editor for your project.

begin;

create table if not exists public.genesis_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  player_id text generated always as (
    'GEN-' || upper(substr(replace(user_id::text, '-', ''), 1, 16))
  ) stored unique,
  display_name text not null default 'Summoner'
    check (char_length(display_name) between 1 and 28),
  achievement_points integer not null default 0 check (achievement_points >= 0),
  achievement_rank text not null default 'Initiate',
  summoner_level integer not null default 1 check (summoner_level between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.genesis_cloud_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  save_data jsonb not null,
  save_schema integer not null check (save_schema >= 1),
  app_version text not null,
  local_saved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.genesis_profiles enable row level security;
alter table public.genesis_cloud_saves enable row level security;

-- Least privilege: signed-out visitors receive no Data API privileges.
revoke all on table public.genesis_profiles from anon, authenticated;
revoke all on table public.genesis_cloud_saves from anon, authenticated;

grant select, insert, update, delete on table public.genesis_profiles to authenticated;
grant select, insert, update, delete on table public.genesis_cloud_saves to authenticated;

drop policy if exists "Genesis profiles select own" on public.genesis_profiles;
drop policy if exists "Genesis profiles insert own" on public.genesis_profiles;
drop policy if exists "Genesis profiles update own" on public.genesis_profiles;
drop policy if exists "Genesis profiles delete own" on public.genesis_profiles;

create policy "Genesis profiles select own"
on public.genesis_profiles for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "Genesis profiles insert own"
on public.genesis_profiles for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "Genesis profiles update own"
on public.genesis_profiles for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "Genesis profiles delete own"
on public.genesis_profiles for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "Genesis saves select own" on public.genesis_cloud_saves;
drop policy if exists "Genesis saves insert own" on public.genesis_cloud_saves;
drop policy if exists "Genesis saves update own" on public.genesis_cloud_saves;
drop policy if exists "Genesis saves delete own" on public.genesis_cloud_saves;

create policy "Genesis saves select own"
on public.genesis_cloud_saves for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "Genesis saves insert own"
on public.genesis_cloud_saves for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "Genesis saves update own"
on public.genesis_cloud_saves for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "Genesis saves delete own"
on public.genesis_cloud_saves for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

commit;

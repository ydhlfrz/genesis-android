-- Genesis - Character Gacha V16.3D
-- Full Online Cutover / Remove Browser-Authoritative Save Access
--
-- Prerequisites:
-- V16.1 -> V16.3A -> V16.3B -> V16.3C -> V16.3C.1 hotfix
--
-- This migration is intentionally NON-DESTRUCTIVE:
-- - genesis_cloud_saves is retained as an archival table
-- - no player rows are deleted
-- - browser access to legacy cloud-save JSON is revoked
-- - browser direct writes to genesis_profiles authoritative fields are revoked
-- - profile creation/display-name maintenance moves to a narrow RPC

begin;

-- ------------------------------------------------------------
-- Retire legacy JSON cloud save from browser use.
-- Keep existing rows only as archival data.
-- ------------------------------------------------------------
revoke all on table public.genesis_cloud_saves from anon, authenticated;

drop policy if exists "Genesis saves select own" on public.genesis_cloud_saves;
drop policy if exists "Genesis saves insert own" on public.genesis_cloud_saves;
drop policy if exists "Genesis saves update own" on public.genesis_cloud_saves;
drop policy if exists "Genesis saves delete own" on public.genesis_cloud_saves;

-- ------------------------------------------------------------
-- Harden profiles: browser reads its profile but cannot directly
-- overwrite AP / Rank / Summoner Level / Summoner XP.
-- ------------------------------------------------------------
revoke all on table public.genesis_profiles from anon, authenticated;
grant select on table public.genesis_profiles to authenticated;

drop policy if exists "Genesis profiles insert own" on public.genesis_profiles;
drop policy if exists "Genesis profiles update own" on public.genesis_profiles;
drop policy if exists "Genesis profiles delete own" on public.genesis_profiles;

drop policy if exists "Genesis profiles select own" on public.genesis_profiles;
create policy "Genesis profiles select own"
on public.genesis_profiles for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

-- ------------------------------------------------------------
-- Narrow profile bootstrap.
-- Only display_name can be browser-originated.
-- Authoritative progression/prestige columns stay server-controlled.
-- ------------------------------------------------------------
create or replace function public.genesis_profile_ensure(
  p_display_name text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  clean_name text;
  row_data public.genesis_profiles%rowtype;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  clean_name := nullif(btrim(coalesce(p_display_name,'')),'');
  if clean_name is not null then
    clean_name := left(clean_name,28);
  end if;

  insert into public.genesis_profiles(user_id,display_name)
  values(uid,coalesce(clean_name,'Summoner'))
  on conflict(user_id) do update
    set display_name=case
      when clean_name is not null then clean_name
      else public.genesis_profiles.display_name
    end,
    updated_at=now()
  returning * into row_data;

  return jsonb_build_object(
    'user_id',row_data.user_id,
    'player_id',row_data.player_id,
    'display_name',row_data.display_name,
    'achievement_points',row_data.achievement_points,
    'achievement_rank',row_data.achievement_rank,
    'summoner_level',row_data.summoner_level,
    'summoner_xp',row_data.summoner_xp,
    'created_at',row_data.created_at,
    'updated_at',row_data.updated_at
  );
end
$$;

revoke execute on function public.genesis_profile_ensure(text) from public, anon;
grant execute on function public.genesis_profile_ensure(text) to authenticated;

commit;

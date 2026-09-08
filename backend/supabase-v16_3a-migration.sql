-- Genesis - Character Gacha V16.3A
-- Server Character Registry & Online Collection
--
-- PREREQUISITES:
-- 1. V16.0 supabase-schema.sql
-- 2. V16.1 supabase-v16_1-migration.sql
--
-- V16.3A goals:
-- - Every server-authoritative summon creates immutable ownership rows.
-- - Browser clients receive seed/rarity/registry IDs but cannot directly INSERT characters.
-- - Active Collection is server-owned.
-- - Favorite/name/archive mutations use authenticated RPCs.
-- - Archived characters remain in summon history.
--
-- Character appearance/stats are deterministic client derivations of the server-owned
-- seed + rarity. Server character_id is independently derived from the seed using the
-- same FNV-1a/base36 algorithm used by the Genesis frontend.

begin;

do $$
begin
  if to_regclass('public.genesis_wallets') is null then
    raise exception 'V16.1 migration is required before V16.3A';
  end if;
end
$$;

-- ------------------------------------------------------------
-- Canonical online summon sessions
-- ------------------------------------------------------------

create table if not exists public.genesis_summon_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  request_key text not null check (char_length(request_key) between 8 and 160),
  summon_count integer not null check (summon_count in (1,10)),
  gp_cost integer not null default 0 check (gp_cost >= 0),
  gp_earned integer not null default 0 check (gp_earned >= 0),
  created_at timestamptz not null default now(),
  unique (user_id, request_key)
);

create index if not exists genesis_summon_sessions_user_created_idx
  on public.genesis_summon_sessions(user_id, created_at desc);

-- ------------------------------------------------------------
-- Canonical character ownership registry
-- ------------------------------------------------------------

create table if not exists public.genesis_characters (
  registry_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  summon_session_id uuid not null references public.genesis_summon_sessions(id) on delete restrict,
  character_id text not null check (character_id ~ '^MCG-[A-Z0-9]{4}-[A-Z0-9]{4}$'),
  seed text not null check (char_length(seed) between 8 and 64),
  rarity_name text not null,
  rarity_stars integer not null check (rarity_stars between 1 and 10),
  gp_reward integer not null default 0 check (gp_reward >= 0),
  summon_index integer not null default 1 check (summon_index between 1 and 10),
  favorite boolean not null default false,
  custom_name text check (custom_name is null or char_length(custom_name) <= 48),
  archived boolean not null default false,

  -- Reserved normalized progression columns.
  -- V16.3A leaves them at defaults; V16.3B will make these authoritative.
  character_level integer not null default 1 check (character_level between 1 and 100),
  character_xp integer not null default 0 check (character_xp >= 0),
  evolution_stage integer not null default 0 check (evolution_stage between 0 and 3),
  weapon_upgrade integer not null default 0 check (weapon_upgrade between 0 and 10),
  armor_upgrade integer not null default 0 check (armor_upgrade between 0 and 10),
  accessory_upgrade integer not null default 0 check (accessory_upgrade between 0 and 10),
  relic_upgrade integer not null default 0 check (relic_upgrade between 0 and 10),
  artifact_upgrade integer not null default 0 check (artifact_upgrade between 0 and 10),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (user_id, character_id),
  unique (summon_session_id, summon_index)
);

create index if not exists genesis_characters_user_active_created_idx
  on public.genesis_characters(user_id, archived, created_at desc);

create index if not exists genesis_characters_user_favorite_idx
  on public.genesis_characters(user_id, favorite)
  where archived = false;

-- ------------------------------------------------------------
-- RLS + least privilege
-- ------------------------------------------------------------

alter table public.genesis_summon_sessions enable row level security;
alter table public.genesis_characters enable row level security;

revoke all on public.genesis_summon_sessions from anon, authenticated;
revoke all on public.genesis_characters from anon, authenticated;

grant select on public.genesis_summon_sessions to authenticated;
grant select on public.genesis_characters to authenticated;

drop policy if exists "Genesis summon sessions select own" on public.genesis_summon_sessions;
create policy "Genesis summon sessions select own"
on public.genesis_summon_sessions for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "Genesis characters select own" on public.genesis_characters;
create policy "Genesis characters select own"
on public.genesis_characters for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

-- No browser INSERT / UPDATE / DELETE policies are created.
-- Ownership writes happen only inside explicitly granted RPCs.

-- ------------------------------------------------------------
-- Deterministic Character ID helpers
-- Mirrors:
-- hashSeed(): 32-bit FNV-1a
-- characterIdFromSeed(): base36 -> MCG-XXXX-XXXX
-- ------------------------------------------------------------

create or replace function private.genesis_fnv1a32(p_text text)
returns bigint
language plpgsql
immutable
strict
set search_path = ''
as $$
declare
  h bigint := 2166136261;
  bytes bytea := convert_to(p_text,'UTF8');
  i integer;
  len integer := length(bytes);
begin
  if len > 0 then
    for i in 0..len-1 loop
      h := h # get_byte(bytes,i);
      h := (h * 16777619) % 4294967296;
    end loop;
  end if;
  return h;
end;
$$;

create or replace function private.genesis_base36(p_num bigint)
returns text
language plpgsql
immutable
strict
set search_path = ''
as $$
declare
  chars text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  n bigint := p_num;
  out_text text := '';
  digit integer;
begin
  if n = 0 then return '0'; end if;
  while n > 0 loop
    digit := (n % 36)::integer;
    out_text := substr(chars,digit+1,1) || out_text;
    n := n / 36;
  end loop;
  return out_text;
end;
$$;

create or replace function private.genesis_character_id_from_seed(p_seed text)
returns text
language plpgsql
immutable
strict
set search_path = ''
as $$
declare
  a text;
  b text;
begin
  a := lpad(private.genesis_base36(private.genesis_fnv1a32(p_seed)),7,'0');
  b := lpad(private.genesis_base36(private.genesis_fnv1a32(p_seed || '|MCG')),7,'0');
  return 'MCG-' || right(a,4) || '-' || right(b,4);
end;
$$;

-- ------------------------------------------------------------
-- Read-only Collection snapshot.
-- SECURITY INVOKER is sufficient because SELECT grants + RLS apply.
-- ------------------------------------------------------------

create or replace function public.genesis_collection_snapshot(
  p_limit integer default 500,
  p_history_limit integer default 50
)
returns jsonb
language plpgsql
security invoker
stable
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  safe_limit integer := greatest(1,least(coalesce(p_limit,500),1000));
  safe_history integer := greatest(1,least(coalesce(p_history_limit,50),200));
  active_json jsonb;
  history_json jsonb;
  active_count bigint;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select count(*)
  into active_count
  from public.genesis_characters
  where user_id=uid and archived=false;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb)
  into active_json
  from (
    select registry_id,summon_session_id,character_id,seed,rarity_name,rarity_stars,
           gp_reward,summon_index,favorite,custom_name,
           character_level,character_xp,evolution_stage,
           weapon_upgrade,armor_upgrade,accessory_upgrade,relic_upgrade,artifact_upgrade,
           created_at,updated_at
    from public.genesis_characters
    where user_id=uid and archived=false
    order by favorite desc, created_at desc
    limit safe_limit
  ) x;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb)
  into history_json
  from (
    select registry_id,summon_session_id,character_id,seed,rarity_name,rarity_stars,
           gp_reward,summon_index,favorite,custom_name,archived,created_at
    from public.genesis_characters
    where user_id=uid
    order by created_at desc
    limit safe_history
  ) x;

  return jsonb_build_object(
    'total_active',active_count,
    'characters',active_json,
    'history',history_json
  );
end;
$$;

-- ------------------------------------------------------------
-- Server-owned metadata mutations
-- ------------------------------------------------------------

create or replace function public.genesis_character_set_favorite(
  p_registry_id uuid,
  p_favorite boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  row_data public.genesis_characters%rowtype;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  update public.genesis_characters
  set favorite=coalesce(p_favorite,false),updated_at=now()
  where registry_id=p_registry_id and user_id=uid and archived=false
  returning * into row_data;

  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  return jsonb_build_object(
    'registry_id',row_data.registry_id,
    'favorite',row_data.favorite,
    'updated_at',row_data.updated_at
  );
end;
$$;

create or replace function public.genesis_character_set_name(
  p_registry_id uuid,
  p_custom_name text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  clean_name text := nullif(btrim(coalesce(p_custom_name,'')),'');
  row_data public.genesis_characters%rowtype;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if clean_name is not null and char_length(clean_name) > 48 then
    raise exception 'NAME_TOO_LONG';
  end if;

  update public.genesis_characters
  set custom_name=clean_name,updated_at=now()
  where registry_id=p_registry_id and user_id=uid and archived=false
  returning * into row_data;

  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  return jsonb_build_object(
    'registry_id',row_data.registry_id,
    'custom_name',row_data.custom_name,
    'updated_at',row_data.updated_at
  );
end;
$$;

create or replace function public.genesis_character_archive(
  p_registry_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  row_data public.genesis_characters%rowtype;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  update public.genesis_characters
  set archived=true,archived_at=now(),favorite=false,updated_at=now()
  where registry_id=p_registry_id and user_id=uid and archived=false
  returning * into row_data;

  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  return jsonb_build_object(
    'registry_id',row_data.registry_id,
    'archived',true,
    'archived_at',row_data.archived_at
  );
end;
$$;

-- ------------------------------------------------------------
-- Replace V16.1 summon RPC.
-- Same external signature, now atomically creates:
-- wallet transaction + Daily progress + summon session + character ownership rows.
-- ------------------------------------------------------------

create or replace function public.genesis_online_summon(
  p_count integer,
  p_pity_enabled boolean,
  p_request_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  existing jsonb;
  w public.genesis_wallets%rowtype;
  d public.genesis_daily_server%rowtype;
  today date := (now() at time zone 'UTC')::date;
  reset_at timestamptz := ((today + 1)::timestamp at time zone 'UTC');
  cost integer := case when p_count=10 then 120 else 0 end;
  i integer;
  stars integer;
  rarity text;
  reward integer;
  earned integer := 0;
  results jsonb := '[]'::jsonb;
  seed text;
  cid text;
  response jsonb;
  session_id uuid := gen_random_uuid();
  new_registry_id uuid;
  new_character_created_at timestamptz;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_count not in (1,10) then raise exception 'INVALID_SUMMON_COUNT'; end if;
  if p_request_key is null or char_length(p_request_key) < 8 or char_length(p_request_key) > 160 then
    raise exception 'INVALID_REQUEST_KEY';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|genesis_online_summon|' || p_request_key,0));

  select r.response into existing
  from public.genesis_rpc_receipts r
  where r.user_id=uid
    and r.rpc_name='genesis_online_summon'
    and r.request_key=p_request_key;

  if found then return existing; end if;

  select * into w
  from public.genesis_wallets
  where user_id=uid
  for update;

  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  if w.gp < cost then raise exception 'INSUFFICIENT_GP'; end if;

  insert into public.genesis_summon_sessions(
    id,user_id,request_key,summon_count,gp_cost,gp_earned
  )
  values(session_id,uid,p_request_key,p_count,cost,0);

  if cost > 0 then
    w.gp := w.gp - cost;
    insert into public.genesis_economy_ledger(
      user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
    )
    values(
      uid,p_request_key,'TEN_PULL_COST',-cost,0,w.gp,w.essence,
      jsonb_build_object('count',p_count,'summon_session_id',session_id)
    );
  end if;

  insert into public.genesis_daily_server(user_id,date_key)
  values(uid,today)
  on conflict(user_id,date_key) do nothing;

  select * into d
  from public.genesis_daily_server
  where user_id=uid and date_key=today
  for update;

  for i in 1..p_count loop
    stars := private.genesis_roll_selected_stars(w.pity_count,p_pity_enabled);
    rarity := private.genesis_rarity_name(stars);
    reward := private.genesis_gp_reward(stars);
    earned := earned + reward;

    if stars >= 8 then w.pity_count := 0;
    else w.pity_count := least(60,w.pity_count + 1);
    end if;

    w.gp := w.gp + reward;

    seed := 'G161-' ||
      upper(substr(replace(gen_random_uuid()::text,'-',''),1,12)) ||
      '-' || lpad(i::text,2,'0');

    cid := private.genesis_character_id_from_seed(seed);

    insert into public.genesis_characters(
      user_id,summon_session_id,character_id,seed,rarity_name,rarity_stars,
      gp_reward,summon_index
    )
    values(
      uid,session_id,cid,seed,rarity,stars,reward,i
    )
    returning registry_id,created_at into new_registry_id,new_character_created_at;

    results := results || jsonb_build_array(jsonb_build_object(
      'registry_id',new_registry_id,
      'session_id',session_id,
      'character_id',cid,
      'seed',seed,
      'rarity',rarity,
      'stars',stars,
      'gp_reward',reward,
      'summon_index',i,
      'created_at',new_character_created_at
    ));

    d.progress := private.genesis_progress_inc(d.progress,'summons',1);
    d.progress := private.genesis_progress_inc(d.progress,'gpEarned',reward);
    if stars >= 3 then d.progress := private.genesis_progress_inc(d.progress,'rarePlus',1); end if;
    if stars >= 5 then d.progress := private.genesis_progress_inc(d.progress,'superRarePlus',1); end if;
    if stars >= 8 then d.progress := private.genesis_progress_inc(d.progress,'legendaryPlus',1); end if;

    insert into public.genesis_economy_ledger(
      user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
    )
    values(
      uid,p_request_key,'SUMMON_REWARD_'||lpad(i::text,2,'0'),
      reward,0,w.gp,w.essence,
      jsonb_build_object(
        'rarity',rarity,
        'stars',stars,
        'seed',seed,
        'character_id',cid,
        'registry_id',new_registry_id,
        'summon_session_id',session_id
      )
    );
  end loop;

  if p_count=10 then
    d.progress := private.genesis_progress_inc(d.progress,'tenPulls',1);
  end if;

  update public.genesis_wallets
  set gp=w.gp,essence=w.essence,pity_count=w.pity_count,updated_at=now()
  where user_id=uid;

  update public.genesis_daily_server
  set progress=d.progress,updated_at=now()
  where user_id=uid and date_key=today;

  update public.genesis_summon_sessions
  set gp_earned=earned
  where id=session_id and user_id=uid;

  response := jsonb_build_object(
    'session_id',session_id,
    'results',results,
    'cost',cost,
    'earned_gp',earned,
    'server_date',today,
    'reset_at',reset_at,
    'wallet',jsonb_build_object(
      'gp',w.gp,'essence',w.essence,'pity_count',w.pity_count
    ),
    'daily',jsonb_build_object(
      'mission_ids',to_jsonb(private.genesis_daily_ids(today)),
      'progress',d.progress,
      'claimed',d.claimed,
      'completion_three',d.completion_three,
      'completion_all',d.completion_all
    )
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_online_summon',p_request_key,response);

  return response;
end;
$$;

-- ------------------------------------------------------------
-- Function privileges
-- ------------------------------------------------------------

revoke execute on function public.genesis_collection_snapshot(integer,integer) from public, anon;
revoke execute on function public.genesis_character_set_favorite(uuid,boolean) from public, anon;
revoke execute on function public.genesis_character_set_name(uuid,text) from public, anon;
revoke execute on function public.genesis_character_archive(uuid) from public, anon;
revoke execute on function public.genesis_online_summon(integer,boolean,text) from public, anon;

grant execute on function public.genesis_collection_snapshot(integer,integer) to authenticated;
grant execute on function public.genesis_character_set_favorite(uuid,boolean) to authenticated;
grant execute on function public.genesis_character_set_name(uuid,text) to authenticated;
grant execute on function public.genesis_character_archive(uuid) to authenticated;
grant execute on function public.genesis_online_summon(integer,boolean,text) to authenticated;

commit;

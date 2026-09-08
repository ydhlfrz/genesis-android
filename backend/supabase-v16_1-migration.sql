-- Genesis - Character Gacha V16.1
-- Secure Economy & Server-Authoritative Daily migration.
-- Run AFTER the V16.0 supabase-schema.sql has already been applied.
--
-- Security model:
-- - Authenticated users may SELECT their own secure state / ledger rows.
-- - Browser roles do NOT receive direct INSERT/UPDATE/DELETE on secure economy tables.
-- - Mutations happen through explicitly granted RPC functions.
-- - SECURITY DEFINER functions pin search_path = '' and schema-qualify objects.

begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.genesis_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  gp bigint not null default 0 check (gp >= 0),
  essence bigint not null default 0 check (essence >= 0),
  pity_count integer not null default 0 check (pity_count between 0 and 60),
  initialized_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.genesis_economy_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  request_key text not null check (char_length(request_key) between 8 and 160),
  event_type text not null,
  gp_delta bigint not null default 0,
  essence_delta bigint not null default 0,
  gp_balance bigint not null,
  essence_balance bigint not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, request_key, event_type)
);

create index if not exists genesis_economy_ledger_user_created_idx
  on public.genesis_economy_ledger (user_id, created_at desc);

create table if not exists public.genesis_rpc_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  rpc_name text not null,
  request_key text not null check (char_length(request_key) between 8 and 160),
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, rpc_name, request_key)
);

create table if not exists public.genesis_daily_server (
  user_id uuid not null references auth.users(id) on delete cascade,
  date_key date not null,
  progress jsonb not null default '{}'::jsonb,
  claimed jsonb not null default '{}'::jsonb,
  completion_three boolean not null default false,
  completion_all boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, date_key)
);

create table if not exists public.genesis_login_server (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_claim_date date,
  cycle_day integer not null default 0 check (cycle_day between 0 and 7),
  total_claims integer not null default 0 check (total_claims >= 0),
  full_cycles integer not null default 0 check (full_cycles >= 0),
  updated_at timestamptz not null default now()
);

alter table public.genesis_wallets enable row level security;
alter table public.genesis_economy_ledger enable row level security;
alter table public.genesis_rpc_receipts enable row level security;
alter table public.genesis_daily_server enable row level security;
alter table public.genesis_login_server enable row level security;

revoke all on public.genesis_wallets from anon, authenticated;
revoke all on public.genesis_economy_ledger from anon, authenticated;
revoke all on public.genesis_rpc_receipts from anon, authenticated;
revoke all on public.genesis_daily_server from anon, authenticated;
revoke all on public.genesis_login_server from anon, authenticated;

grant select on public.genesis_wallets to authenticated;
grant select on public.genesis_economy_ledger to authenticated;
grant select on public.genesis_daily_server to authenticated;
grant select on public.genesis_login_server to authenticated;

drop policy if exists "Genesis wallet select own" on public.genesis_wallets;
create policy "Genesis wallet select own"
on public.genesis_wallets for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "Genesis ledger select own" on public.genesis_economy_ledger;
create policy "Genesis ledger select own"
on public.genesis_economy_ledger for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "Genesis daily select own" on public.genesis_daily_server;
create policy "Genesis daily select own"
on public.genesis_daily_server for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "Genesis login select own" on public.genesis_login_server;
create policy "Genesis login select own"
on public.genesis_login_server for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

-- No client SELECT policy is created for RPC receipts.

-- ----------------------------------------------------------------
-- Private helpers
-- ----------------------------------------------------------------

create or replace function private.genesis_roll_base_stars()
returns integer
language plpgsql
volatile
set search_path = ''
as $$
declare
  r double precision := random() * 100.0;
begin
  if r < 30.0 then return 1;
  elsif r < 52.0 then return 2;
  elsif r < 70.0 then return 3;
  elsif r < 82.0 then return 4;
  elsif r < 90.0 then return 5;
  elsif r < 95.0 then return 6;
  elsif r < 98.0 then return 7;
  elsif r < 99.5 then return 8;
  elsif r < 99.9 then return 9;
  else return 10;
  end if;
end;
$$;

create or replace function private.genesis_rarity_name(p_stars integer)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_stars
    when 1 then 'Common'
    when 2 then 'Uncommon'
    when 3 then 'Rare'
    when 4 then 'Special Rare'
    when 5 then 'Super Rare'
    when 6 then 'Super Special Rare'
    when 7 then 'Epic'
    when 8 then 'Legendary'
    when 9 then 'Mythical'
    when 10 then 'Primordial'
    else 'Common'
  end
$$;

create or replace function private.genesis_gp_reward(p_stars integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_stars
    when 1 then 1
    when 2 then 2
    when 3 then 5
    when 4 then 10
    when 5 then 10
    when 6 then 20
    when 7 then 25
    when 8 then 50
    when 9 then 100
    when 10 then 200
    else 0
  end
$$;

create or replace function private.genesis_roll_selected_stars(
  p_pity_count integer,
  p_pity_enabled boolean
)
returns integer
language plpgsql
volatile
set search_path = ''
as $$
declare
  attempts integer := 1;
  i integer;
  candidate integer;
  best integer := 1;
  r double precision;
begin
  if p_pity_enabled and p_pity_count >= 60 then
    -- Existing client behavior effectively rolls from Legendary+ until successful.
    -- Conditional weights: Legendary 75%, Mythical 20%, Primordial 5%.
    r := random() * 100.0;
    if r < 75.0 then return 8;
    elsif r < 95.0 then return 9;
    else return 10;
    end if;
  end if;

  if p_pity_enabled then
    if p_pity_count >= 50 then attempts := 5;
    elsif p_pity_count >= 40 then attempts := 3;
    elsif p_pity_count >= 30 then attempts := 2;
    end if;
  end if;

  for i in 1..attempts loop
    candidate := private.genesis_roll_base_stars();
    if candidate > best then best := candidate; end if;
  end loop;
  return best;
end;
$$;

create or replace function private.genesis_daily_ids(p_date date)
returns text[]
language sql
stable
set search_path = ''
as $$
  select array_agg(x.id order by x.sort_key)
  from (
    select v.id, md5(p_date::text || '|' || v.id) as sort_key
    from (values
      ('summon5'),
      ('summon10'),
      ('gp50'),
      ('rare3'),
      ('super1'),
      ('tenpull1'),
      ('legendary1'),
      ('gp100')
    ) as v(id)
    order by md5(p_date::text || '|' || v.id)
    limit 6
  ) as x
$$;

create or replace function private.genesis_daily_metric(p_id text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_id
    when 'summon5' then 'summons'
    when 'summon10' then 'summons'
    when 'gp50' then 'gpEarned'
    when 'rare3' then 'rarePlus'
    when 'super1' then 'superRarePlus'
    when 'tenpull1' then 'tenPulls'
    when 'legendary1' then 'legendaryPlus'
    when 'gp100' then 'gpEarned'
    else null
  end
$$;

create or replace function private.genesis_daily_target(p_id text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_id
    when 'summon5' then 5
    when 'summon10' then 10
    when 'gp50' then 50
    when 'rare3' then 3
    when 'super1' then 1
    when 'tenpull1' then 1
    when 'legendary1' then 1
    when 'gp100' then 100
    else 2147483647
  end
$$;

create or replace function private.genesis_daily_reward(p_id text)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select case p_id
    when 'summon5' then jsonb_build_object('gp',10,'essence',0,'xp',15,'label','10 GP + 15 Summoner EXP')
    when 'summon10' then jsonb_build_object('gp',15,'essence',20,'xp',20,'label','15 GP + 20 Essence + 20 Summoner EXP')
    when 'gp50' then jsonb_build_object('gp',0,'essence',35,'xp',15,'label','35 Essence + 15 Summoner EXP')
    when 'rare3' then jsonb_build_object('gp',0,'essence',30,'xp',15,'label','30 Essence + 15 Summoner EXP')
    when 'super1' then jsonb_build_object('gp',0,'essence',40,'xp',20,'label','40 Essence + 20 Summoner EXP')
    when 'tenpull1' then jsonb_build_object('gp',10,'essence',20,'xp',20,'label','10 GP + 20 Essence + 20 Summoner EXP')
    when 'legendary1' then jsonb_build_object('gp',15,'essence',30,'xp',25,'label','15 GP + 30 Essence + 25 Summoner EXP')
    when 'gp100' then jsonb_build_object('gp',10,'essence',25,'xp',20,'label','10 GP + 25 Essence + 20 Summoner EXP')
    else jsonb_build_object('gp',0,'essence',0,'xp',0,'label','No reward')
  end
$$;

create or replace function private.genesis_progress_inc(
  p_progress jsonb,
  p_metric text,
  p_amount integer
)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  old_value integer := coalesce((p_progress ->> p_metric)::integer, 0);
begin
  return jsonb_set(coalesce(p_progress,'{}'::jsonb), array[p_metric], to_jsonb(old_value + greatest(p_amount,0)), true);
end;
$$;

create or replace function private.genesis_completed_daily_count(
  p_date date,
  p_progress jsonb
)
returns integer
language plpgsql
stable
set search_path = ''
as $$
declare
  ids text[] := private.genesis_daily_ids(p_date);
  id text;
  metric text;
  target integer;
  value integer;
  total integer := 0;
begin
  foreach id in array ids loop
    metric := private.genesis_daily_metric(id);
    target := private.genesis_daily_target(id);
    value := coalesce((p_progress ->> metric)::integer,0);
    if value >= target then total := total + 1; end if;
  end loop;
  return total;
end;
$$;

-- ----------------------------------------------------------------
-- Public RPC: initialize secure wallet ONCE.
-- The migration accepts legacy local balances exactly once, with generous caps.
-- This is a transition trust boundary from V16.0; after initialization the browser
-- cannot directly UPDATE wallet rows.
-- ----------------------------------------------------------------

create or replace function public.genesis_wallet_initialize(
  p_initial_gp bigint,
  p_initial_essence bigint
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  inserted_count integer := 0;
  w public.genesis_wallets%rowtype;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_initial_gp < 0 or p_initial_gp > 5000000 then raise exception 'INITIAL_GP_OUT_OF_RANGE'; end if;
  if p_initial_essence < 0 or p_initial_essence > 50000000 then raise exception 'INITIAL_ESSENCE_OUT_OF_RANGE'; end if;

  insert into public.genesis_wallets(user_id,gp,essence,pity_count)
  values(uid,p_initial_gp,p_initial_essence,0)
  on conflict(user_id) do nothing;
  get diagnostics inserted_count = row_count;

  select * into w from public.genesis_wallets where user_id=uid;

  if inserted_count = 1 then
    insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
    values(uid,'MIGRATION-'||uid::text,'V161_LEGACY_MIGRATION',p_initial_gp,p_initial_essence,w.gp,w.essence,
      jsonb_build_object('source','V16.0 local/cloud save','one_time',true));
  end if;

  return jsonb_build_object(
    'initialized',true,
    'initialized_now',(inserted_count=1),
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count,'updated_at',w.updated_at)
  );
end;
$$;

-- ----------------------------------------------------------------
-- Public RPC: secure state snapshot
-- ----------------------------------------------------------------

create or replace function public.genesis_secure_snapshot()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  w public.genesis_wallets%rowtype;
  d public.genesis_daily_server%rowtype;
  l public.genesis_login_server%rowtype;
  today date := (now() at time zone 'UTC')::date;
  reset_at timestamptz := ((today + 1)::timestamp at time zone 'UTC');
  ids text[] := private.genesis_daily_ids(today);
  ledger_json jsonb := '[]'::jsonb;
  daily_claim_count bigint := 0;
  perfect_daily_count bigint := 0;
  next_day integer := 1;
  claimed_today boolean := false;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into w from public.genesis_wallets where user_id=uid;
  if not found then
    return jsonb_build_object(
      'initialized',false,
      'server_date',today,
      'reset_at',reset_at,
      'wallet',null,
      'daily',null,
      'login',jsonb_build_object('cycle_day',0,'total_claims',0,'full_cycles',0,'claimed_today',false,'next_day',1),
      'ledger','[]'::jsonb
    );
  end if;

  insert into public.genesis_daily_server(user_id,date_key)
  values(uid,today)
  on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today;

  select * into l from public.genesis_login_server where user_id=uid;
  if found then
    claimed_today := l.last_claim_date = today;
    if claimed_today then next_day := l.cycle_day;
    elsif l.last_claim_date = today - 1 then next_day := (l.cycle_day % 7) + 1;
    else next_day := 1;
    end if;
  end if;

  select count(*) into daily_claim_count
  from public.genesis_economy_ledger
  where user_id=uid and event_type like 'DAILY_MISSION_%';

  select count(*) into perfect_daily_count
  from public.genesis_economy_ledger
  where user_id=uid and event_type='DAILY_COMPLETION_ALL';

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb)
  into ledger_json
  from (
    select event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata,created_at
    from public.genesis_economy_ledger
    where user_id=uid
    order by created_at desc
    limit 10
  ) x;

  return jsonb_build_object(
    'initialized',true,
    'server_date',today,
    'reset_at',reset_at,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count,'updated_at',w.updated_at),
    'daily',jsonb_build_object(
      'mission_ids',to_jsonb(ids),
      'progress',d.progress,
      'claimed',d.claimed,
      'completion_three',d.completion_three,
      'completion_all',d.completion_all
    ),
    'login',jsonb_build_object(
      'cycle_day',coalesce(l.cycle_day,0),
      'total_claims',coalesce(l.total_claims,0),
      'full_cycles',coalesce(l.full_cycles,0),
      'last_claim_date',l.last_claim_date,
      'claimed_today',claimed_today,
      'next_day',next_day
    ),
    'career',jsonb_build_object(
      'daily_mission_claims',daily_claim_count,
      'perfect_daily_days',perfect_daily_count,
      'full_login_cycles',coalesce(l.full_cycles,0)
    ),
    'ledger',ledger_json
  );
end;
$$;

-- ----------------------------------------------------------------
-- Public RPC: server-authoritative summon rarity + wallet
-- ----------------------------------------------------------------

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
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_count not in (1,10) then raise exception 'INVALID_SUMMON_COUNT'; end if;
  if p_request_key is null or char_length(p_request_key) < 8 or char_length(p_request_key) > 160 then raise exception 'INVALID_REQUEST_KEY'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|genesis_online_summon|' || p_request_key,0));

  select r.response into existing
  from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_online_summon' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  if w.gp < cost then raise exception 'INSUFFICIENT_GP'; end if;

  if cost > 0 then
    w.gp := w.gp - cost;
    insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
    values(uid,p_request_key,'TEN_PULL_COST',-cost,0,w.gp,w.essence,jsonb_build_object('count',p_count));
  end if;

  insert into public.genesis_daily_server(user_id,date_key)
  values(uid,today)
  on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;

  for i in 1..p_count loop
    stars := private.genesis_roll_selected_stars(w.pity_count,p_pity_enabled);
    rarity := private.genesis_rarity_name(stars);
    reward := private.genesis_gp_reward(stars);
    earned := earned + reward;

    if stars >= 8 then w.pity_count := 0;
    else w.pity_count := least(60,w.pity_count + 1);
    end if;

    w.gp := w.gp + reward;
    seed := 'G161-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,12)) || '-' || lpad(i::text,2,'0');

    results := results || jsonb_build_array(jsonb_build_object(
      'seed',seed,
      'rarity',rarity,
      'stars',stars,
      'gp_reward',reward
    ));

    d.progress := private.genesis_progress_inc(d.progress,'summons',1);
    d.progress := private.genesis_progress_inc(d.progress,'gpEarned',reward);
    if stars >= 3 then d.progress := private.genesis_progress_inc(d.progress,'rarePlus',1); end if;
    if stars >= 5 then d.progress := private.genesis_progress_inc(d.progress,'superRarePlus',1); end if;
    if stars >= 8 then d.progress := private.genesis_progress_inc(d.progress,'legendaryPlus',1); end if;

    insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
    values(uid,p_request_key,'SUMMON_REWARD_'||lpad(i::text,2,'0'),reward,0,w.gp,w.essence,
      jsonb_build_object('rarity',rarity,'stars',stars,'seed',seed));
  end loop;

  if p_count=10 then d.progress := private.genesis_progress_inc(d.progress,'tenPulls',1); end if;

  update public.genesis_wallets
  set gp=w.gp, essence=w.essence, pity_count=w.pity_count, updated_at=now()
  where user_id=uid;

  update public.genesis_daily_server
  set progress=d.progress,updated_at=now()
  where user_id=uid and date_key=today;

  response := jsonb_build_object(
    'results',results,
    'cost',cost,
    'earned_gp',earned,
    'server_date',today,
    'reset_at',reset_at,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
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

-- ----------------------------------------------------------------
-- Public RPC: Essence spend gate
-- This protects the server wallet. Character-state validation remains a later phase.
-- ----------------------------------------------------------------

create or replace function public.genesis_spend_essence(
  p_amount bigint,
  p_reason text,
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
  response jsonb;
  allowed boolean := p_reason in ('TRAIN','ASCEND','WEAPON_UPGRADE','EQUIPMENT_UPGRADE');
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if not allowed then raise exception 'INVALID_ESSENCE_REASON'; end if;
  if p_amount <= 0 or p_amount > 1000000 then raise exception 'INVALID_ESSENCE_AMOUNT'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|genesis_spend_essence|' || p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_spend_essence' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  if w.essence < p_amount then raise exception 'INSUFFICIENT_ESSENCE'; end if;

  w.essence := w.essence - p_amount;
  update public.genesis_wallets set essence=w.essence,updated_at=now() where user_id=uid;

  insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
  values(uid,p_request_key,'ESSENCE_SPEND_'||p_reason,0,-p_amount,w.gp,w.essence,jsonb_build_object('reason',p_reason));

  response := jsonb_build_object(
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'spent_essence',p_amount,
    'reason',p_reason
  );
  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_spend_essence',p_request_key,response);
  return response;
end;
$$;

-- ----------------------------------------------------------------
-- Public RPC: claim one server Daily Mission
-- ----------------------------------------------------------------

create or replace function public.genesis_claim_daily_mission(
  p_mission_id text,
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
  ids text[] := private.genesis_daily_ids(today);
  metric text;
  target integer;
  value integer;
  reward jsonb;
  gp_delta integer;
  essence_delta integer;
  xp_delta integer;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if not (p_mission_id = any(ids)) then raise exception 'MISSION_NOT_ACTIVE_TODAY'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|genesis_claim_daily_mission|' || p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_claim_daily_mission' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  insert into public.genesis_daily_server(user_id,date_key)
  values(uid,today) on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;

  if coalesce((d.claimed ->> p_mission_id)::boolean,false) then raise exception 'MISSION_ALREADY_CLAIMED'; end if;
  metric := private.genesis_daily_metric(p_mission_id);
  target := private.genesis_daily_target(p_mission_id);
  value := coalesce((d.progress ->> metric)::integer,0);
  if value < target then raise exception 'MISSION_NOT_COMPLETE'; end if;

  reward := private.genesis_daily_reward(p_mission_id);
  gp_delta := coalesce((reward->>'gp')::integer,0);
  essence_delta := coalesce((reward->>'essence')::integer,0);
  xp_delta := coalesce((reward->>'xp')::integer,0);

  w.gp := w.gp + gp_delta;
  w.essence := w.essence + essence_delta;
  d.claimed := jsonb_set(d.claimed,array[p_mission_id],'true'::jsonb,true);

  update public.genesis_wallets set gp=w.gp,essence=w.essence,updated_at=now() where user_id=uid;
  update public.genesis_daily_server set claimed=d.claimed,updated_at=now()
    where user_id=uid and date_key=today;

  insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
  values(uid,p_request_key,'DAILY_MISSION_'||upper(p_mission_id),gp_delta,essence_delta,w.gp,w.essence,
    jsonb_build_object('mission_id',p_mission_id,'server_date',today));

  response := jsonb_build_object(
    'mission_id',p_mission_id,
    'reward_label',reward->>'label',
    'xp_delta',xp_delta,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count)
  );
  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_claim_daily_mission',p_request_key,response);
  return response;
end;
$$;

-- ----------------------------------------------------------------
-- Public RPC: 3/6 and 6/6 server completion bonus
-- ----------------------------------------------------------------

create or replace function public.genesis_claim_daily_completion(
  p_kind text,
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
  completed integer;
  gp_delta integer;
  essence_delta integer;
  xp_delta integer;
  label text;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_kind not in ('three','all') then raise exception 'INVALID_COMPLETION_KIND'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|genesis_claim_daily_completion|' || p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_claim_daily_completion' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  insert into public.genesis_daily_server(user_id,date_key)
  values(uid,today) on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;

  completed := private.genesis_completed_daily_count(today,d.progress);

  if p_kind='three' then
    if completed < 3 then raise exception 'THREE_MISSIONS_NOT_COMPLETE'; end if;
    if d.completion_three then raise exception 'THREE_BONUS_ALREADY_CLAIMED'; end if;
    gp_delta:=10; essence_delta:=50; xp_delta:=25; label:='10 GP + 50 Essence + 25 Summoner EXP';
    d.completion_three:=true;
  else
    if completed < 6 then raise exception 'ALL_MISSIONS_NOT_COMPLETE'; end if;
    if d.completion_all then raise exception 'ALL_BONUS_ALREADY_CLAIMED'; end if;
    gp_delta:=20; essence_delta:=100; xp_delta:=50; label:='20 GP + 100 Essence + 50 Summoner EXP';
    d.completion_all:=true;
  end if;

  w.gp:=w.gp+gp_delta;
  w.essence:=w.essence+essence_delta;

  update public.genesis_wallets set gp=w.gp,essence=w.essence,updated_at=now() where user_id=uid;
  update public.genesis_daily_server
  set completion_three=d.completion_three,completion_all=d.completion_all,updated_at=now()
  where user_id=uid and date_key=today;

  insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
  values(uid,p_request_key,'DAILY_COMPLETION_'||upper(p_kind),gp_delta,essence_delta,w.gp,w.essence,
    jsonb_build_object('completed_missions',completed,'server_date',today));

  response:=jsonb_build_object(
    'kind',p_kind,'reward_label',label,'xp_delta',xp_delta,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count)
  );
  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_claim_daily_completion',p_request_key,response);
  return response;
end;
$$;

-- ----------------------------------------------------------------
-- Public RPC: UTC server-authoritative 7-day Login Reward
-- ----------------------------------------------------------------

create or replace function public.genesis_claim_login(
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
  l public.genesis_login_server%rowtype;
  today date := (now() at time zone 'UTC')::date;
  day integer;
  gp_delta integer := 0;
  essence_delta integer := 0;
  label text;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|genesis_claim_login|' || p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_claim_login' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  insert into public.genesis_login_server(user_id)
  values(uid) on conflict(user_id) do nothing;
  select * into l from public.genesis_login_server where user_id=uid for update;

  if l.last_claim_date=today then raise exception 'LOGIN_ALREADY_CLAIMED_TODAY'; end if;

  if l.last_claim_date=today-1 then day:=(l.cycle_day % 7)+1;
  else day:=1;
  end if;

  case day
    when 1 then gp_delta:=5; label:='5 GP';
    when 2 then essence_delta:=25; label:='25 Essence';
    when 3 then gp_delta:=10; label:='10 GP';
    when 4 then essence_delta:=50; label:='50 Essence';
    when 5 then gp_delta:=15; label:='15 GP';
    when 6 then essence_delta:=100; label:='100 Essence';
    when 7 then gp_delta:=25; essence_delta:=150; label:='25 GP + 150 Essence';
  end case;

  w.gp:=w.gp+gp_delta;
  w.essence:=w.essence+essence_delta;
  l.last_claim_date:=today;
  l.cycle_day:=day;
  l.total_claims:=l.total_claims+1;
  if day=7 then l.full_cycles:=l.full_cycles+1; end if;

  update public.genesis_wallets set gp=w.gp,essence=w.essence,updated_at=now() where user_id=uid;
  update public.genesis_login_server
  set last_claim_date=l.last_claim_date,cycle_day=l.cycle_day,total_claims=l.total_claims,
      full_cycles=l.full_cycles,updated_at=now()
  where user_id=uid;

  insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
  values(uid,p_request_key,'LOGIN_DAY_'||day,gp_delta,essence_delta,w.gp,w.essence,jsonb_build_object('server_date',today));

  response:=jsonb_build_object(
    'reward_label',label,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'login',jsonb_build_object('cycle_day',l.cycle_day,'total_claims',l.total_claims,'full_cycles',l.full_cycles,'last_claim_date',l.last_claim_date)
  );
  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_claim_login',p_request_key,response);
  return response;
end;
$$;

-- ----------------------------------------------------------------
-- Function privileges
-- ----------------------------------------------------------------

revoke execute on function public.genesis_wallet_initialize(bigint,bigint) from public, anon;
revoke execute on function public.genesis_secure_snapshot() from public, anon;
revoke execute on function public.genesis_online_summon(integer,boolean,text) from public, anon;
revoke execute on function public.genesis_spend_essence(bigint,text,text) from public, anon;
revoke execute on function public.genesis_claim_daily_mission(text,text) from public, anon;
revoke execute on function public.genesis_claim_daily_completion(text,text) from public, anon;
revoke execute on function public.genesis_claim_login(text) from public, anon;

grant execute on function public.genesis_wallet_initialize(bigint,bigint) to authenticated;
grant execute on function public.genesis_secure_snapshot() to authenticated;
grant execute on function public.genesis_online_summon(integer,boolean,text) to authenticated;
grant execute on function public.genesis_spend_essence(bigint,text,text) to authenticated;
grant execute on function public.genesis_claim_daily_mission(text,text) to authenticated;
grant execute on function public.genesis_claim_daily_completion(text,text) to authenticated;
grant execute on function public.genesis_claim_login(text) to authenticated;

commit;

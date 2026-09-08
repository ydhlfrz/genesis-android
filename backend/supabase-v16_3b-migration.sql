-- Genesis - Character Gacha V16.3B
-- Server Character Progression & Equipment
--
-- PREREQUISITES:
-- 1. V16.0 base schema
-- 2. V16.1 migration
-- 3. V16.3A migration
--
-- Authority added:
-- - Character Level / EXP
-- - Evolution Stage
-- - Weapon upgrade +0..10
-- - Armor / Accessory / Relic / Artifact upgrades +0..10
-- - Essence payment and progression mutation in the SAME transaction
-- - Idempotent RPC receipts
--
-- Existing V16.3A registry rows keep their current canonical DB values.
-- Local browser progression is NOT imported.

begin;

do $$
begin
  if to_regclass('public.genesis_characters') is null then
    raise exception 'V16.3A migration is required before V16.3B';
  end if;
end
$$;

-- ------------------------------------------------------------
-- Private cost helpers matching the Genesis client formulas.
-- ------------------------------------------------------------

create or replace function private.genesis_character_xp_needed(p_level integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when p_level >= 100 then 0
    else 70 + p_level * 18 + floor(p_level * p_level * 0.6)::integer
  end
$$;

create or replace function private.genesis_training_essence_cost(p_level integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select greatest(12, round(10 + p_level * 2.4)::integer)
$$;

create or replace function private.genesis_weapon_upgrade_cost(p_level integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when p_level >= 10 then 0
    else round(45 + p_level * 35 + p_level * p_level * 4)::integer
  end
$$;

create or replace function private.genesis_u32(p_value bigint)
returns bigint
language sql
immutable
set search_path = ''
as $$
  select ((p_value % 4294967296) + 4294967296) % 4294967296
$$;

-- First output of the exact JS mulberry32 PRNG used for deterministic equipment rarity.
create or replace function private.genesis_mulberry32_first(p_seed_u32 bigint)
returns double precision
language plpgsql
immutable
set search_path = ''
as $$
declare
  t bigint;
  x bigint;
begin
  t := private.genesis_u32(p_seed_u32 + 1831565813); -- 0x6D2B79F5

  x := private.genesis_u32(
    (t # floor(t / 32768)::bigint) *
    (t | 1)
  );

  x := x # private.genesis_u32(
    x + private.genesis_u32(
      (x # floor(x / 128)::bigint) *
      (x | 61)
    )
  );

  x := private.genesis_u32(x # floor(x / 16384)::bigint);
  return x::double precision / 4294967296.0;
end;
$$;

create or replace function private.genesis_equipment_rarity_stars(
  p_seed text,
  p_slot text
)
returns integer
language plpgsql
immutable
set search_path = ''
as $$
declare
  suffix text;
  r double precision;
begin
  suffix := case lower(p_slot)
    when 'armor' then '|EQUIP|ARMOR'
    when 'accessory' then '|EQUIP|ACCESSORY'
    when 'relic' then '|EQUIP|RELIC'
    when 'artifact' then '|EQUIP|ARTIFACT'
    else null
  end;

  if suffix is null then
    raise exception 'INVALID_EQUIPMENT_SLOT';
  end if;

  r := private.genesis_mulberry32_first(
    private.genesis_fnv1a32(p_seed || suffix)
  ) * 100.0;

  -- EQUIPMENT_RARITIES weights sum exactly to 100.
  if r < 36.0 then return 1;
  elsif r < 61.0 then return 2;
  elsif r < 77.0 then return 3;
  elsif r < 87.0 then return 4;
  elsif r < 93.0 then return 5;
  elsif r < 96.5 then return 6;
  elsif r < 98.3 then return 7;
  elsif r < 99.3 then return 8;
  elsif r < 99.9 then return 9;
  else return 10;
  end if;
end;
$$;

create or replace function private.genesis_equipment_upgrade_cost(
  p_level integer,
  p_rarity_stars integer
)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when p_level >= 10 then 0
    else round(
      (30 + p_level * 26 + p_level * p_level * 3) *
      (1 + (greatest(1,least(10,p_rarity_stars)) - 1) * 0.08)
    )::integer
  end
$$;

create or replace function private.genesis_stage_name(p_stage integer)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_stage
    when 0 then 'Base'
    when 1 then 'Awakened'
    when 2 then 'Ascended'
    when 3 then 'Transcendent'
    else 'Base'
  end
$$;

create or replace function private.genesis_stage_level_requirement(p_stage integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_stage
    when 1 then 25
    when 2 then 50
    when 3 then 80
    else 1
  end
$$;

create or replace function private.genesis_stage_essence_cost(p_stage integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_stage
    when 1 then 250
    when 2 then 600
    when 3 then 1200
    else 0
  end
$$;

-- ------------------------------------------------------------
-- Consistent progression payload helper.
-- ------------------------------------------------------------

create or replace function private.genesis_character_progression_json(
  p_row public.genesis_characters
)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_build_object(
    'registry_id',p_row.registry_id,
    'character_id',p_row.character_id,
    'character_level',p_row.character_level,
    'character_xp',p_row.character_xp,
    'evolution_stage',p_row.evolution_stage,
    'weapon_upgrade',p_row.weapon_upgrade,
    'armor_upgrade',p_row.armor_upgrade,
    'accessory_upgrade',p_row.accessory_upgrade,
    'relic_upgrade',p_row.relic_upgrade,
    'artifact_upgrade',p_row.artifact_upgrade,
    'updated_at',p_row.updated_at
  )
$$;

-- ------------------------------------------------------------
-- Train character: one or five requested training steps.
-- ------------------------------------------------------------

create or replace function public.genesis_character_train(
  p_registry_id uuid,
  p_levels integer,
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
  c public.genesis_characters%rowtype;
  requested integer := greatest(1,least(coalesce(p_levels,1),5));
  i integer;
  cost integer;
  xp_need integer;
  total_cost integer := 0;
  levels_gained integer := 0;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_request_key is null or char_length(p_request_key) < 8 or char_length(p_request_key) > 160 then
    raise exception 'INVALID_REQUEST_KEY';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|train|' || p_registry_id::text || '|' || p_request_key,0));

  select r.response into existing
  from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_character_train' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  select * into c
  from public.genesis_characters
  where registry_id=p_registry_id and user_id=uid and archived=false
  for update;
  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  for i in 1..requested loop
    exit when c.character_level >= 100;

    cost := private.genesis_training_essence_cost(c.character_level);
    if w.essence < total_cost + cost then
      exit;
    end if;

    total_cost := total_cost + cost;
    xp_need := private.genesis_character_xp_needed(c.character_level);
    c.character_xp := c.character_xp + xp_need;

    while c.character_level < 100
      and c.character_xp >= private.genesis_character_xp_needed(c.character_level)
    loop
      c.character_xp := c.character_xp - private.genesis_character_xp_needed(c.character_level);
      c.character_level := c.character_level + 1;
      levels_gained := levels_gained + 1;
    end loop;
  end loop;

  if levels_gained <= 0 then
    if c.character_level >= 100 then raise exception 'MAX_CHARACTER_LEVEL'; end if;
    raise exception 'INSUFFICIENT_ESSENCE';
  end if;

  w.essence := w.essence - total_cost;

  update public.genesis_wallets
  set essence=w.essence,updated_at=now()
  where user_id=uid;

  update public.genesis_characters
  set character_level=c.character_level,
      character_xp=c.character_xp,
      updated_at=now()
  where registry_id=c.registry_id and user_id=uid
  returning * into c;

  insert into public.genesis_economy_ledger(
    user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
  )
  values(
    uid,p_request_key,'CHARACTER_TRAIN',0,-total_cost,w.gp,w.essence,
    jsonb_build_object(
      'registry_id',c.registry_id,
      'character_id',c.character_id,
      'levels_gained',levels_gained,
      'new_level',c.character_level
    )
  );

  response := jsonb_build_object(
    'levels_gained',levels_gained,
    'essence_spent',total_cost,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'character',private.genesis_character_progression_json(c)
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_character_train',p_request_key,response);

  return response;
end;
$$;

-- ------------------------------------------------------------
-- Ascend / evolve character.
-- ------------------------------------------------------------

create or replace function public.genesis_character_ascend(
  p_registry_id uuid,
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
  c public.genesis_characters%rowtype;
  next_stage integer;
  level_req integer;
  cost integer;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|ascend|' || p_registry_id::text || '|' || p_request_key,0));

  select r.response into existing
  from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_character_ascend' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  select * into c
  from public.genesis_characters
  where registry_id=p_registry_id and user_id=uid and archived=false
  for update;
  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  if c.evolution_stage >= 3 then raise exception 'MAX_EVOLUTION_STAGE'; end if;

  next_stage := c.evolution_stage + 1;
  level_req := private.genesis_stage_level_requirement(next_stage);
  cost := private.genesis_stage_essence_cost(next_stage);

  if c.character_level < level_req then raise exception 'LEVEL_REQUIREMENT_NOT_MET'; end if;
  if w.essence < cost then raise exception 'INSUFFICIENT_ESSENCE'; end if;

  w.essence := w.essence - cost;

  update public.genesis_wallets
  set essence=w.essence,updated_at=now()
  where user_id=uid;

  update public.genesis_characters
  set evolution_stage=next_stage,updated_at=now()
  where registry_id=c.registry_id and user_id=uid
  returning * into c;

  insert into public.genesis_economy_ledger(
    user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
  )
  values(
    uid,p_request_key,'CHARACTER_ASCEND',0,-cost,w.gp,w.essence,
    jsonb_build_object(
      'registry_id',c.registry_id,
      'character_id',c.character_id,
      'stage',next_stage,
      'stage_name',private.genesis_stage_name(next_stage)
    )
  );

  response := jsonb_build_object(
    'stage_name',private.genesis_stage_name(next_stage),
    'essence_spent',cost,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'character',private.genesis_character_progression_json(c)
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_character_ascend',p_request_key,response);

  return response;
end;
$$;

-- ------------------------------------------------------------
-- Weapon upgrade.
-- ------------------------------------------------------------

create or replace function public.genesis_character_upgrade_weapon(
  p_registry_id uuid,
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
  c public.genesis_characters%rowtype;
  cost integer;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|weapon|' || p_registry_id::text || '|' || p_request_key,0));

  select r.response into existing
  from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_character_upgrade_weapon' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  select * into c
  from public.genesis_characters
  where registry_id=p_registry_id and user_id=uid and archived=false
  for update;
  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  if c.weapon_upgrade >= 10 then raise exception 'MAX_WEAPON_UPGRADE'; end if;

  cost := private.genesis_weapon_upgrade_cost(c.weapon_upgrade);
  if w.essence < cost then raise exception 'INSUFFICIENT_ESSENCE'; end if;

  w.essence := w.essence - cost;

  update public.genesis_wallets
  set essence=w.essence,updated_at=now()
  where user_id=uid;

  update public.genesis_characters
  set weapon_upgrade=weapon_upgrade+1,updated_at=now()
  where registry_id=c.registry_id and user_id=uid
  returning * into c;

  insert into public.genesis_economy_ledger(
    user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
  )
  values(
    uid,p_request_key,'WEAPON_UPGRADE',0,-cost,w.gp,w.essence,
    jsonb_build_object(
      'registry_id',c.registry_id,
      'character_id',c.character_id,
      'upgrade_level',c.weapon_upgrade
    )
  );

  response := jsonb_build_object(
    'essence_spent',cost,
    'upgrade_level',c.weapon_upgrade,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'character',private.genesis_character_progression_json(c)
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_character_upgrade_weapon',p_request_key,response);

  return response;
end;
$$;

-- ------------------------------------------------------------
-- Equipment upgrade: server derives the item's rarity from seed + slot,
-- so the browser cannot lie about rarity to reduce the Essence cost.
-- ------------------------------------------------------------

create or replace function public.genesis_character_upgrade_equipment(
  p_registry_id uuid,
  p_slot text,
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
  c public.genesis_characters%rowtype;
  slot_name text := lower(coalesce(p_slot,''));
  current_level integer;
  rarity_stars integer;
  cost integer;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if slot_name not in ('armor','accessory','relic','artifact') then
    raise exception 'INVALID_EQUIPMENT_SLOT';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text || '|equipment|' || p_registry_id::text || '|' || slot_name || '|' || p_request_key,0));

  select r.response into existing
  from public.genesis_rpc_receipts r
  where r.user_id=uid and r.rpc_name='genesis_character_upgrade_equipment' and r.request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  select * into c
  from public.genesis_characters
  where registry_id=p_registry_id and user_id=uid and archived=false
  for update;
  if not found then raise exception 'CHARACTER_NOT_FOUND'; end if;

  current_level := case slot_name
    when 'armor' then c.armor_upgrade
    when 'accessory' then c.accessory_upgrade
    when 'relic' then c.relic_upgrade
    when 'artifact' then c.artifact_upgrade
  end;

  if current_level >= 10 then raise exception 'MAX_EQUIPMENT_UPGRADE'; end if;

  rarity_stars := private.genesis_equipment_rarity_stars(c.seed,slot_name);
  cost := private.genesis_equipment_upgrade_cost(current_level,rarity_stars);

  if w.essence < cost then raise exception 'INSUFFICIENT_ESSENCE'; end if;

  w.essence := w.essence - cost;

  update public.genesis_wallets
  set essence=w.essence,updated_at=now()
  where user_id=uid;

  if slot_name='armor' then
    update public.genesis_characters set armor_upgrade=armor_upgrade+1,updated_at=now()
    where registry_id=c.registry_id and user_id=uid returning * into c;
  elsif slot_name='accessory' then
    update public.genesis_characters set accessory_upgrade=accessory_upgrade+1,updated_at=now()
    where registry_id=c.registry_id and user_id=uid returning * into c;
  elsif slot_name='relic' then
    update public.genesis_characters set relic_upgrade=relic_upgrade+1,updated_at=now()
    where registry_id=c.registry_id and user_id=uid returning * into c;
  else
    update public.genesis_characters set artifact_upgrade=artifact_upgrade+1,updated_at=now()
    where registry_id=c.registry_id and user_id=uid returning * into c;
  end if;

  current_level := case slot_name
    when 'armor' then c.armor_upgrade
    when 'accessory' then c.accessory_upgrade
    when 'relic' then c.relic_upgrade
    when 'artifact' then c.artifact_upgrade
  end;

  insert into public.genesis_economy_ledger(
    user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
  )
  values(
    uid,p_request_key,'EQUIPMENT_UPGRADE_'||upper(slot_name),0,-cost,w.gp,w.essence,
    jsonb_build_object(
      'registry_id',c.registry_id,
      'character_id',c.character_id,
      'slot',slot_name,
      'rarity_stars',rarity_stars,
      'upgrade_level',current_level
    )
  );

  response := jsonb_build_object(
    'slot',slot_name,
    'rarity_stars',rarity_stars,
    'essence_spent',cost,
    'upgrade_level',current_level,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'character',private.genesis_character_progression_json(c)
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_character_upgrade_equipment',p_request_key,response);

  return response;
end;
$$;

-- ------------------------------------------------------------
-- RPC privileges: only authenticated users.
-- ------------------------------------------------------------

revoke execute on function public.genesis_character_train(uuid,integer,text) from public, anon;
revoke execute on function public.genesis_character_ascend(uuid,text) from public, anon;
revoke execute on function public.genesis_character_upgrade_weapon(uuid,text) from public, anon;
revoke execute on function public.genesis_character_upgrade_equipment(uuid,text,text) from public, anon;

grant execute on function public.genesis_character_train(uuid,integer,text) to authenticated;
grant execute on function public.genesis_character_ascend(uuid,text) to authenticated;
grant execute on function public.genesis_character_upgrade_weapon(uuid,text) to authenticated;
grant execute on function public.genesis_character_upgrade_equipment(uuid,text,text) to authenticated;

commit;

-- Genesis 17.0: versioned free-play economy and five-tier characters.
-- Apply AFTER all existing migrations. Transactional and repeatable.
begin;
alter table public.genesis_wallets add column if not exists economy_version integer not null default 1;
alter table public.genesis_wallets add column if not exists sr_pity integer not null default 0 check(sr_pity between 0 and 39);
alter table public.genesis_wallets add column if not exists mythic_pity integer not null default 0 check(mythic_pity between 0 and 89);
alter table public.genesis_wallets add column if not exists tickets integer not null default 0 check(tickets>=0);
alter table public.genesis_wallets add column if not exists tokens integer not null default 0 check(tokens>=0);
alter table public.genesis_characters add column if not exists rules_version integer not null default 1 check(rules_version in (1,2));
create table if not exists public.genesis_v2_claims(user_id uuid not null references auth.users(id) on delete cascade,day date not null,mission text not null,primary key(user_id,day,mission));
alter table public.genesis_v2_claims enable row level security;
revoke all on public.genesis_v2_claims from public,anon,authenticated;
grant select on public.genesis_v2_claims to authenticated;
drop policy if exists v2_claims_own on public.genesis_v2_claims;
create policy v2_claims_own on public.genesis_v2_claims for select to authenticated using(user_id=(select auth.uid()));
create or replace function private.genesis_v2_ensure(uid uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if uid is null then raise exception 'AUTH_REQUIRED'; end if;
 update public.genesis_wallets set sr_pity=least(pity_count,39),mythic_pity=floor(pity_count*89.0/60)::int,tickets=tickets+5,economy_version=2 where user_id=uid and economy_version=1;
 if not exists(select 1 from public.genesis_wallets where user_id=uid) then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED';end if;
end;$$;
create or replace function private.genesis_v2_band(r double precision) returns integer language sql immutable set search_path='' as $$
select case when r<.60 then 1 when r<.90 then 3 when r<.97 then 5 when r<.995 then 7 else 9 end;$$;
create or replace function private.genesis_v2_chance(failures integer) returns double precision language sql immutable set search_path='' as $$
select case when failures>=89 then 1.0 when failures>=69 then .005+.005*(failures-68) else .005 end;$$;
create or replace function private.genesis_v2_roll(sr integer,mythic integer,r double precision) returns integer language plpgsql immutable set search_path='' as $$
declare q double precision:=private.genesis_v2_chance(mythic); u double precision;
begin
 if r<q or mythic>=89 then return 9;end if;
 u:=(r-q)/(1-q);
 if sr>=39 then return case when u<7.0/9.5 then 5 else 7 end;end if;
 if u<60.0/99.5 then return 1;elsif u<90.0/99.5 then return 3;elsif u<97.0/99.5 then return 5;else return 7;end if;
end;$$;
create or replace function private.genesis_v2_pool(band integer) returns text[] language sql immutable set search_path='' as $$ select case band
when 1 then array['Beastkin','Centaur','Dark Elf','Dragonkin','Dryad','Dwarf','Elf','Fairy','Ghost','Ghoul','Golem','Harpy','Human','Imp','Leonin','Lich','Merfolk','Minotaur','Orc','Reptilian','Shadow','Undead']
when 3 then array['Asgardian','Beastkin','Centaur','Dark Elf','Djinn','Dragonkin','Dryad','Dwarf','Elf','Fairy','Fallen Angel','Ghost','Ghoul','Golem','Harpy','Human','Imp','Leonin','Lich','Merfolk','Minotaur','Oni','Orc','Pale Orc','Reptilian','Shadow','Slime','Spiritborn','Undead','Vampire','Voidborn']
when 5 then array['Ancient Egyptian','Asgardian','Beastkin','Celestial','Centaur','Dark Elf','Demi-God','Djinn','Dragonkin','Dryad','Dwarf','Elf','Fairy','Fallen Angel','Ghost','Ghoul','Golem','Harpy','Human','Imp','Kitsune','Krakenborn','Leonin','Lich','Merfolk','Minotaur','Oni','Orc','Pale Orc','Phoenixborn','Reptilian','Shadow','Slime','Spiritborn','Undead','Vampire','Voidborn']
when 7 then array['Ancient Egyptian','Angel','Archangel','Asgardian','Celestial','Demi-God','Demon','Fallen Angel','God','Kitsune','Krakenborn','Pale Orc','Phoenixborn','Slime','Spiritborn','Targaryen','Vampire','Voidborn']
when 9 then array['Ancient Egyptian','Angel','Archangel','Demon','God','Targaryen']
else null::text[] end;$$;
create or replace function private.genesis_v2_base_combat_power(
 p_race text,p_class text,p_rarity_stars integer,p_race_chance double precision,
 p_hidden_race boolean,p_hidden_class boolean,p_trait text,
 p_weapon_power integer,p_equipment_power integer
)
returns integer
language plpgsql immutable set search_path=''
as $$
declare
  bonus integer:=case p_rarity_stars when 1 then 0 when 2 then 4 when 3 then 8 when 4 then 12 when 5 then 17 when 6 then 23 when 7 then 30 when 8 then 38 when 9 then 47 else 58 end;
  rarity_bonus integer:=p_rarity_stars*280;
  stat_total integer:=0;
  stat text;
  val integer;
  race_bonus double precision;
  hidden_bonus integer:=(case when p_hidden_race then 650 else 0 end)+(case when p_hidden_class then 650 else 0 end);
  trait_bonus integer:=case when p_trait in ('Immortal Core','Six-Winged Awakening','Void Heart','Dragon Blood') then 260 else 100 end;
begin
  foreach stat in array array['STR','AGI','INT','DEF','VIT','LCK'] loop
    val:=50+bonus+private.genesis_race_stat_bonus(p_race,stat)+private.genesis_class_stat_bonus(p_class,stat);
    val:=greatest(10,least(120,round(val)::integer));
    stat_total:=stat_total+val;
  end loop;
  race_bonus:=least(900,greatest(0,(20-coalesce(p_race_chance,20))*40));
  return round(stat_total*12+rarity_bonus+p_weapon_power*1.4+p_equipment_power*1.15+race_bonus+hidden_bonus+trait_bonus)::integer;
end
$$;


create or replace function public.genesis_v2_summon(
  p_count integer,p_use_ticket boolean,p_request_key text
)
returns jsonb
language plpgsql security definer set search_path=''
as $$
declare
  uid uuid:=(select auth.uid());
  existing jsonb;
  w public.genesis_wallets%rowtype;
  d public.genesis_daily_server%rowtype;
  today date:=(now() at time zone 'UTC')::date;
  reset_at timestamptz:=((today+1)::timestamp at time zone 'UTC');
  cost integer:=p_count*12; pool text[];
  i integer; stars integer; rarity text; reward integer; earned integer:=0;
  results jsonb:='[]'::jsonb; seed text; cid text; response jsonb;
  session_id uuid:=gen_random_uuid(); new_registry_id uuid; character_created_at timestamptz;
  race_name text; class_name text; trait_name text; weapon_name text; hidden jsonb;
  weapon_stars integer; weapon_power integer;
  armor_name text; accessory_name text; relic_name text; artifact_name text;
  armor_stars integer; accessory_stars integer; relic_stars integer; artifact_stars integer;
  armor_power integer; accessory_power integer; relic_power integer; artifact_power integer;
  equip_power integer; race_chance double precision; cp integer;
  new_discovery boolean; summon_xp integer; rarity_xp integer;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_count is null or p_count not in (1,10) then raise exception 'INVALID_SUMMON_COUNT'; end if;
  if p_request_key is null or char_length(p_request_key)<8 or char_length(p_request_key)>160 then raise exception 'INVALID_REQUEST_KEY'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text||'|genesis_online_summon|'||p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_v2_summon' and request_key=p_request_key;
  if found then return existing; end if;

  perform private.genesis_v2_ensure(uid);
  select * into w from public.genesis_wallets where user_id=uid for update;
  -- Recheck after the account lock: concurrent retries must return the same receipt.
  select r.response into existing from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_v2_summon' and request_key=p_request_key;
  if found then return existing;end if;
  if p_use_ticket is null then raise exception 'INVALID_PAYMENT';end if;
  if p_use_ticket then
    if w.tickets<p_count then raise exception 'INSUFFICIENT_TICKETS';end if;
    w.tickets:=w.tickets-p_count;cost:=0;
  end if;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  if w.gp<cost then raise exception 'INSUFFICIENT_GP'; end if;

  insert into public.genesis_summon_sessions(id,user_id,request_key,summon_count,gp_cost,gp_earned)
  values(session_id,uid,p_request_key,p_count,cost,0);

  if cost>0 then
    w.gp:=w.gp-cost;
    insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
    values(uid,p_request_key,'SUMMON_COST',-cost,0,w.gp,w.essence,jsonb_build_object('count',p_count,'summon_session_id',session_id));
  end if;

  insert into public.genesis_daily_server(user_id,date_key) values(uid,today) on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;

  for i in 1..p_count loop
    stars:=private.genesis_v2_roll(w.sr_pity,w.mythic_pity,random());
    rarity:=case stars when 1 then 'Common' when 3 then 'Rare' when 5 then 'Super Rare' when 7 then 'Epic' else 'Mythic' end;
    reward:=0;
    if stars>=5 then w.sr_pity:=0;else w.sr_pity:=least(39,w.sr_pity+1);end if;
    if stars=9 then w.mythic_pity:=0;else w.mythic_pity:=least(89,w.mythic_pity+1);end if;
    seed:='G165-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12))||'-'||lpad(i::text,2,'0');
    cid:=private.genesis_character_id_from_seed(seed);
    pool:=private.genesis_v2_pool(stars);
    race_name:=pool[floor(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|RACE_V2'),1)*array_length(pool,1))::integer+1];
    class_name:=private.genesis_server_class(seed);
    trait_name:=private.genesis_server_trait(seed);
    hidden:=jsonb_build_object('hidden_race',false,'hidden_class',false);
    weapon_name:=private.genesis_server_weapon(seed);

    weapon_stars:=private.genesis_v2_band(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|WEAPON'),1));
    weapon_power:=private.genesis_weapon_power(seed,weapon_name,weapon_stars);

    armor_stars:=private.genesis_v2_band(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|ARMOR'),1));
    accessory_stars:=private.genesis_v2_band(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|ACCESSORY'),1));
    relic_stars:=private.genesis_v2_band(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|RELIC'),1));
    artifact_stars:=private.genesis_v2_band(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|ARTIFACT'),1));

    armor_name:=private.genesis_equipment_name(seed,'ARMOR');
    accessory_name:=private.genesis_equipment_name(seed,'ACCESSORY');
    relic_name:=private.genesis_equipment_name(seed,'RELIC');
    artifact_name:=private.genesis_equipment_name(seed,'ARTIFACT');

    armor_power:=private.genesis_equipment_power(seed,'ARMOR',armor_stars);
    accessory_power:=private.genesis_equipment_power(seed,'ACCESSORY',accessory_stars);
    relic_power:=private.genesis_equipment_power(seed,'RELIC',relic_stars);
    artifact_power:=private.genesis_equipment_power(seed,'ARTIFACT',artifact_stars);
    equip_power:=armor_power+accessory_power+relic_power+artifact_power;
    race_chance:=100.0/array_length(pool,1);

    cp:=private.genesis_v2_base_combat_power(
      race_name,class_name,stars,race_chance,
      coalesce((hidden->>'hidden_race')::boolean,false),coalesce((hidden->>'hidden_class')::boolean,false),
      trait_name,weapon_power,equip_power
    );

    insert into public.genesis_characters(
      user_id,summon_session_id,character_id,seed,rarity_name,rarity_stars,gp_reward,summon_index,rules_version
    ) values(uid,session_id,cid,seed,rarity,stars,reward,i,2)
    returning registry_id,created_at into new_registry_id,character_created_at;

    insert into public.genesis_character_facts(
      registry_id,user_id,base_race,base_class,hidden_race_name,hidden_class_name,hidden_race,hidden_class,trait_name,
      weapon_name,weapon_rarity_stars,weapon_power,
      armor_name,armor_rarity_stars,armor_power,accessory_name,accessory_rarity_stars,accessory_power,
      relic_name,relic_rarity_stars,relic_power,artifact_name,artifact_rarity_stars,artifact_power,base_combat_power
    ) values(
      new_registry_id,uid,race_name,class_name,hidden->>'hidden_race_name',hidden->>'hidden_class_name',
      coalesce((hidden->>'hidden_race')::boolean,false),coalesce((hidden->>'hidden_class')::boolean,false),trait_name,
      weapon_name,weapon_stars,weapon_power,
      armor_name,armor_stars,armor_power,accessory_name,accessory_stars,accessory_power,
      relic_name,relic_stars,relic_power,artifact_name,artifact_stars,artifact_power,cp
    );

    new_discovery:=false;
    if private.genesis_codex_touch(uid,'race',race_name,stars,0,character_created_at) then new_discovery:=true; end if;
    if private.genesis_codex_touch(uid,'class',class_name,stars,0,character_created_at) then new_discovery:=true; end if;
    if private.genesis_codex_touch(uid,'rarity',rarity,stars,0,character_created_at) then new_discovery:=true; end if;
    perform private.genesis_codex_touch(uid,'weapon',weapon_name,weapon_stars,weapon_power,character_created_at);
    perform private.genesis_codex_touch(uid,'equipment','Armor|'||armor_name,armor_stars,armor_power,character_created_at);
    perform private.genesis_codex_touch(uid,'equipment','Accessory|'||accessory_name,accessory_stars,accessory_power,character_created_at);
    perform private.genesis_codex_touch(uid,'equipment','Relic|'||relic_name,relic_stars,relic_power,character_created_at);
    perform private.genesis_codex_touch(uid,'equipment','Artifact|'||artifact_name,artifact_stars,artifact_power,character_created_at);
    if coalesce((hidden->>'hidden_race')::boolean,false) then
      perform private.genesis_codex_touch(uid,'hidden_race',hidden->>'hidden_race_name',stars,0,character_created_at); new_discovery:=true;
    end if;
    if coalesce((hidden->>'hidden_class')::boolean,false) then
      perform private.genesis_codex_touch(uid,'hidden_class',hidden->>'hidden_class_name',stars,0,character_created_at); new_discovery:=true;
    end if;

    rarity_xp:=case stars when 1 then 10 when 2 then 14 when 3 then 20 when 4 then 28 when 5 then 38 when 6 then 50 when 7 then 68 when 8 then 95 when 9 then 150 else 300 end;
    summon_xp:=rarity_xp
      + case when new_discovery then 35 else 0 end
      + greatest(0,round((5-race_chance)*8)::integer)
      + case when coalesce((hidden->>'hidden_race')::boolean,false) or coalesce((hidden->>'hidden_class')::boolean,false) then 45 else 0 end;
    perform private.genesis_apply_summoner_xp(uid,summon_xp);

    results:=results||jsonb_build_array(jsonb_build_object(
      'registry_id',new_registry_id,'session_id',session_id,'character_id',cid,'seed',seed,'rarity',rarity,'stars',stars,
      'gp_reward',reward,'summon_index',i,'created_at',character_created_at
    ));

    d.progress:=private.genesis_progress_inc(d.progress,'summons',1);
    d.progress:=private.genesis_progress_inc(d.progress,'gpEarned',reward);
    if stars>=3 then d.progress:=private.genesis_progress_inc(d.progress,'rarePlus',1); end if;
    if stars>=5 then d.progress:=private.genesis_progress_inc(d.progress,'superRarePlus',1); end if;
    if stars>=8 then d.progress:=private.genesis_progress_inc(d.progress,'legendaryPlus',1); end if;

    insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
    values(uid,p_request_key,'SUMMON_REWARD_'||lpad(i::text,2,'0'),reward,0,w.gp,w.essence,
      jsonb_build_object('rarity',rarity,'stars',stars,'seed',seed,'character_id',cid,'registry_id',new_registry_id,'summon_session_id',session_id));
  end loop;

  if p_count=10 then d.progress:=private.genesis_progress_inc(d.progress,'tenPulls',1); end if;

  update public.genesis_wallets set gp=w.gp,essence=w.essence,tickets=w.tickets,sr_pity=w.sr_pity,mythic_pity=w.mythic_pity,updated_at=now() where user_id=uid;
  update public.genesis_daily_server set progress=d.progress,updated_at=now() where user_id=uid and date_key=today;
  update public.genesis_summon_sessions set gp_earned=earned where id=session_id and user_id=uid;

  response:=jsonb_build_object(
    'session_id',session_id,'results',results,'cost',cost,'earned_gp',earned,'server_date',today,'reset_at',reset_at,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'sr_pity',w.sr_pity,'mythic_pity',w.mythic_pity,'tickets',w.tickets,'tokens',w.tokens),
    'daily',jsonb_build_object('mission_ids',to_jsonb(private.genesis_daily_ids(today)),'progress',d.progress,'claimed',d.claimed,'completion_three',d.completion_three,'completion_all',d.completion_all)
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_v2_summon',p_request_key,response);

  return response;
end
$$;


create or replace function public.genesis_v2_status() returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=(select auth.uid());w public.genesis_wallets%rowtype;today date:=(now() at time zone 'UTC')::date;claims jsonb;pulls integer;training integer;upgrades integer;
begin
 perform private.genesis_v2_ensure(uid);
 select * into w from public.genesis_wallets where user_id=uid;
 select coalesce(jsonb_agg(mission),'[]') into claims from public.genesis_v2_claims where user_id=uid and day=today;
 select coalesce(sum(summon_count),0) into pulls from public.genesis_summon_sessions where user_id=uid and created_at>=(today::timestamp at time zone 'UTC');
 select count(*) filter(where event_type='CHARACTER_TRAIN'),count(*) filter(where event_type='WEAPON_UPGRADE' or event_type like 'EQUIPMENT_UPGRADE_%') into training,upgrades from public.genesis_economy_ledger where user_id=uid and created_at>=(today::timestamp at time zone 'UTC');
 return jsonb_build_object('version',2,'wallet',to_jsonb(w)-'user_id','claims',claims,'server_date',today,'mythic_chance',private.genesis_v2_chance(w.mythic_pity), 'progress',jsonb_build_object('checkin',1,'summon1',pulls,'summon3',pulls,'train1',training,'upgrade1',upgrades));
end;$$;
create or replace function public.genesis_v2_claim(p_mission text,p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=(select auth.uid());today date:=(now() at time zone 'UTC')::date;w public.genesis_wallets%rowtype;snap jsonb;response jsonb;g integer:=0;e integer:=0;t integer:=0;k integer:=0;target integer:=1;
begin
 if uid is null then raise exception 'AUTH_REQUIRED';end if;
 if p_request_key is null or length(p_request_key) not between 8 and 160 then raise exception 'INVALID_REQUEST_KEY';end if;
 perform private.genesis_v2_ensure(uid);
 select * into w from public.genesis_wallets where user_id=uid for update;
 select r.response into response from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_v2_claim' and request_key=p_request_key;
 if found then return response;end if;
 case p_mission
 when 'checkin' then g:=60;e:=50;t:=10;k:=1;
 when 'summon1' then g:=12;
 when 'summon3' then g:=24;target:=3;
 when 'train1' then g:=12;e:=15;
 when 'upgrade1' then g:=12;e:=20;
 else raise exception 'INVALID_MISSION';end case;
 if exists(select 1 from public.genesis_v2_claims where user_id=uid and day=today and mission=p_mission) then raise exception 'ALREADY_CLAIMED';end if;
 snap:=public.genesis_v2_status();
 if coalesce((snap->'progress'->>p_mission)::int,0)<target then raise exception 'MISSION_NOT_COMPLETE';end if;
 insert into public.genesis_v2_claims values(uid,today,p_mission);
 update public.genesis_wallets set gp=gp+g,essence=essence+e,tokens=tokens+t,tickets=tickets+k,updated_at=now() where user_id=uid returning * into w;
 insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata) values(uid,p_request_key,'V2_MISSION_'||p_mission,g,e,w.gp,w.essence,jsonb_build_object('tokens',t,'tickets',k,'day',today));
 response:=jsonb_build_object('gp',g,'essence',e,'tokens',t,'tickets',k);
 insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response) values(uid,'genesis_v2_claim',p_request_key,response);
 return response;
end;$$;
create or replace function public.genesis_v2_shop_buy(p_item text,p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=(select auth.uid());w public.genesis_wallets%rowtype;cost integer;amount integer;response jsonb;
begin
 if uid is null then raise exception 'AUTH_REQUIRED';end if;
 if p_request_key is null or length(p_request_key) not between 8 and 160 then raise exception 'INVALID_REQUEST_KEY';end if;
 perform private.genesis_v2_ensure(uid);
 select * into w from public.genesis_wallets where user_id=uid for update;
 select r.response into response from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_v2_shop_buy' and request_key=p_request_key;
 if found then return response;end if;
 case p_item when 'essence50' then cost:=5;amount:=50;when 'essence150' then cost:=12;amount:=150;else raise exception 'INVALID_SHOP_ITEM';end case;
 if w.tokens<cost then raise exception 'INSUFFICIENT_TOKENS';end if;
 update public.genesis_wallets set tokens=tokens-cost,essence=essence+amount,updated_at=now() where user_id=uid returning * into w;
 response:=jsonb_build_object('item',p_item,'tokens_spent',cost,'essence_received',amount);
 insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata) values(uid,p_request_key,'V2_SHOP',0,amount,w.gp,w.essence,response);
 insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response) values(uid,'genesis_v2_shop_buy',p_request_key,response);
 return response;
end;$$;
create or replace function public.genesis_online_summon(p_count integer,p_pity_enabled boolean,p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$begin raise exception 'UPDATE_REQUIRED_USE_V2';end;$$;
create or replace function public.genesis_claim_daily_mission(p_mission_id text,p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$begin raise exception 'UPDATE_REQUIRED_USE_V2';end;$$;
create or replace function public.genesis_claim_daily_completion(p_kind text,p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$begin raise exception 'UPDATE_REQUIRED_USE_V2';end;$$;
create or replace function public.genesis_claim_login(p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$begin raise exception 'UPDATE_REQUIRED_USE_V2';end;$$;
revoke all on function public.genesis_v2_summon(integer,boolean,text) from public,anon;
grant execute on function public.genesis_v2_summon(integer,boolean,text) to authenticated;
revoke all on function public.genesis_v2_status() from public,anon;
grant execute on function public.genesis_v2_status() to authenticated;
revoke all on function public.genesis_v2_claim(text,text) from public,anon;
grant execute on function public.genesis_v2_claim(text,text) to authenticated;
revoke all on function public.genesis_v2_shop_buy(text,text) from public,anon;
grant execute on function public.genesis_v2_shop_buy(text,text) to authenticated;
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

  if p_seed like 'G165-%' then return private.genesis_v2_band(r/100.0);end if;
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


create or replace function private.genesis_achievement_met(p_uid uuid,p_id text)
returns boolean
language plpgsql stable security definer set search_path=''
as $$
declare
  n bigint; level_value integer; wallet_ess bigint;
begin
  if p_id in ('first_legendary','first_primordial','legendary_10','all_rarities','hidden_form','collection_legendary_10','login_7','login_30','primordial_human','primordial_weapon','primordial_equipment') then return false;end if;
  case p_id
    when 'first_legendary' then return exists(select 1 from public.genesis_characters where user_id=p_uid and rarity_stars=8);
    when 'first_mythical' then return exists(select 1 from public.genesis_characters where user_id=p_uid and rarity_stars=9);
    when 'first_primordial' then return exists(select 1 from public.genesis_characters where user_id=p_uid and rarity_stars=10);
    when 'first_10x' then return exists(select 1 from public.genesis_summon_sessions where user_id=p_uid and summon_count=10);
    when 'summons_100' then select count(*) into n from public.genesis_characters where user_id=p_uid; return n>=100;
    when 'summons_500' then select count(*) into n from public.genesis_characters where user_id=p_uid; return n>=500;
    when 'summons_1000' then select count(*) into n from public.genesis_characters where user_id=p_uid; return n>=1000;
    when 'legendary_10' then select count(*) into n from public.genesis_characters where user_id=p_uid and rarity_stars>=8; return n>=10;
    when 'mythical_5' then select count(*) into n from public.genesis_characters where user_id=p_uid and rarity_stars>=9; return n>=5;

    when 'race_10' then select count(*) into n from public.genesis_player_codex where user_id=p_uid and codex_type='race'; return n>=10;
    when 'race_25' then select count(*) into n from public.genesis_player_codex where user_id=p_uid and codex_type='race'; return n>=25;
    when 'all_races' then select count(*) into n from public.genesis_player_codex where user_id=p_uid and codex_type='race'; return n>=42;
    when 'family_mortal' then return (select count(*) from public.genesis_player_codex where user_id=p_uid and codex_type='race' and entry_key in ('Human','Dwarf','Orc','Pale Orc'))=4;
    when 'family_fae' then return (select count(*) from public.genesis_player_codex where user_id=p_uid and codex_type='race' and entry_key in ('Elf','Dark Elf','Fairy','Dryad','Kitsune'))=5;
    when 'family_undead' then return (select count(*) from public.genesis_player_codex where user_id=p_uid and codex_type='race' and entry_key in ('Ghoul','Ghost','Undead','Lich','Vampire'))=5;
    when 'all_families' then return (
      select count(distinct private.genesis_race_family(entry_key))
      from public.genesis_player_codex where user_id=p_uid and codex_type='race'
    )>=14;
    when 'all_rarities' then select count(*) into n from public.genesis_player_codex where user_id=p_uid and codex_type='rarity'; return n>=10;
    when 'hidden_form' then return exists(select 1 from public.genesis_character_facts where user_id=p_uid and (hidden_race or hidden_class));

    when 'collector_10' then select count(*) into n from public.genesis_characters where user_id=p_uid and archived=false; return n>=10;
    when 'collector_25' then select count(*) into n from public.genesis_characters where user_id=p_uid and archived=false; return n>=25;
    when 'collector_100' then select count(*) into n from public.genesis_characters where user_id=p_uid and archived=false; return n>=100;
    when 'collection_legendary_10' then select count(*) into n from public.genesis_characters where user_id=p_uid and archived=false and rarity_stars>=8; return n>=10;
    when 'collection_mythical_5' then select count(*) into n from public.genesis_characters where user_id=p_uid and archived=false and rarity_stars>=9; return n>=5;
    when 'favorites_10' then select count(*) into n from public.genesis_characters where user_id=p_uid and archived=false and favorite; return n>=10;

    when 'summoner_25' then select summoner_level into level_value from public.genesis_profiles where user_id=p_uid; return coalesce(level_value,1)>=25;
    when 'summoner_50' then select summoner_level into level_value from public.genesis_profiles where user_id=p_uid; return coalesce(level_value,1)>=50;
    when 'first_duplicate' then return exists(
      select 1 from public.genesis_character_facts
      where user_id=p_uid group by base_race,base_class having count(*)>=2
    );
    when 'first_awakened' then return exists(select 1 from public.genesis_characters where user_id=p_uid and evolution_stage>=1);
    when 'first_ascended' then return exists(select 1 from public.genesis_characters where user_id=p_uid and evolution_stage>=2);
    when 'first_transcendent' then return exists(select 1 from public.genesis_characters where user_id=p_uid and evolution_stage>=3);
    when 'character_level_50' then return exists(select 1 from public.genesis_characters where user_id=p_uid and character_level>=50);
    when 'character_level_100' then return exists(select 1 from public.genesis_characters where user_id=p_uid and character_level>=100);
    when 'weapon_plus_10' then return exists(select 1 from public.genesis_characters where user_id=p_uid and weapon_upgrade>=10);
    when 'all_gear_plus_10' then return exists(select 1 from public.genesis_characters where user_id=p_uid and weapon_upgrade>=10 and armor_upgrade>=10 and accessory_upgrade>=10 and relic_upgrade>=10 and artifact_upgrade>=10);
    when 'essence_1000' then select essence into wallet_ess from public.genesis_wallets where user_id=p_uid; return coalesce(wallet_ess,0)>=1000;
    when 'power_12000' then return exists(select 1 from public.genesis_character_facts where user_id=p_uid and base_combat_power>=12000);

    when 'daily_10' then select count(*) into n from public.genesis_v2_claims where user_id=p_uid and mission<>'checkin'; return n+(select count(*) from public.genesis_daily_server d cross join lateral jsonb_each(d.claimed) e where d.user_id=p_uid and e.value='true'::jsonb)>=10;
    when 'daily_50' then select count(*) into n from public.genesis_v2_claims where user_id=p_uid and mission<>'checkin'; return n+(select count(*) from public.genesis_daily_server d cross join lateral jsonb_each(d.claimed) e where d.user_id=p_uid and e.value='true'::jsonb)>=50;
    when 'daily_100' then select count(*) into n from public.genesis_v2_claims where user_id=p_uid and mission<>'checkin'; return n+(select count(*) from public.genesis_daily_server d cross join lateral jsonb_each(d.claimed) e where d.user_id=p_uid and e.value='true'::jsonb)>=100;
    when 'perfect_daily' then return exists(select 1 from public.genesis_daily_server where user_id=p_uid and completion_all) or exists(select day from public.genesis_v2_claims where user_id=p_uid group by day having count(*)=5);
    when 'login_7' then return exists(select 1 from public.genesis_login_server where user_id=p_uid and full_cycles>=1);
    when 'login_30' then return exists(select 1 from public.genesis_login_server where user_id=p_uid and total_claims>=30);

    when 'summon_god' then return exists(select 1 from public.genesis_character_facts where user_id=p_uid and base_race='God');
    when 'summon_archangel' then return exists(select 1 from public.genesis_character_facts where user_id=p_uid and base_race='Archangel');
    when 'primordial_human' then return exists(
      select 1 from public.genesis_character_facts f join public.genesis_characters c on c.registry_id=f.registry_id
      where f.user_id=p_uid and f.base_race='Human' and c.rarity_stars=10
    );
    when 'primordial_weapon' then return exists(select 1 from public.genesis_character_facts where user_id=p_uid and weapon_rarity_stars=10);
    when 'primordial_equipment' then return exists(select 1 from public.genesis_character_facts where user_id=p_uid and greatest(armor_rarity_stars,accessory_rarity_stars,relic_rarity_stars,artifact_rarity_stars)=10);
    else return false;
  end case;
end
$$;


revoke all on all functions in schema private from public,anon,authenticated;
commit;

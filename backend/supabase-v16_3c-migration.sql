-- Genesis - Character Gacha V16.3C
-- Server Codex, Verified Achievements & Achievement Points
--
-- Prerequisites: V16.1, V16.3A, V16.3B
--
-- IMPORTANT GENERATOR BOUNDARY
-- Future authoritative summons use G163 seeds. G163 character facts use independent
-- deterministic sub-seeds so PostgreSQL and the browser can reproduce the same facts.
-- Existing G161 test characters remain valid owned/progression records but are not
-- trusted to backfill detailed Codex facts that were never recorded by the server.

begin;

do $$
begin
  if to_regclass('public.genesis_characters') is null then
    raise exception 'V16.3A is required before V16.3C';
  end if;
  if to_regprocedure('public.genesis_character_train(uuid,integer,text)') is null then
    raise exception 'V16.3B is required before V16.3C';
  end if;
end
$$;

-- ------------------------------------------------------------
-- Profile: authoritative Summoner XP + Level.
-- ------------------------------------------------------------
alter table public.genesis_profiles
  add column if not exists summoner_xp bigint not null default 0 check (summoner_xp >= 0);

-- ------------------------------------------------------------
-- Verified deterministic character facts.
-- ------------------------------------------------------------
create table if not exists public.genesis_character_facts (
  registry_id uuid primary key references public.genesis_characters(registry_id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  base_race text not null,
  base_class text not null,
  hidden_race_name text,
  hidden_class_name text,
  hidden_race boolean not null default false,
  hidden_class boolean not null default false,
  trait_name text not null,
  weapon_name text not null,
  weapon_rarity_stars integer not null check (weapon_rarity_stars between 1 and 10),
  weapon_power integer not null check (weapon_power >= 0),
  armor_name text not null,
  armor_rarity_stars integer not null check (armor_rarity_stars between 1 and 10),
  armor_power integer not null check (armor_power >= 0),
  accessory_name text not null,
  accessory_rarity_stars integer not null check (accessory_rarity_stars between 1 and 10),
  accessory_power integer not null check (accessory_power >= 0),
  relic_name text not null,
  relic_rarity_stars integer not null check (relic_rarity_stars between 1 and 10),
  relic_power integer not null check (relic_power >= 0),
  artifact_name text not null,
  artifact_rarity_stars integer not null check (artifact_rarity_stars between 1 and 10),
  artifact_power integer not null check (artifact_power >= 0),
  base_combat_power integer not null check (base_combat_power >= 0),
  created_at timestamptz not null default now(),
  unique(user_id,registry_id)
);

alter table public.genesis_character_facts enable row level security;
revoke all on public.genesis_character_facts from anon, authenticated;
grant select on public.genesis_character_facts to authenticated;

drop policy if exists "Genesis facts select own" on public.genesis_character_facts;
create policy "Genesis facts select own"
on public.genesis_character_facts for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid())=user_id);

-- ------------------------------------------------------------
-- Server Codex.
-- ------------------------------------------------------------
create table if not exists public.genesis_player_codex (
  user_id uuid not null references auth.users(id) on delete cascade,
  codex_type text not null check (codex_type in ('race','class','rarity','hidden_race','hidden_class','weapon','equipment')),
  entry_key text not null,
  first_discovered_at timestamptz not null default now(),
  last_obtained_at timestamptz not null default now(),
  times_obtained integer not null default 1 check (times_obtained >= 1),
  best_rarity_stars integer check (best_rarity_stars between 1 and 10),
  highest_power integer not null default 0 check (highest_power >= 0),
  primary key(user_id,codex_type,entry_key)
);

alter table public.genesis_player_codex enable row level security;
revoke all on public.genesis_player_codex from anon, authenticated;
grant select on public.genesis_player_codex to authenticated;

drop policy if exists "Genesis codex select own" on public.genesis_player_codex;
create policy "Genesis codex select own"
on public.genesis_player_codex for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid())=user_id);

-- ------------------------------------------------------------
-- Verified achievements.
-- ------------------------------------------------------------
create table if not exists public.genesis_player_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  ap integer not null check (ap >= 0),
  reward_gp integer not null default 0 check (reward_gp >= 0),
  reward_essence integer not null default 0 check (reward_essence >= 0),
  reward_xp integer not null default 0 check (reward_xp >= 0),
  unlocked_at timestamptz not null default now(),
  primary key(user_id,achievement_id)
);

alter table public.genesis_player_achievements enable row level security;
revoke all on public.genesis_player_achievements from anon, authenticated;
grant select on public.genesis_player_achievements to authenticated;

drop policy if exists "Genesis achievements select own" on public.genesis_player_achievements;
create policy "Genesis achievements select own"
on public.genesis_player_achievements for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid())=user_id);

-- ------------------------------------------------------------
-- Deterministic G163 helpers.
-- ------------------------------------------------------------

create or replace function private.genesis_mulberry32_at(p_seed_u32 bigint,p_index integer)
returns double precision
language plpgsql
immutable
set search_path=''
as $$
declare
  a bigint := private.genesis_u32(p_seed_u32);
  t bigint;
  x bigint;
  out_value double precision := 0;
  i integer;
begin
  if p_index < 1 then raise exception 'INVALID_RNG_INDEX'; end if;
  for i in 1..p_index loop
    a := private.genesis_u32(a + 1831565813);
    t := a;
    x := private.genesis_u32((t # floor(t/32768)::bigint) * (t | 1));
    x := x # private.genesis_u32(x + private.genesis_u32((x # floor(x/128)::bigint) * (x | 61)));
    x := private.genesis_u32(x # floor(x/16384)::bigint);
    out_value := x::double precision / 4294967296.0;
  end loop;
  return out_value;
end
$$;

create or replace function private.genesis_rarity_stars_from_name(p_name text)
returns integer
language sql immutable set search_path=''
as $$
  select case p_name
    when 'Common' then 1 when 'Uncommon' then 2 when 'Rare' then 3
    when 'Special Rare' then 4 when 'Super Rare' then 5 when 'Super Special Rare' then 6
    when 'Epic' then 7 when 'Legendary' then 8 when 'Mythical' then 9 when 'Primordial' then 10
    else 1 end
$$;

create or replace function private.genesis_race_allowed(p_race text,p_stars integer)
returns boolean
language sql immutable set search_path=''
as $$
  select case
    when p_race='God' then p_stars in (9,10)
    when p_race in ('Demi-God','Archangel','Angel','Demon') then p_stars>=6
    when p_race='Targaryen' then p_stars>=8
    when p_race in ('Dryad','Golem') then p_stars>=3
    when p_race='Krakenborn' then p_stars>=4
    when p_race in ('Kitsune','Oni') then p_stars>=5
    when p_race='Djinn' then p_stars>=6
    when p_race='Phoenixborn' then p_stars>=7
    else true end
$$;

create or replace function private.genesis_server_race(p_seed text,p_stars integer)
returns text
language plpgsql immutable set search_path=''
as $$
declare
  r double precision;
  total double precision := 0;
  acc double precision := 0;
  rec record;
begin
  for rec in
    select * from (values
      ('Human',20.0),('Elf',6.7),('Orc',5.7),('Dwarf',5.2),('Beastkin',4.8),('Slime',4.0),
      ('Pale Orc',3.5),('Reptilian',3.5),('Dark Elf',3.0),('Minotaur',3.0),('Centaur',3.0),
      ('Leonin',3.0),('Imp',2.5),('Shadow',2.5),('Harpy',2.5),('Merfolk',2.5),('Fairy',2.2),
      ('Spiritborn',2.2),('Ghoul',2.2),('Ghost',2.2),('Undead',2.2),('Dragonkin',2.0),
      ('Vampire',1.8),('Ancient Egyptian',1.8),('Fallen Angel',1.5),('Lich',1.2),('Asgardian',1.2),
      ('Celestial',1.0),('Voidborn',0.8),('Demon',0.8),('Angel',0.6),('Archangel',0.4),
      ('Demi-God',0.3),('God',0.2),('Dryad',1.8),('Golem',1.6),('Kitsune',1.2),
      ('Krakenborn',1.0),('Djinn',0.9),('Oni',0.8),('Phoenixborn',0.4),('Targaryen',0.7)
    ) v(name,weight)
    where private.genesis_race_allowed(v.name,p_stars)
  loop total := total + rec.weight; end loop;

  r := private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|RACE_GATE_V155'),1)*total;

  for rec in
    select * from (values
      ('Human',20.0),('Elf',6.7),('Orc',5.7),('Dwarf',5.2),('Beastkin',4.8),('Slime',4.0),
      ('Pale Orc',3.5),('Reptilian',3.5),('Dark Elf',3.0),('Minotaur',3.0),('Centaur',3.0),
      ('Leonin',3.0),('Imp',2.5),('Shadow',2.5),('Harpy',2.5),('Merfolk',2.5),('Fairy',2.2),
      ('Spiritborn',2.2),('Ghoul',2.2),('Ghost',2.2),('Undead',2.2),('Dragonkin',2.0),
      ('Vampire',1.8),('Ancient Egyptian',1.8),('Fallen Angel',1.5),('Lich',1.2),('Asgardian',1.2),
      ('Celestial',1.0),('Voidborn',0.8),('Demon',0.8),('Angel',0.6),('Archangel',0.4),
      ('Demi-God',0.3),('God',0.2),('Dryad',1.8),('Golem',1.6),('Kitsune',1.2),
      ('Krakenborn',1.0),('Djinn',0.9),('Oni',0.8),('Phoenixborn',0.4),('Targaryen',0.7)
    ) v(name,weight)
    where private.genesis_race_allowed(v.name,p_stars)
  loop
    acc := acc + rec.weight;
    if r <= acc then return rec.name; end if;
  end loop;
  return 'Human';
end
$$;

create or replace function private.genesis_race_probability(p_race text,p_stars integer)
returns double precision
language plpgsql immutable set search_path=''
as $$
declare total double precision:=0; w double precision:=0; rec record;
begin
  for rec in
    select * from (values
      ('Human',20.0),('Elf',6.7),('Orc',5.7),('Dwarf',5.2),('Beastkin',4.8),('Slime',4.0),
      ('Pale Orc',3.5),('Reptilian',3.5),('Dark Elf',3.0),('Minotaur',3.0),('Centaur',3.0),
      ('Leonin',3.0),('Imp',2.5),('Shadow',2.5),('Harpy',2.5),('Merfolk',2.5),('Fairy',2.2),
      ('Spiritborn',2.2),('Ghoul',2.2),('Ghost',2.2),('Undead',2.2),('Dragonkin',2.0),
      ('Vampire',1.8),('Ancient Egyptian',1.8),('Fallen Angel',1.5),('Lich',1.2),('Asgardian',1.2),
      ('Celestial',1.0),('Voidborn',0.8),('Demon',0.8),('Angel',0.6),('Archangel',0.4),
      ('Demi-God',0.3),('God',0.2),('Dryad',1.8),('Golem',1.6),('Kitsune',1.2),
      ('Krakenborn',1.0),('Djinn',0.9),('Oni',0.8),('Phoenixborn',0.4),('Targaryen',0.7)
    ) v(name,weight)
    where private.genesis_race_allowed(v.name,p_stars)
  loop
    total:=total+rec.weight;
    if rec.name=p_race then w:=rec.weight; end if;
  end loop;
  return case when total>0 then w/total*100.0 else 0 end;
end
$$;

create or replace function private.genesis_server_class(p_seed text)
returns text
language plpgsql immutable set search_path=''
as $$
declare
  arr text[]:=array['Knight','Paladin','Mage','Ranger','Assassin','Berserker','Priest','Necromancer','Samurai','Monk','Warlock','Druid','Spellblade','Gunslinger','Summoner','Dragon Knight','Shadow Knight','Battle Sage','Arcane Duelist','Soul Reaper','Chronomancer','Void Walker','Holy Executioner','Demon Hunter'];
  idx integer;
begin
  idx:=floor(private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|CLASS_V163'),1)*array_length(arr,1))::integer+1;
  return arr[idx];
end
$$;

create or replace function private.genesis_server_trait(p_seed text)
returns text
language plpgsql immutable set search_path=''
as $$
declare
  arr text[]:=array['Six-Winged Awakening','Dragon Blood','Immortal Core','Mana Overdrive','Second Soul','Void Heart','Sacred Mark','Demonic Eye','Phoenix Crest','Astral Body','Moon Blessing','Cursed Bloodline','Runic Skin','Time Sense','Predator Instinct','World Tree Pact','Unbreakable Will','Nine-Tail Blessing','Worldroot Heart','Living Core','Wishbound Sigil','Oni Crest','Eternal Ember','Leviathan Blood'];
  idx integer;
begin
  idx:=floor(private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|TRAIT_V163'),1)*array_length(arr,1))::integer+1;
  return arr[idx];
end
$$;

create or replace function private.genesis_server_weapon(p_seed text)
returns text
language plpgsql immutable set search_path=''
as $$
declare
  arr text[]:=array[
    'Longsword','Greatsword','Twin Blades','Spear','Halberd','Katana','Scythe','Warhammer','Bow',
    'Arcane Staff','Spellbook','Gauntlets','Dual Pistols','Chain Blade','Dragon Lance','Sacred Relic','Cursed Blade','Crystal Wand',
    'Sunblade Khopesh','Pharaoh Scepter','Relic Spear','Titan Axe','Runic Hammer','Ceremonial Glaive','Obsidian Dagger','Ancient Totem',
    'Void Grimoire','Astral Orb','Soul Lantern','Elemental Tome','Celestial Staff','Chrono Blade','Arcane Chakram','Rune Cannon','Hex Sigil',
    'Magitek Rifle','Hextech Revolver','Combat Shotgun','Twin SMGs','Rail Lance','Energy Saber','Tactical Crossbow','Pulse Cannon','Modern Battle Staff',
    'Foxfire Fan','Worldroot Staff','Runic Golem Fist','Djinn Lampblade','Oni Kanabo','Phoenix Spear','Leviathan Trident'
  ];
  idx integer;
begin
  idx:=floor(private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|WEAPON_NAME_V163'),1)*array_length(arr,1))::integer+1;
  return arr[idx];
end
$$;

create or replace function private.genesis_weighted_rarity_stars(p_roll double precision,p_kind text)
returns integer
language plpgsql immutable set search_path=''
as $$
declare r double precision:=p_roll*100.0;
begin
  if p_kind='weapon' then
    if r<34 then return 1; elsif r<58 then return 2; elsif r<74 then return 3; elsif r<84 then return 4;
    elsif r<91 then return 5; elsif r<95 then return 6; elsif r<97.5 then return 7; elsif r<99 then return 8;
    elsif r<99.8 then return 9; else return 10; end if;
  else
    if r<36 then return 1; elsif r<61 then return 2; elsif r<77 then return 3; elsif r<87 then return 4;
    elsif r<93 then return 5; elsif r<96.5 then return 6; elsif r<98.3 then return 7; elsif r<99.3 then return 8;
    elsif r<99.9 then return 9; else return 10; end if;
  end if;
end
$$;

create or replace function private.genesis_weapon_category(p_name text)
returns text
language sql immutable set search_path=''
as $$
select case
  when p_name in ('Sunblade Khopesh','Pharaoh Scepter','Relic Spear','Titan Axe','Runic Hammer','Ceremonial Glaive','Obsidian Dagger','Ancient Totem') then 'Ancient Weapon'
  when p_name in ('Arcane Staff','Spellbook','Dragon Lance','Sacred Relic','Cursed Blade','Crystal Wand','Void Grimoire','Astral Orb','Soul Lantern','Elemental Tome','Celestial Staff','Chrono Blade','Arcane Chakram','Rune Cannon','Hex Sigil') then 'Magic Weapon'
  when p_name in ('Dual Pistols','Magitek Rifle','Hextech Revolver','Combat Shotgun','Twin SMGs','Rail Lance','Energy Saber','Tactical Crossbow','Pulse Cannon','Modern Battle Staff') then 'Modern Weapon'
  else 'Traditional Weapon' end
$$;

create or replace function private.genesis_weapon_power(p_seed text,p_weapon text,p_stars integer)
returns integer
language plpgsql immutable set search_path=''
as $$
declare
  base integer:=case p_stars when 1 then 120 when 2 then 180 when 3 then 260 when 4 then 360 when 5 then 480 when 6 then 620 when 7 then 800 when 8 then 1050 when 9 then 1400 else 1900 end;
  spread integer:=case p_stars when 1 then 70 when 2 then 90 when 3 then 120 when 4 then 150 when 5 then 190 when 6 then 240 when 7 then 300 when 8 then 380 when 9 then 480 else 650 end;
  bonus integer;
  roll double precision;
begin
  bonus:=case private.genesis_weapon_category(p_weapon) when 'Ancient Weapon' then 85 when 'Magic Weapon' then 75 when 'Modern Weapon' then 65 else 30 end;
  roll:=private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|WEAPON'),2);
  return round(base+roll*spread+bonus)::integer;
end
$$;

create or replace function private.genesis_equipment_name(p_seed text,p_slot text)
returns text
language plpgsql immutable set search_path=''
as $$
declare arr text[]; idx integer; label text:=upper(p_slot);
begin
  if label='ARMOR' then arr:=array['Iron Vanguard Plate','Runebound Armor','Dragonbone Mail','Voidweave Robe','Seraphic Plate','Crimson Warlord Armor','Moonveil Garment','Titanhide Cuirass','Aether Knight Coat','Pharaoh Warplate','Living Slime Armor','Astral Guardian Mail','Shadowstalker Mantle','Stormforged Plate'];
  elsif label='ACCESSORY' then arr:=array['Moonstone Ring','Phoenix Pendant','Eye of the Oracle','Dragonfang Necklace','Voidglass Ring','Golden Scarab Charm','Bifrost Bracelet','Blood Ruby Brooch','World Tree Amulet','Chrono Pocketwatch','Lionheart Talisman','Arcane Earring','Soulbound Rosary','Celestial Signet'];
  elsif label='RELIC' then arr:=array['Fragment of the First Heaven','Ancient Dragon Heart','Pharaoh''s Eternal Seal','Ashes of the Phoenix','Frozen Tear of Valhalla','Black Sun Fragment','Saint''s Last Prayer','World Tree Seedling','Eye of Eternity','Bone Crown Shard','Abyssal Compass','Tablet of Forgotten Names'];
  elsif label='ARTIFACT' then arr:=array['World Seed','Chrono Heart','Crown of the Abyss','Orb of Infinite Stars','Genesis Crystal','Mirror of Lost Souls','Eclipse Engine','Divine Law Tablet','Primordial Ember','Void Keystone','Astral Throne Fragment','Book of Unwritten Fate'];
  else raise exception 'INVALID_EQUIPMENT_SLOT';
  end if;
  idx:=floor(private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|EQUIP|'||label),2)*array_length(arr,1))::integer+1;
  return arr[idx];
end
$$;

create or replace function private.genesis_equipment_power(p_seed text,p_slot text,p_stars integer)
returns integer
language plpgsql immutable set search_path=''
as $$
declare
  base integer:=case p_stars when 1 then 45 when 2 then 70 when 3 then 105 when 4 then 150 when 5 then 210 when 6 then 285 when 7 then 380 when 8 then 510 when 9 then 700 else 980 end;
  spread integer:=case p_stars when 1 then 30 when 2 then 40 when 3 then 55 when 4 then 75 when 5 then 100 when 6 then 130 when 7 then 170 when 8 then 220 when 9 then 300 else 420 end;
  roll double precision;
begin
  roll:=private.genesis_mulberry32_at(private.genesis_fnv1a32(p_seed||'|EQUIP|'||upper(p_slot)),4);
  return round(base+roll*spread)::integer;
end
$$;

create or replace function private.genesis_hidden_result(p_seed text,p_race text,p_class text,p_rarity text)
returns jsonb
language plpgsql immutable set search_path=''
as $$
declare
  c double precision:=case p_rarity when 'Rare' then .003 when 'Special Rare' then .008 when 'Super Rare' then .015 when 'Super Special Rare' then .025 when 'Epic' then .05 when 'Legendary' then .10 when 'Mythical' then .22 when 'Primordial' then .45 else 0 end;
  seed_u bigint:=private.genesis_fnv1a32(p_seed||'|HIDDEN_V163');
  idx integer:=1;
  roll double precision;
  race_options text[];
  secret text[]:=array['Reality Breaker','Eternal Vanguard','World Weaver','Seraph Warlord','Divine Arbiter','Abyss Sovereign','Void Monarch','Dragon Emperor','Wyrm Godslayer','Deathlord','Crypt Sovereign','Primal Overlord','Wild King','Grand Arcanist','Sacred Champion','Relic Overlord','Mythic Gunslinger','Ancient Weapon Master'];
  hidden_race_name text:=null;
  hidden_class_name text:=null;
  do_secret boolean:=false;
begin
  roll:=private.genesis_mulberry32_at(seed_u,idx); idx:=idx+1;
  if roll>=c then return jsonb_build_object('hidden_race',false,'hidden_class',false,'hidden_race_name',null,'hidden_class_name',null); end if;

  race_options:=case p_race
    when 'Angel' then array['High Seraph','Nephilim'] when 'Archangel' then array['Throneseraph','Heaven''s Spear']
    when 'Demon' then array['Archdemon','Infernal Sovereign'] when 'Dragonkin' then array['Primordial Dragon','Dragon Ascendant']
    when 'Voidborn' then array['Eldritch Born','Outer Void Entity'] when 'Celestial' then array['Godborn','Astral Deity']
    when 'Vampire' then array['Blood Progenitor','Crimson Ancestor'] when 'Elf' then array['High Fae','World Tree Scion']
    when 'Dark Elf' then array['Abyssal Fae','Night Sovereign'] when 'Spiritborn' then array['Ancient Spirit','Astral Incarnate']
    when 'Minotaur' then array['Labyrinth Lord','Horned Titan'] when 'Imp' then array['Infernal Trickster','Hellfire Imp King']
    when 'Shadow' then array['Night Incarnate','Eclipse Phantom'] when 'Centaur' then array['Starhoof Champion','Ancient Plains Lord']
    when 'Ghoul' then array['Grave Devourer','Carrion King'] when 'Ghost' then array['Spectral Monarch','Wailing Apparition']
    when 'Undead' then array['Deathless Sovereign','Bone Tyrant'] when 'Lich' then array['Archlich','Crypt Emperor']
    when 'Harpy' then array['Storm Harbinger','Sky Queen'] when 'Merfolk' then array['Tide Oracle','Abyssal Mariner']
    when 'Pale Orc' then array['Frostfang Warlord','Bonecrusher King'] when 'Leonin' then array['Sunmane Sovereign','Golden Pride King']
    when 'Slime' then array['Primordial Slime','Abyssal Gel Monarch'] when 'Reptilian' then array['Scaled Tyrant','Basilisk Descendant']
    when 'Asgardian' then array['Odinblood Heir','Bifrost Champion'] when 'Ancient Egyptian' then array['Pharaoh Eternal','Anubian Oracle']
    when 'God' then array['Creator Aspect','Divine Origin'] when 'Demi-God' then array['Ascended Scion','Heaven-Touched Hero']
    when 'Targaryen' then array['Dragonlord Ascendant','Blood of Old Valyria'] when 'Dryad' then array['Elder Dryad','Worldroot Avatar']
    when 'Golem' then array['Colossus Golem','Genesis Construct'] when 'Kitsune' then array['Nine-Tailed Kitsune','Moonfire Fox Spirit']
    when 'Krakenborn' then array['Leviathan Scion','Abyssal Kraken Lord'] when 'Djinn' then array['Ifrit Sovereign','Wishbound Monarch']
    when 'Oni' then array['Crimson Oni Lord','Thunder Oni'] when 'Phoenixborn' then array['Eternal Phoenix','Solar Rebirth Avatar']
    else null end;

  if race_options is not null then
    roll:=private.genesis_mulberry32_at(seed_u,idx); idx:=idx+1;
    if roll<.72 then
      roll:=private.genesis_mulberry32_at(seed_u,idx); idx:=idx+1;
      hidden_race_name:=race_options[floor(roll*array_length(race_options,1))::integer+1];
    end if;
  end if;

  roll:=private.genesis_mulberry32_at(seed_u,idx); idx:=idx+1;
  do_secret:=roll<.64 or p_rarity='Primordial';
  if do_secret then
    roll:=private.genesis_mulberry32_at(seed_u,idx);
    hidden_class_name:=secret[floor(roll*array_length(secret,1))::integer+1];
  end if;

  return jsonb_build_object(
    'hidden_race',hidden_race_name is not null,
    'hidden_class',hidden_class_name is not null,
    'hidden_race_name',hidden_race_name,
    'hidden_class_name',hidden_class_name
  );
end
$$;

create or replace function private.genesis_race_stat_bonus(p_race text,p_stat text)
returns integer
language sql immutable set search_path=''
as $$
select case p_race||'|'||p_stat
 when 'Orc|STR' then 15 when 'Orc|VIT' then 10 when 'Orc|INT' then -6
 when 'Pale Orc|STR' then 13 when 'Pale Orc|VIT' then 11 when 'Pale Orc|INT' then -4 when 'Pale Orc|DEF' then 4
 when 'Dwarf|DEF' then 14 when 'Dwarf|VIT' then 12 when 'Dwarf|AGI' then -8
 when 'Minotaur|STR' then 18 when 'Minotaur|VIT' then 12 when 'Minotaur|AGI' then -5
 when 'Centaur|STR' then 10 when 'Centaur|AGI' then 10 when 'Centaur|VIT' then 8
 when 'Leonin|STR' then 9 when 'Leonin|AGI' then 8 when 'Leonin|VIT' then 6 when 'Leonin|LCK' then 4
 when 'Slime|VIT' then 16 when 'Slime|DEF' then 6 when 'Slime|STR' then -5 when 'Slime|AGI' then -3
 when 'Reptilian|AGI' then 9 when 'Reptilian|DEF' then 5 when 'Reptilian|VIT' then 6
 when 'Lich|INT' then 18 when 'Lich|LCK' then 8 when 'Lich|STR' then -8
 when 'Ghost|INT' then 12 when 'Ghost|AGI' then 7 when 'Ghost|DEF' then -10
 when 'Undead|VIT' then 14 when 'Undead|DEF' then 7 when 'Undead|AGI' then -4
 when 'Harpy|AGI' then 13 when 'Harpy|LCK' then 6
 when 'Dragonkin|STR' then 12 when 'Dragonkin|DEF' then 9 when 'Dragonkin|VIT' then 10
 when 'Angel|INT' then 10 when 'Angel|AGI' then 5 when 'Angel|LCK' then 6
 when 'Archangel|INT' then 15 when 'Archangel|AGI' then 8 when 'Archangel|LCK' then 12 when 'Archangel|DEF' then 5
 when 'Elf|AGI' then 10 when 'Elf|INT' then 8 when 'Elf|DEF' then -4
 when 'Demon|STR' then 12 when 'Demon|INT' then 6
 when 'Vampire|AGI' then 8 when 'Vampire|INT' then 6 when 'Vampire|LCK' then 5
 when 'Voidborn|INT' then 13 when 'Voidborn|LCK' then 8
 when 'Asgardian|STR' then 10 when 'Asgardian|INT' then 10 when 'Asgardian|VIT' then 8 when 'Asgardian|LCK' then 6
 when 'Ancient Egyptian|INT' then 9 when 'Ancient Egyptian|LCK' then 8 when 'Ancient Egyptian|AGI' then 4
 when 'God|STR' then 10 when 'God|AGI' then 6 when 'God|INT' then 16 when 'God|VIT' then 10 when 'God|LCK' then 12
 when 'Demi-God|STR' then 12 when 'Demi-God|AGI' then 8 when 'Demi-God|INT' then 8 when 'Demi-God|LCK' then 6
 else 0 end
$$;

create or replace function private.genesis_class_stat_bonus(p_class text,p_stat text)
returns integer
language sql immutable set search_path=''
as $$
select case p_class||'|'||p_stat
 when 'Knight|STR' then 8 when 'Knight|DEF' then 10 when 'Knight|VIT' then 6
 when 'Paladin|STR' then 6 when 'Paladin|DEF' then 8 when 'Paladin|VIT' then 8 when 'Paladin|INT' then 4
 when 'Mage|INT' then 16 when 'Mage|DEF' then -5
 when 'Ranger|AGI' then 12 when 'Ranger|LCK' then 5
 when 'Assassin|AGI' then 16 when 'Assassin|LCK' then 7 when 'Assassin|DEF' then -7
 when 'Berserker|STR' then 18 when 'Berserker|VIT' then 8
 when 'Priest|INT' then 12 when 'Priest|VIT' then 5
 when 'Necromancer|INT' then 15 when 'Necromancer|LCK' then 4 when 'Necromancer|DEF' then -5
 when 'Chronomancer|INT' then 16 when 'Chronomancer|AGI' then 7 when 'Chronomancer|LCK' then 5
 when 'Dragon Knight|STR' then 12 when 'Dragon Knight|DEF' then 8 when 'Dragon Knight|VIT' then 7
 when 'Void Walker|INT' then 14 when 'Void Walker|AGI' then 7 when 'Void Walker|LCK' then 6
 else 0 end
$$;

create or replace function private.genesis_base_combat_power(
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
  race_bonus integer;
  hidden_bonus integer:=(case when p_hidden_race then 650 else 0 end)+(case when p_hidden_class then 650 else 0 end);
  trait_bonus integer:=case when p_trait in ('Immortal Core','Six-Winged Awakening','Void Heart','Dragon Blood') then 260 else 100 end;
begin
  foreach stat in array array['STR','AGI','INT','DEF','VIT','LCK'] loop
    val:=50+bonus+private.genesis_race_stat_bonus(p_race,stat)+private.genesis_class_stat_bonus(p_class,stat);
    val:=greatest(10,least(120,round(val)::integer));
    stat_total:=stat_total+val;
  end loop;
  race_bonus:=least(900,greatest(0,round((20-coalesce(p_race_chance,20))*40)::integer));
  return round(stat_total*12+rarity_bonus+p_weapon_power*1.4+p_equipment_power*1.15+race_bonus+hidden_bonus+trait_bonus)::integer;
end
$$;

create or replace function private.genesis_summoner_level_from_xp(p_xp bigint)
returns integer
language plpgsql immutable set search_path=''
as $$
declare level integer:=1; remaining bigint:=greatest(0,p_xp); need integer;
begin
  while level<100 loop
    need:=100+level*35;
    if remaining<need then return level; end if;
    remaining:=remaining-need;
    level:=level+1;
  end loop;
  return 100;
end
$$;

create or replace function private.genesis_achievement_rank(p_ap integer)
returns text
language sql immutable set search_path=''
as $$
select case
 when p_ap>=800 then 'Sovereign of Genesis'
 when p_ap>=550 then 'Mythic Chronicler'
 when p_ap>=350 then 'Legendary Archivist'
 when p_ap>=200 then 'Genesis Vanguard'
 when p_ap>=100 then 'Codex Adept'
 when p_ap>=50 then 'Fate Seeker'
 else 'Initiate' end
$$;

create or replace function private.genesis_race_family(p_race text)
returns text
language sql immutable set search_path=''
as $$
select case
 when p_race in ('Human','Dwarf','Orc','Pale Orc') then 'Mortal'
 when p_race in ('Elf','Dark Elf','Fairy','Dryad','Kitsune') then 'Fae'
 when p_race in ('Beastkin','Minotaur','Centaur','Leonin','Harpy','Merfolk','Reptilian','Krakenborn') then 'Beast'
 when p_race in ('Ghoul','Ghost','Undead','Lich','Vampire') then 'Undead'
 when p_race in ('Angel','Archangel','Fallen Angel','Celestial') then 'Celestial'
 when p_race in ('Imp','Demon','Oni') then 'Infernal'
 when p_race in ('God','Demi-God') then 'Divine'
 when p_race='Dragonkin' then 'Draconic'
 when p_race in ('Shadow','Voidborn') then 'Eldritch'
 when p_race in ('Asgardian','Ancient Egyptian') then 'Ancient'
 when p_race in ('Slime','Djinn','Phoenixborn') then 'Elemental'
 when p_race='Spiritborn' then 'Spirit'
 when p_race='Golem' then 'Construct'
 when p_race='Targaryen' then 'Special Bloodline'
 else 'Unknown' end
$$;

create or replace function private.genesis_codex_touch(
 p_uid uuid,p_type text,p_key text,p_rarity integer,p_power integer,p_when timestamptz
)
returns boolean
language plpgsql security definer set search_path=''
as $$
declare existed boolean;
begin
  select exists(
    select 1 from public.genesis_player_codex
    where user_id=p_uid and codex_type=p_type and entry_key=p_key
  ) into existed;

  insert into public.genesis_player_codex(
    user_id,codex_type,entry_key,first_discovered_at,last_obtained_at,times_obtained,best_rarity_stars,highest_power
  ) values(p_uid,p_type,p_key,p_when,p_when,1,p_rarity,greatest(0,coalesce(p_power,0)))
  on conflict(user_id,codex_type,entry_key) do update
    set last_obtained_at=excluded.last_obtained_at,
        times_obtained=public.genesis_player_codex.times_obtained+1,
        best_rarity_stars=greatest(coalesce(public.genesis_player_codex.best_rarity_stars,0),coalesce(excluded.best_rarity_stars,0)),
        highest_power=greatest(public.genesis_player_codex.highest_power,excluded.highest_power);

  return not existed;
end
$$;

-- ------------------------------------------------------------
-- Achievement catalog constants.
-- ------------------------------------------------------------
create or replace function private.genesis_achievement_reward(p_id text)
returns jsonb
language sql immutable set search_path=''
as $$
select case p_id
 when 'first_legendary' then jsonb_build_object('ap',10,'gp',0,'essence',30,'xp',0)
 when 'first_mythical' then jsonb_build_object('ap',20,'gp',10,'essence',50,'xp',0)
 when 'first_primordial' then jsonb_build_object('ap',50,'gp',25,'essence',100,'xp',0)
 when 'first_10x' then jsonb_build_object('ap',5,'gp',0,'essence',20,'xp',0)
 when 'summons_100' then jsonb_build_object('ap',10,'gp',10,'essence',40,'xp',0)
 when 'summons_500' then jsonb_build_object('ap',20,'gp',20,'essence',75,'xp',0)
 when 'summons_1000' then jsonb_build_object('ap',50,'gp',40,'essence',150,'xp',0)
 when 'legendary_10' then jsonb_build_object('ap',20,'gp',0,'essence',75,'xp',0)
 when 'mythical_5' then jsonb_build_object('ap',50,'gp',25,'essence',100,'xp',0)
 when 'race_10' then jsonb_build_object('ap',5,'gp',0,'essence',20,'xp',0)
 when 'race_25' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'all_races' then jsonb_build_object('ap',50,'gp',30,'essence',150,'xp',0)
 when 'family_mortal' then jsonb_build_object('ap',10,'gp',0,'essence',30,'xp',0)
 when 'family_fae' then jsonb_build_object('ap',10,'gp',0,'essence',30,'xp',0)
 when 'family_undead' then jsonb_build_object('ap',10,'gp',0,'essence',30,'xp',0)
 when 'all_families' then jsonb_build_object('ap',20,'gp',15,'essence',60,'xp',0)
 when 'all_rarities' then jsonb_build_object('ap',20,'gp',15,'essence',60,'xp',0)
 when 'hidden_form' then jsonb_build_object('ap',10,'gp',0,'essence',35,'xp',0)
 when 'collector_10' then jsonb_build_object('ap',5,'gp',0,'essence',20,'xp',0)
 when 'collector_25' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'collector_100' then jsonb_build_object('ap',20,'gp',20,'essence',75,'xp',0)
 when 'collection_legendary_10' then jsonb_build_object('ap',20,'gp',0,'essence',75,'xp',0)
 when 'collection_mythical_5' then jsonb_build_object('ap',50,'gp',25,'essence',100,'xp',0)
 when 'favorites_10' then jsonb_build_object('ap',10,'gp',0,'essence',35,'xp',0)
 when 'summoner_25' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'summoner_50' then jsonb_build_object('ap',20,'gp',15,'essence',75,'xp',0)
 when 'first_duplicate' then jsonb_build_object('ap',5,'gp',0,'essence',20,'xp',0)
 when 'first_awakened' then jsonb_build_object('ap',5,'gp',0,'essence',25,'xp',0)
 when 'first_ascended' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'first_transcendent' then jsonb_build_object('ap',20,'gp',15,'essence',75,'xp',0)
 when 'character_level_50' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'character_level_100' then jsonb_build_object('ap',20,'gp',15,'essence',75,'xp',0)
 when 'weapon_plus_10' then jsonb_build_object('ap',20,'gp',0,'essence',75,'xp',0)
 when 'all_gear_plus_10' then jsonb_build_object('ap',50,'gp',30,'essence',150,'xp',0)
 when 'essence_1000' then jsonb_build_object('ap',10,'gp',0,'essence',25,'xp',0)
 when 'power_12000' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'daily_10' then jsonb_build_object('ap',5,'gp',0,'essence',25,'xp',0)
 when 'daily_50' then jsonb_build_object('ap',10,'gp',10,'essence',50,'xp',0)
 when 'daily_100' then jsonb_build_object('ap',20,'gp',20,'essence',80,'xp',0)
 when 'perfect_daily' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'login_7' then jsonb_build_object('ap',10,'gp',10,'essence',40,'xp',0)
 when 'login_30' then jsonb_build_object('ap',20,'gp',20,'essence',80,'xp',0)
 when 'summon_god' then jsonb_build_object('ap',20,'gp',15,'essence',60,'xp',0)
 when 'summon_archangel' then jsonb_build_object('ap',10,'gp',0,'essence',40,'xp',0)
 when 'primordial_human' then jsonb_build_object('ap',50,'gp',30,'essence',150,'xp',0)
 when 'primordial_weapon' then jsonb_build_object('ap',50,'gp',25,'essence',120,'xp',0)
 when 'primordial_equipment' then jsonb_build_object('ap',50,'gp',25,'essence',120,'xp',0)
 else jsonb_build_object('ap',0,'gp',0,'essence',0,'xp',0) end
$$;

create or replace function private.genesis_achievement_met(p_uid uuid,p_id text)
returns boolean
language plpgsql stable security definer set search_path=''
as $$
declare
  n bigint; level_value integer; wallet_ess bigint;
begin
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

    when 'daily_10' then return (select count(*) from public.genesis_economy_ledger where user_id=p_uid and event_type like 'DAILY_MISSION_%')>=10;
    when 'daily_50' then return (select count(*) from public.genesis_economy_ledger where user_id=p_uid and event_type like 'DAILY_MISSION_%')>=50;
    when 'daily_100' then return (select count(*) from public.genesis_economy_ledger where user_id=p_uid and event_type like 'DAILY_MISSION_%')>=100;
    when 'perfect_daily' then return exists(select 1 from public.genesis_economy_ledger where user_id=p_uid and event_type='DAILY_COMPLETION_ALL');
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

create or replace function private.genesis_apply_summoner_xp(p_uid uuid,p_delta integer)
returns void
language plpgsql security definer set search_path=''
as $$
declare new_xp bigint; new_level integer;
begin
  if coalesce(p_delta,0)<=0 then return; end if;
  update public.genesis_profiles
  set summoner_xp=summoner_xp+p_delta,updated_at=now()
  where user_id=p_uid
  returning summoner_xp into new_xp;
  new_level:=private.genesis_summoner_level_from_xp(coalesce(new_xp,0));
  update public.genesis_profiles set summoner_level=new_level,updated_at=now() where user_id=p_uid;
end
$$;

-- ------------------------------------------------------------
-- Verified achievement sweep.
-- Rewards are minted exactly once due to PK(user_id,achievement_id).
-- ------------------------------------------------------------
create or replace function public.genesis_verify_achievements(p_request_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $$
declare
  uid uuid:=(select auth.uid());
  id text;
  reward jsonb;
  inserted integer;
  ap_gain integer:=0;
  gp_gain integer:=0;
  essence_gain integer:=0;
  xp_gain integer:=0;
  w public.genesis_wallets%rowtype;
  total_ap integer;
  response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;

  foreach id in array array[
    'first_legendary','first_mythical','first_primordial','first_10x','summons_100','summons_500','summons_1000','legendary_10','mythical_5',
    'race_10','race_25','all_races','family_mortal','family_fae','family_undead','all_families','all_rarities','hidden_form',
    'collector_10','collector_25','collector_100','collection_legendary_10','collection_mythical_5','favorites_10',
    'summoner_25','summoner_50','first_duplicate','first_awakened','first_ascended','first_transcendent','character_level_50','character_level_100',
    'weapon_plus_10','all_gear_plus_10','essence_1000','power_12000',
    'daily_10','daily_50','daily_100','perfect_daily','login_7','login_30',
    'summon_god','summon_archangel','primordial_human','primordial_weapon','primordial_equipment'
  ] loop
    if private.genesis_achievement_met(uid,id) then
      reward:=private.genesis_achievement_reward(id);
      insert into public.genesis_player_achievements(
        user_id,achievement_id,ap,reward_gp,reward_essence,reward_xp
      ) values(
        uid,id,(reward->>'ap')::integer,(reward->>'gp')::integer,(reward->>'essence')::integer,(reward->>'xp')::integer
      ) on conflict(user_id,achievement_id) do nothing;
      get diagnostics inserted=row_count;

      if inserted=1 then
        ap_gain:=ap_gain+(reward->>'ap')::integer;
        gp_gain:=gp_gain+(reward->>'gp')::integer;
        essence_gain:=essence_gain+(reward->>'essence')::integer;
        xp_gain:=xp_gain+(reward->>'xp')::integer;
      end if;
    end if;
  end loop;

  if gp_gain>0 or essence_gain>0 then
    w.gp:=w.gp+gp_gain;
    w.essence:=w.essence+essence_gain;
    update public.genesis_wallets set gp=w.gp,essence=w.essence,updated_at=now() where user_id=uid;
    insert into public.genesis_economy_ledger(
      user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata
    ) values(
      uid,coalesce(nullif(p_request_key,''),'ACH-'||gen_random_uuid()::text),'ACHIEVEMENT_REWARDS',
      gp_gain,essence_gain,w.gp,w.essence,jsonb_build_object('new_ap',ap_gain)
    );
  end if;

  if xp_gain>0 then perform private.genesis_apply_summoner_xp(uid,xp_gain); end if;

  select coalesce(sum(ap),0)::integer into total_ap from public.genesis_player_achievements where user_id=uid;
  update public.genesis_profiles
  set achievement_points=total_ap,achievement_rank=private.genesis_achievement_rank(total_ap),updated_at=now()
  where user_id=uid;

  response:=jsonb_build_object(
    'new_ap',ap_gain,'gp_rewarded',gp_gain,'essence_rewarded',essence_gain,'xp_rewarded',xp_gain,
    'total_ap',total_ap,'rank',private.genesis_achievement_rank(total_ap)
  );
  return response;
end
$$;

-- ------------------------------------------------------------
-- Meta snapshot + progress values.
-- ------------------------------------------------------------
create or replace function public.genesis_meta_snapshot()
returns jsonb
language plpgsql security definer stable set search_path=''
as $$
declare
  uid uuid:=(select auth.uid());
  codex_json jsonb;
  achievement_json jsonb;
  profile_json jsonb;
  wallet_json jsonb;
  stats_json jsonb;
  progress_json jsonb;
  total_summons bigint;
  ten_pulls bigint;
  daily_claims bigint;
  perfect_days bigint;
  primordial_count bigint;
  mythical_count bigint;
  god_count bigint;
  primordial_weapon_count bigint;
  race_counts jsonb;
  rarity_counts jsonb;
  highest_cp integer:=0;
  best_character_id text:=null;
  best_character_name text:=null;
  highest_weapon_power integer:=0;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.codex_type,x.entry_key),'[]'::jsonb)
  into codex_json from (
    select codex_type,entry_key,first_discovered_at,last_obtained_at,times_obtained,best_rarity_stars,highest_power
    from public.genesis_player_codex where user_id=uid
  ) x;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.unlocked_at),'[]'::jsonb)
  into achievement_json from (
    select achievement_id,ap,reward_gp,reward_essence,reward_xp,unlocked_at
    from public.genesis_player_achievements where user_id=uid
  ) x;

  select jsonb_build_object(
    'summoner_xp',summoner_xp,'summoner_level',summoner_level,
    'achievement_points',achievement_points,'achievement_rank',achievement_rank
  ) into profile_json
  from public.genesis_profiles where user_id=uid;

  select jsonb_build_object('gp',gp,'essence',essence,'pity_count',pity_count)
  into wallet_json from public.genesis_wallets where user_id=uid;

  select count(*) into total_summons from public.genesis_characters where user_id=uid;
  select count(*) into ten_pulls from public.genesis_summon_sessions where user_id=uid and summon_count=10;
  select count(*) into daily_claims from public.genesis_economy_ledger where user_id=uid and event_type like 'DAILY_MISSION_%';
  select count(*) into perfect_days from public.genesis_economy_ledger where user_id=uid and event_type='DAILY_COMPLETION_ALL';
  select count(*) into primordial_count from public.genesis_characters where user_id=uid and rarity_stars=10;
  select count(*) into mythical_count from public.genesis_characters where user_id=uid and rarity_stars>=9;
  select count(*) into god_count from public.genesis_character_facts where user_id=uid and base_race='God';
  select count(*) into primordial_weapon_count from public.genesis_character_facts where user_id=uid and weapon_rarity_stars=10;

  select coalesce(jsonb_object_agg(rarity_name,cnt),'{}'::jsonb) into rarity_counts
  from (select rarity_name,count(*) cnt from public.genesis_characters where user_id=uid group by rarity_name) q;

  select coalesce(jsonb_object_agg(base_race,cnt),'{}'::jsonb) into race_counts
  from (select base_race,count(*) cnt from public.genesis_character_facts where user_id=uid group by base_race) q;

  select coalesce(f.base_combat_power,0),c.character_id,coalesce(nullif(c.custom_name,''),'UNNAMED HERO')
  into highest_cp,best_character_id,best_character_name
  from public.genesis_character_facts f
  join public.genesis_characters c on c.registry_id=f.registry_id
  where f.user_id=uid
  order by f.base_combat_power desc,c.created_at asc
  limit 1;

  select coalesce(max(weapon_power),0) into highest_weapon_power
  from public.genesis_character_facts where user_id=uid;

  stats_json:=jsonb_build_object(
    'total_summons',total_summons,'ten_pulls',ten_pulls,'primordial_count',primordial_count,
    'mythical_count',mythical_count,'god_count',god_count,'primordial_weapon_count',primordial_weapon_count,
    'daily_mission_claims',daily_claims,'perfect_daily_days',perfect_days,
    'full_login_cycles',coalesce((select full_cycles from public.genesis_login_server where user_id=uid),0),
    'highest_combat_power',coalesce(highest_cp,0),
    'best_character_id',best_character_id,
    'best_character_name',best_character_name,
    'highest_weapon_power',coalesce(highest_weapon_power,0),
    'rarity_counts',rarity_counts,'race_counts',race_counts
  );

  progress_json:=jsonb_build_object(
    'summons_100',jsonb_build_array(total_summons,100),'summons_500',jsonb_build_array(total_summons,500),'summons_1000',jsonb_build_array(total_summons,1000),
    'legendary_10',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and rarity_stars>=8),10),
    'mythical_5',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and rarity_stars>=9),5),
    'race_10',jsonb_build_array((select count(*) from public.genesis_player_codex where user_id=uid and codex_type='race'),10),
    'race_25',jsonb_build_array((select count(*) from public.genesis_player_codex where user_id=uid and codex_type='race'),25),
    'all_races',jsonb_build_array((select count(*) from public.genesis_player_codex where user_id=uid and codex_type='race'),42),
    'all_rarities',jsonb_build_array((select count(*) from public.genesis_player_codex where user_id=uid and codex_type='rarity'),10),
    'collector_10',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and archived=false),10),
    'collector_25',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and archived=false),25),
    'collector_100',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and archived=false),100),
    'collection_legendary_10',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and archived=false and rarity_stars>=8),10),
    'collection_mythical_5',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and archived=false and rarity_stars>=9),5),
    'favorites_10',jsonb_build_array((select count(*) from public.genesis_characters where user_id=uid and archived=false and favorite),10),
    'summoner_25',jsonb_build_array(coalesce((select summoner_level from public.genesis_profiles where user_id=uid),1),25),
    'summoner_50',jsonb_build_array(coalesce((select summoner_level from public.genesis_profiles where user_id=uid),1),50),
    'character_level_50',jsonb_build_array(coalesce((select max(character_level) from public.genesis_characters where user_id=uid),1),50),
    'character_level_100',jsonb_build_array(coalesce((select max(character_level) from public.genesis_characters where user_id=uid),1),100),
    'first_awakened',jsonb_build_array(coalesce((select max(evolution_stage) from public.genesis_characters where user_id=uid),0),1),
    'first_ascended',jsonb_build_array(coalesce((select max(evolution_stage) from public.genesis_characters where user_id=uid),0),2),
    'first_transcendent',jsonb_build_array(coalesce((select max(evolution_stage) from public.genesis_characters where user_id=uid),0),3),
    'essence_1000',jsonb_build_array(coalesce((select essence from public.genesis_wallets where user_id=uid),0),1000),
    'daily_10',jsonb_build_array(daily_claims,10),'daily_50',jsonb_build_array(daily_claims,50),'daily_100',jsonb_build_array(daily_claims,100),
    'perfect_daily',jsonb_build_array(perfect_days,1),
    'login_7',jsonb_build_array(coalesce((select full_cycles from public.genesis_login_server where user_id=uid),0),1),
    'login_30',jsonb_build_array(coalesce((select total_claims from public.genesis_login_server where user_id=uid),0),30)
  );

  return jsonb_build_object(
    'codex',codex_json,'achievements',achievement_json,'achievement_progress',progress_json,
    'profile',profile_json,'wallet',wallet_json,'stats',stats_json
  );
end
$$;

-- ------------------------------------------------------------
-- Replace summon RPC: G163 + verified facts + Codex + Summoner XP.
-- ------------------------------------------------------------
create or replace function public.genesis_online_summon(
  p_count integer,p_pity_enabled boolean,p_request_key text
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
  cost integer:=case when p_count=10 then 120 else 0 end;
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
  if p_count not in (1,10) then raise exception 'INVALID_SUMMON_COUNT'; end if;
  if p_request_key is null or char_length(p_request_key)<8 or char_length(p_request_key)>160 then raise exception 'INVALID_REQUEST_KEY'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text||'|genesis_online_summon|'||p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_online_summon' and request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  if w.gp<cost then raise exception 'INSUFFICIENT_GP'; end if;

  insert into public.genesis_summon_sessions(id,user_id,request_key,summon_count,gp_cost,gp_earned)
  values(session_id,uid,p_request_key,p_count,cost,0);

  if cost>0 then
    w.gp:=w.gp-cost;
    insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
    values(uid,p_request_key,'TEN_PULL_COST',-cost,0,w.gp,w.essence,jsonb_build_object('count',p_count,'summon_session_id',session_id));
  end if;

  insert into public.genesis_daily_server(user_id,date_key) values(uid,today) on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;

  for i in 1..p_count loop
    stars:=private.genesis_roll_selected_stars(w.pity_count,p_pity_enabled);
    rarity:=private.genesis_rarity_name(stars);
    reward:=private.genesis_gp_reward(stars);
    earned:=earned+reward;
    if stars>=8 then w.pity_count:=0; else w.pity_count:=least(60,w.pity_count+1); end if;
    w.gp:=w.gp+reward;

    seed:='G163-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12))||'-'||lpad(i::text,2,'0');
    cid:=private.genesis_character_id_from_seed(seed);
    race_name:=private.genesis_server_race(seed,stars);
    class_name:=private.genesis_server_class(seed);
    trait_name:=private.genesis_server_trait(seed);
    hidden:=private.genesis_hidden_result(seed,race_name,class_name,rarity);
    weapon_name:=private.genesis_server_weapon(seed);

    weapon_stars:=private.genesis_weighted_rarity_stars(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|WEAPON'),1),'weapon');
    weapon_power:=private.genesis_weapon_power(seed,weapon_name,weapon_stars);

    armor_stars:=private.genesis_weighted_rarity_stars(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|ARMOR'),1),'equipment');
    accessory_stars:=private.genesis_weighted_rarity_stars(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|ACCESSORY'),1),'equipment');
    relic_stars:=private.genesis_weighted_rarity_stars(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|RELIC'),1),'equipment');
    artifact_stars:=private.genesis_weighted_rarity_stars(private.genesis_mulberry32_at(private.genesis_fnv1a32(seed||'|EQUIP|ARTIFACT'),1),'equipment');

    armor_name:=private.genesis_equipment_name(seed,'ARMOR');
    accessory_name:=private.genesis_equipment_name(seed,'ACCESSORY');
    relic_name:=private.genesis_equipment_name(seed,'RELIC');
    artifact_name:=private.genesis_equipment_name(seed,'ARTIFACT');

    armor_power:=private.genesis_equipment_power(seed,'ARMOR',armor_stars);
    accessory_power:=private.genesis_equipment_power(seed,'ACCESSORY',accessory_stars);
    relic_power:=private.genesis_equipment_power(seed,'RELIC',relic_stars);
    artifact_power:=private.genesis_equipment_power(seed,'ARTIFACT',artifact_stars);
    equip_power:=armor_power+accessory_power+relic_power+artifact_power;
    race_chance:=private.genesis_race_probability(race_name,stars);

    cp:=private.genesis_base_combat_power(
      race_name,class_name,stars,race_chance,
      coalesce((hidden->>'hidden_race')::boolean,false),coalesce((hidden->>'hidden_class')::boolean,false),
      trait_name,weapon_power,equip_power
    );

    insert into public.genesis_characters(
      user_id,summon_session_id,character_id,seed,rarity_name,rarity_stars,gp_reward,summon_index
    ) values(uid,session_id,cid,seed,rarity,stars,reward,i)
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

  update public.genesis_wallets set gp=w.gp,essence=w.essence,pity_count=w.pity_count,updated_at=now() where user_id=uid;
  update public.genesis_daily_server set progress=d.progress,updated_at=now() where user_id=uid and date_key=today;
  update public.genesis_summon_sessions set gp_earned=earned where id=session_id and user_id=uid;

  response:=jsonb_build_object(
    'session_id',session_id,'results',results,'cost',cost,'earned_gp',earned,'server_date',today,'reset_at',reset_at,
    'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count),
    'daily',jsonb_build_object('mission_ids',to_jsonb(private.genesis_daily_ids(today)),'progress',d.progress,'claimed',d.claimed,'completion_three',d.completion_three,'completion_all',d.completion_all)
  );

  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response)
  values(uid,'genesis_online_summon',p_request_key,response);

  return response;
end
$$;

-- Fix invalid PL/pgSQL syntax above for discovery checks by using a helper query-safe wrapper.
-- Replace codex_touch with a version whose boolean accurately signals first discovery.



-- ------------------------------------------------------------
-- V16.3C Daily/Login functions: persist Summoner XP on the server.
-- ------------------------------------------------------------

create or replace function public.genesis_claim_daily_mission(
  p_mission_id text,p_request_key text
)
returns jsonb
language plpgsql security definer set search_path=''
as $$
declare
  uid uuid:=(select auth.uid()); existing jsonb; w public.genesis_wallets%rowtype; d public.genesis_daily_server%rowtype;
  today date:=(now() at time zone 'UTC')::date; ids text[]:=private.genesis_daily_ids(today);
  metric text; target integer; value integer; reward jsonb; gp_delta integer; essence_delta integer; xp_delta integer; response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if not (p_mission_id=any(ids)) then raise exception 'MISSION_NOT_ACTIVE_TODAY'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text||'|daily|'||p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_claim_daily_mission' and request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  insert into public.genesis_daily_server(user_id,date_key) values(uid,today) on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;

  if coalesce((d.claimed->>p_mission_id)::boolean,false) then raise exception 'MISSION_ALREADY_CLAIMED'; end if;
  metric:=private.genesis_daily_metric(p_mission_id); target:=private.genesis_daily_target(p_mission_id);
  value:=coalesce((d.progress->>metric)::integer,0);
  if value<target then raise exception 'MISSION_NOT_COMPLETE'; end if;

  reward:=private.genesis_daily_reward(p_mission_id);
  gp_delta:=coalesce((reward->>'gp')::integer,0); essence_delta:=coalesce((reward->>'essence')::integer,0); xp_delta:=coalesce((reward->>'xp')::integer,0);
  w.gp:=w.gp+gp_delta; w.essence:=w.essence+essence_delta;
  d.claimed:=jsonb_set(d.claimed,array[p_mission_id],'true'::jsonb,true);

  update public.genesis_wallets set gp=w.gp,essence=w.essence,updated_at=now() where user_id=uid;
  update public.genesis_daily_server set claimed=d.claimed,updated_at=now() where user_id=uid and date_key=today;
  perform private.genesis_apply_summoner_xp(uid,xp_delta);

  insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
  values(uid,p_request_key,'DAILY_MISSION_'||upper(p_mission_id),gp_delta,essence_delta,w.gp,w.essence,jsonb_build_object('mission_id',p_mission_id,'server_date',today));

  response:=jsonb_build_object('mission_id',p_mission_id,'reward_label',reward->>'label','xp_delta',xp_delta,'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count));
  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response) values(uid,'genesis_claim_daily_mission',p_request_key,response);
  return response;
end
$$;

create or replace function public.genesis_claim_daily_completion(
  p_kind text,p_request_key text
)
returns jsonb
language plpgsql security definer set search_path=''
as $$
declare
  uid uuid:=(select auth.uid()); existing jsonb; w public.genesis_wallets%rowtype; d public.genesis_daily_server%rowtype;
  today date:=(now() at time zone 'UTC')::date; completed integer; gp_delta integer; essence_delta integer; xp_delta integer; label text; response jsonb;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_kind not in ('three','all') then raise exception 'INVALID_COMPLETION_KIND'; end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text||'|completion|'||p_request_key,0));
  select r.response into existing from public.genesis_rpc_receipts r where user_id=uid and rpc_name='genesis_claim_daily_completion' and request_key=p_request_key;
  if found then return existing; end if;

  select * into w from public.genesis_wallets where user_id=uid for update;
  if not found then raise exception 'SECURE_ECONOMY_NOT_INITIALIZED'; end if;
  insert into public.genesis_daily_server(user_id,date_key) values(uid,today) on conflict(user_id,date_key) do nothing;
  select * into d from public.genesis_daily_server where user_id=uid and date_key=today for update;
  completed:=private.genesis_completed_daily_count(today,d.progress);

  if p_kind='three' then
    if completed<3 then raise exception 'THREE_MISSIONS_NOT_COMPLETE'; end if;
    if d.completion_three then raise exception 'THREE_BONUS_ALREADY_CLAIMED'; end if;
    gp_delta:=10;essence_delta:=50;xp_delta:=25;label:='10 GP + 50 Essence + 25 Summoner EXP';d.completion_three:=true;
  else
    if completed<6 then raise exception 'ALL_MISSIONS_NOT_COMPLETE'; end if;
    if d.completion_all then raise exception 'ALL_BONUS_ALREADY_CLAIMED'; end if;
    gp_delta:=20;essence_delta:=100;xp_delta:=50;label:='20 GP + 100 Essence + 50 Summoner EXP';d.completion_all:=true;
  end if;

  w.gp:=w.gp+gp_delta;w.essence:=w.essence+essence_delta;
  update public.genesis_wallets set gp=w.gp,essence=w.essence,updated_at=now() where user_id=uid;
  update public.genesis_daily_server set completion_three=d.completion_three,completion_all=d.completion_all,updated_at=now() where user_id=uid and date_key=today;
  perform private.genesis_apply_summoner_xp(uid,xp_delta);

  insert into public.genesis_economy_ledger(user_id,request_key,event_type,gp_delta,essence_delta,gp_balance,essence_balance,metadata)
  values(uid,p_request_key,'DAILY_COMPLETION_'||upper(p_kind),gp_delta,essence_delta,w.gp,w.essence,jsonb_build_object('completed_missions',completed,'server_date',today));

  response:=jsonb_build_object('kind',p_kind,'reward_label',label,'xp_delta',xp_delta,'wallet',jsonb_build_object('gp',w.gp,'essence',w.essence,'pity_count',w.pity_count));
  insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response) values(uid,'genesis_claim_daily_completion',p_request_key,response);
  return response;
end
$$;

-- ------------------------------------------------------------
-- Privileges
-- ------------------------------------------------------------
revoke execute on function public.genesis_verify_achievements(text) from public,anon;
revoke execute on function public.genesis_meta_snapshot() from public,anon;
revoke execute on function public.genesis_online_summon(integer,boolean,text) from public,anon;
revoke execute on function public.genesis_claim_daily_mission(text,text) from public,anon;
revoke execute on function public.genesis_claim_daily_completion(text,text) from public,anon;

grant execute on function public.genesis_verify_achievements(text) to authenticated;
grant execute on function public.genesis_meta_snapshot() to authenticated;
grant execute on function public.genesis_online_summon(integer,boolean,text) to authenticated;
grant execute on function public.genesis_claim_daily_mission(text,text) to authenticated;
grant execute on function public.genesis_claim_daily_completion(text,text) to authenticated;

commit;

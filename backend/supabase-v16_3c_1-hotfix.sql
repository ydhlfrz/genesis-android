-- Genesis - Character Gacha V16.3C.1
-- G163 Summon Runtime Hotfix
--
-- Cause:
-- The V16.3B/V16.3C PostgreSQL Mulberry32 implementation multiplied two uint32-sized
-- values as signed BIGINT before applying modulo 2^32. The intermediate product can
-- reach ~1.84e19, above PostgreSQL BIGINT max (~9.22e18), causing runtime
-- "bigint out of range" during G163 summon generation.
--
-- This hotfix uses NUMERIC only for the multiplication intermediate, then returns
-- the exact low 32 bits as BIGINT. No tables/data are reset.
--
-- Safe to run after V16.3C. No redeploy is required for the backend fix itself.

begin;

-- Exact Math.imul-equivalent low 32-bit multiplication.
create or replace function private.genesis_imul32(
  p_a bigint,
  p_b bigint
)
returns bigint
language sql
immutable
strict
set search_path = ''
as $$
  select mod(
    private.genesis_u32(p_a)::numeric *
    private.genesis_u32(p_b)::numeric,
    4294967296::numeric
  )::bigint
$$;

-- Patch V16.3B deterministic equipment helper too.
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
  t := private.genesis_u32(p_seed_u32 + 1831565813);

  x := private.genesis_imul32(
    t # floor(t / 32768)::bigint,
    t | 1
  );

  x := private.genesis_u32(
    x # private.genesis_u32(
      x + private.genesis_imul32(
        x # floor(x / 128)::bigint,
        x | 61
      )
    )
  );

  x := private.genesis_u32(x # floor(x / 16384)::bigint);

  return x::double precision / 4294967296.0;
end
$$;

-- Patch V16.3C multi-output deterministic helper.
create or replace function private.genesis_mulberry32_at(
  p_seed_u32 bigint,
  p_index integer
)
returns double precision
language plpgsql
immutable
set search_path = ''
as $$
declare
  a bigint := private.genesis_u32(p_seed_u32);
  x bigint;
  out_value double precision := 0;
  i integer;
begin
  if p_index < 1 then
    raise exception 'INVALID_RNG_INDEX';
  end if;

  for i in 1..p_index loop
    a := private.genesis_u32(a + 1831565813);

    x := private.genesis_imul32(
      a # floor(a / 32768)::bigint,
      a | 1
    );

    x := private.genesis_u32(
      x # private.genesis_u32(
        x + private.genesis_imul32(
          x # floor(x / 128)::bigint,
          x | 61
        )
      )
    );

    x := private.genesis_u32(x # floor(x / 16384)::bigint);
    out_value := x::double precision / 4294967296.0;
  end loop;

  return out_value;
end
$$;

commit;

-- ------------------------------------------------------------
-- Optional verification queries.
-- These do NOT mutate player data.
-- ------------------------------------------------------------

select
  private.genesis_mulberry32_at(
    private.genesis_fnv1a32('G163-ABCDEF123456-01|CLASS_V163'),
    1
  ) as class_roll_test;

select
  private.genesis_server_class('G163-ABCDEF123456-01') as class_test,
  private.genesis_server_race('G163-ABCDEF123456-01',3) as race_test,
  private.genesis_server_weapon('G163-ABCDEF123456-01') as weapon_test;

select
  private.genesis_equipment_rarity_stars('G163-ABCDEF123456-01','armor') as armor_rarity_test;

-- Genesis - Character Gacha V16.4
-- Character Management & Prompt Studio
--
-- Adds:
-- - Private Supabase Storage bucket for submitted character artwork.
-- - Server-owned character media registry.
-- - RLS for per-account media reads.
-- - Storage policies restricted to the authenticated user's own character registry.
-- - Narrow RPC for attaching/replacing one primary generated artwork per character.
--
-- Prerequisites:
-- - supabase-schema.sql
-- - supabase-v16_1-migration.sql
-- - supabase-v16_3a-migration.sql
-- - supabase-v16_3b-migration.sql
-- - supabase-v16_3c-migration.sql
-- - supabase-v16_3c_1-hotfix.sql
-- - supabase-v16_3d-migration.sql

begin;

do $$
begin
  if to_regclass('public.genesis_characters') is null then
    raise exception 'V16.3A+ character registry is required before V16.4';
  end if;
end
$$;

-- ------------------------------------------------------------
-- Private artwork storage bucket
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'genesis-character-art',
  'genesis-character-art',
  false,
  10485760,
  array['image/png','image/jpeg','image/webp']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ------------------------------------------------------------
-- Canonical character media registry
-- ------------------------------------------------------------

create table if not exists public.genesis_character_media (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  registry_id uuid not null references public.genesis_characters(registry_id) on delete cascade,
  storage_path text not null,
  mime_type text not null check (mime_type in ('image/png','image/jpeg','image/webp')),
  file_size bigint not null check (file_size > 0 and file_size <= 10485760),
  prompt_snapshot text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (registry_id),
  unique (storage_path)
);

create index if not exists genesis_character_media_user_updated_idx
  on public.genesis_character_media(user_id, updated_at desc);

alter table public.genesis_character_media enable row level security;

revoke all on public.genesis_character_media from anon, authenticated;
grant select on public.genesis_character_media to authenticated;

drop policy if exists "Genesis character media select own" on public.genesis_character_media;
create policy "Genesis character media select own"
on public.genesis_character_media for select
to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

-- No direct INSERT / UPDATE / DELETE policy is granted for the media table.
-- Media metadata is written only through genesis_character_media_upsert().

-- ------------------------------------------------------------
-- Storage object policies
-- Path format is strictly:
--   <auth.uid()>/<registry_id>/primary
-- ------------------------------------------------------------

drop policy if exists "Genesis character art select own" on storage.objects;
create policy "Genesis character art select own"
on storage.objects for select
to authenticated
using (
  bucket_id = 'genesis-character-art'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.genesis_characters c
    where c.registry_id::text = (storage.foldername(name))[2]
      and c.user_id = (select auth.uid())
  )
);

drop policy if exists "Genesis character art insert own" on storage.objects;
create policy "Genesis character art insert own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'genesis-character-art'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and storage.filename(name) = 'primary'
  and exists (
    select 1
    from public.genesis_characters c
    where c.registry_id::text = (storage.foldername(name))[2]
      and c.user_id = (select auth.uid())
      and c.archived = false
  )
);

drop policy if exists "Genesis character art update own" on storage.objects;
create policy "Genesis character art update own"
on storage.objects for update
to authenticated
using (
  bucket_id = 'genesis-character-art'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.genesis_characters c
    where c.registry_id::text = (storage.foldername(name))[2]
      and c.user_id = (select auth.uid())
      and c.archived = false
  )
)
with check (
  bucket_id = 'genesis-character-art'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and storage.filename(name) = 'primary'
  and exists (
    select 1
    from public.genesis_characters c
    where c.registry_id::text = (storage.foldername(name))[2]
      and c.user_id = (select auth.uid())
      and c.archived = false
  )
);

drop policy if exists "Genesis character art delete own" on storage.objects;
create policy "Genesis character art delete own"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'genesis-character-art'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.genesis_characters c
    where c.registry_id::text = (storage.foldername(name))[2]
      and c.user_id = (select auth.uid())
  )
);

-- ------------------------------------------------------------
-- Server-validated attachment RPC
-- ------------------------------------------------------------

create or replace function public.genesis_character_media_upsert(
  p_registry_id uuid,
  p_storage_path text,
  p_mime_type text,
  p_file_size bigint,
  p_prompt_snapshot text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  expected_path text;
  row_data public.genesis_character_media%rowtype;
begin
  if uid is null then
    raise exception 'Authentication required';
  end if;

  if p_registry_id is null then
    raise exception 'Character registry ID is required';
  end if;

  if not exists (
    select 1
    from public.genesis_characters c
    where c.registry_id = p_registry_id
      and c.user_id = uid
      and c.archived = false
  ) then
    raise exception 'Character is not available in your active Collection';
  end if;

  if p_mime_type not in ('image/png','image/jpeg','image/webp') then
    raise exception 'Unsupported artwork format';
  end if;

  if p_file_size is null or p_file_size <= 0 or p_file_size > 10485760 then
    raise exception 'Artwork must be between 1 byte and 10 MB';
  end if;

  if p_prompt_snapshot is not null and char_length(p_prompt_snapshot) > 50000 then
    raise exception 'Prompt snapshot is too large';
  end if;

  expected_path := uid::text || '/' || p_registry_id::text || '/primary';
  if p_storage_path is distinct from expected_path then
    raise exception 'Invalid character artwork storage path';
  end if;

  if not exists (
    select 1
    from storage.objects o
    where o.bucket_id = 'genesis-character-art'
      and o.name = expected_path
  ) then
    raise exception 'Uploaded artwork object could not be verified';
  end if;

  insert into public.genesis_character_media(
    user_id, registry_id, storage_path, mime_type, file_size, prompt_snapshot
  ) values (
    uid, p_registry_id, expected_path, p_mime_type, p_file_size, p_prompt_snapshot
  )
  on conflict (registry_id) do update
  set
    user_id = excluded.user_id,
    storage_path = excluded.storage_path,
    mime_type = excluded.mime_type,
    file_size = excluded.file_size,
    prompt_snapshot = excluded.prompt_snapshot,
    updated_at = now()
  where public.genesis_character_media.user_id = uid
  returning * into row_data;

  if row_data.id is null then
    raise exception 'Character artwork metadata update was rejected';
  end if;

  return jsonb_build_object(
    'id', row_data.id,
    'registry_id', row_data.registry_id,
    'storage_path', row_data.storage_path,
    'mime_type', row_data.mime_type,
    'file_size', row_data.file_size,
    'created_at', row_data.created_at,
    'updated_at', row_data.updated_at
  );
end;
$$;

revoke all on function public.genesis_character_media_upsert(uuid,text,text,bigint,text) from public, anon;
grant execute on function public.genesis_character_media_upsert(uuid,text,text,bigint,text) to authenticated;

commit;

-- Run after the working V17 migration. Existing characters remain unchanged.
begin;
alter table public.genesis_characters add column if not exists selection_state text not null default 'kept' check(selection_state in ('pending','kept','discarded'));
create index if not exists genesis_characters_pending on public.genesis_characters(user_id,created_at desc) where selection_state='pending';
create or replace function private.genesis_new_character_pending() returns trigger language plpgsql set search_path='' as $$
begin
 new.selection_state:='pending';new.archived:=true;new.archived_at:=null;
 return new;
end;$$;
drop trigger if exists genesis_character_pending on public.genesis_characters;
create trigger genesis_character_pending before insert on public.genesis_characters for each row execute function private.genesis_new_character_pending();
revoke all on function private.genesis_new_character_pending() from public,anon,authenticated;
create or replace function public.genesis_character_decide(p_registry_id uuid,p_keep boolean) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=(select auth.uid());c public.genesis_characters%rowtype;target text;
begin
 if uid is null then raise exception 'AUTH_REQUIRED';end if;
 if p_keep is null then raise exception 'INVALID_DECISION';end if;
 target:=case when p_keep then 'kept' else 'discarded' end;
 select * into c from public.genesis_characters where registry_id=p_registry_id and user_id=uid for update;
 if not found then raise exception 'CHARACTER_NOT_FOUND';end if;
 if c.selection_state=target then return jsonb_build_object('state',target,'registry_id',p_registry_id);end if;
 if c.selection_state<>'pending' then raise exception 'CHARACTER_ALREADY_DECIDED';end if;
 update public.genesis_characters set selection_state=target,archived=not p_keep,archived_at=case when p_keep then null else now() end,updated_at=now() where registry_id=p_registry_id and user_id=uid;
 return jsonb_build_object('state',target,'registry_id',p_registry_id);
end;$$;
revoke all on function public.genesis_character_decide(uuid,boolean) from public,anon;
grant execute on function public.genesis_character_decide(uuid,boolean) to authenticated;
commit;

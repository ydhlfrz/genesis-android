begin;
create or replace function public.genesis_bulk_discard_unnamed(p_ids uuid[],p_request_key text) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=(select auth.uid());result jsonb;n integer;expected integer;
begin
 if uid is null then raise exception 'AUTH_REQUIRED';end if;
 if p_request_key is null or length(p_request_key) not between 8 and 160 then raise exception 'INVALID_REQUEST_KEY';end if;
 if p_ids is null or cardinality(p_ids) not between 1 and 1000 or array_position(p_ids,null) is not null then raise exception 'INVALID_SELECTION';end if;
 select count(distinct x) into expected from unnest(p_ids) x;
 perform pg_advisory_xact_lock(hashtextextended(uid::text||'|bulk_cleanup',0));
 select response into result from public.genesis_rpc_receipts where user_id=uid and rpc_name='genesis_bulk_discard_unnamed' and request_key=p_request_key;
 if found then return result;end if;
 -- Lock the reviewed IDs, then recheck their current name/favorite state.
 perform registry_id from public.genesis_characters where user_id=uid and registry_id=any(p_ids) order by registry_id for update;
 select count(*) into n from public.genesis_characters where user_id=uid and registry_id=any(p_ids) and not archived and selection_state='kept' and not favorite and btrim(coalesce(custom_name,''))='';
 if n<>expected then raise exception 'SELECTION_CHANGED_REFRESH_AND_REVIEW';end if;
 update public.genesis_characters set archived=true,archived_at=now(),selection_state='discarded',updated_at=now() where user_id=uid and registry_id=any(p_ids);
 result:=jsonb_build_object('discarded',n);
 insert into public.genesis_rpc_receipts(user_id,rpc_name,request_key,response) values(uid,'genesis_bulk_discard_unnamed',p_request_key,result);
 return result;
end;$$;
revoke all on function public.genesis_bulk_discard_unnamed(uuid[],text) from public,anon;
grant execute on function public.genesis_bulk_discard_unnamed(uuid[],text) to authenticated;
commit;

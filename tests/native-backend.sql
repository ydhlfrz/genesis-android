begin;
insert into auth.users(id) values('10000000-0000-0000-0000-000000000001'),('10000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
select public.genesis_profile_ensure('Native test');
select public.genesis_wallet_initialize(0,0);
do $$
declare r jsonb; again jsonb; k text:=gen_random_uuid()::text; id uuid;
begin
 begin
  perform public.genesis_wallet_initialize(100,0);
  raise exception 'bootstrap accepted invented currency';
 exception when raise_exception then if sqlerrm<>'NEW_WALLETS_START_AT_ZERO' then raise;end if; end;
 r:=public.genesis_online_summon(1,true,k);
 assert jsonb_array_length(r->'results')=1;
 again:=public.genesis_online_summon(1,true,k);assert r=again, 'idempotent summon';
 id:=(r->'results'->0->>'registry_id')::uuid;
 perform public.genesis_character_set_name(id,'Native Hero');
 perform public.genesis_character_set_favorite(id,true);
 assert (select count(*) from public.genesis_characters)=1;
 assert (select custom_name from public.genesis_characters where registry_id=id)='Native Hero';
 perform public.genesis_verify_achievements(gen_random_uuid()::text);
 assert public.genesis_meta_snapshot()->'codex' <> '[]'::jsonb;
 begin
  update public.genesis_wallets set gp=999999;
  raise exception 'direct wallet update succeeded';
 exception when insufficient_privilege then null; end;
end; $$;
reset role;
update public.genesis_wallets set gp=120,essence=5000 where user_id='10000000-0000-0000-0000-000000000001';
set local role authenticated;
do $$ declare r jsonb; id uuid;begin
 r:=public.genesis_online_summon(10,true,gen_random_uuid()::text);
 assert (r->>'cost')::int=120;
 assert jsonb_array_length(r->'results')=10;
 id:=(r->'results'->0->>'registry_id')::uuid;
 perform public.genesis_character_train(id,1,gen_random_uuid()::text);
 assert (select character_level from public.genesis_characters where registry_id=id)=2;
 perform public.genesis_character_upgrade_weapon(id,gen_random_uuid()::text);
 perform public.genesis_character_upgrade_equipment(id,'armor',gen_random_uuid()::text);
 assert (select armor_upgrade from public.genesis_characters where registry_id=id)=1;
 perform public.genesis_character_archive(id);
 assert (select archived from public.genesis_characters where registry_id=id);
end; $$;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
select public.genesis_profile_ensure('Other account');
do $$ begin assert (select count(*) from public.genesis_characters)=0, 'cross-account collection exposed';assert (select count(*) from public.genesis_wallets)=0, 'cross-account wallet exposed';end; $$;
set local role anon;
do $$ begin begin perform public.genesis_secure_snapshot();raise exception 'anonymous snapshot succeeded';exception when insufficient_privilege then null;end;end; $$;
reset role;
rollback;
select 'Native backend checks passed';

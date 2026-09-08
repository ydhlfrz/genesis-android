-- Only permits the zero-balance bootstrap already used by full-online Genesis.
-- Does not modify existing wallet balances. Apply after the web migrations.
begin;
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
  if p_initial_gp is distinct from 0 or p_initial_essence is distinct from 0 then raise exception 'NEW_WALLETS_START_AT_ZERO'; end if;
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
revoke execute on function public.genesis_wallet_initialize(bigint,bigint) from public,anon;
grant execute on function public.genesis_wallet_initialize(bigint,bigint) to authenticated;
commit;

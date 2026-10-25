-- NEXUS domain-agent prototype. Review existing schema before execution.
-- Additive migration: does not alter nexus_profiles/nexus_vault or their policies.
-- Run once, in the Supabase SQL Editor as a trusted project administrator.
begin;
create schema if not exists nexus_private;
revoke all on schema nexus_private from public;
grant usage on schema nexus_private to anon, authenticated;

create table public.nexus_domain_agents (
 id text primary key,
 codename text not null,
 domain text not null,
 min_role text not null check (min_role in ('member','operator','admin')),
 requires_grant boolean not null default false,
 title text not null,
 body text not null
);
create table public.nexus_agent_grants (
 user_id uuid not null references auth.users(id) on delete cascade,
 agent_id text not null references public.nexus_domain_agents(id) on delete cascade,
 granted_at timestamptz not null default now(),
 expires_at timestamptz,
 primary key(user_id,agent_id)
);
create table public.nexus_agent_access_log (
 id bigint generated always as identity primary key,
 created_at timestamptz not null default now(),
 actor_id uuid, -- retain historical identifier if an account is deleted
 agent_id text not null,
 outcome text not null check(outcome in ('granted','denied')),
 reason text not null,
 request_id uuid not null unique
);
create index nexus_agent_access_log_created on public.nexus_agent_access_log(created_at desc);
alter table public.nexus_domain_agents enable row level security;
alter table public.nexus_agent_grants enable row level security;
alter table public.nexus_agent_access_log enable row level security;
revoke all on public.nexus_domain_agents, public.nexus_agent_grants, public.nexus_agent_access_log from anon, authenticated;
-- No direct client read/write policies on agents or grants. Dossiers come via the logged RPC only.
grant select on public.nexus_agent_access_log to authenticated;
create policy nexus_agent_log_admin_read on public.nexus_agent_access_log
for select to authenticated using (
 exists(select 1 from public.nexus_profiles p where p.id=(select auth.uid()) and p.role='admin')
);

insert into public.nexus_domain_agents(id,codename,domain,min_role,requires_grant,title,body) values
('ghost','GHOST','Family / relationships','member',false,'GHOST // FAMILY FIELD NOTES',E'MOCK DATA ONLY\n\nMISSION\nKeep important people and shared commitments visible.\n\nQUEUE\n• Confirm a shared meal.\n• Plan a weekly family check-in.\n• Review household responsibilities.\n\nBOUNDARY\nNo messages sent. No contact accounts connected.'),
('architect','ARCHITECT','Work / business','member',false,'ARCHITECT // EXECUTION BOARD',E'MOCK DATA ONLY\n\nMISSION\nTranslate work and business goals into clear next actions.\n\nQUEUE\n• Review three sourcing candidates.\n• Compare estimated costs and fees.\n• Choose the next project milestone.\n\nBOUNDARY\nNo Amazon account connected. No purchases or listing changes.'),
('wolf','WOLF','Financial strategy','operator',true,'WOLF // FINANCIAL STRATEGY',E'MOCK DATA ONLY\n\nMISSION\nCoordinate long-term financial goals.\n\nQUEUE\n• Draft savings priorities.\n• Review a sample monthly budget.\n• Outline debt repayment goals.\n\nBOUNDARY\nNo bank connection. No financial transactions or personalized investment advice.'),
('ledger','LEDGER','Bills / obligations','operator',true,'LEDGER // OBLIGATIONS BOARD',E'MOCK DATA ONLY\n\nMISSION\nSeparate upcoming obligations from completed payments.\n\nSAMPLE ITEMS\n• Utilities — due date not configured.\n• Subscription review — pending.\n• Rent — sample record only.\n\nBOUNDARY\nNo real bill amounts, reminders, or payment execution.'),
('vital','VITAL','Health / personal care','operator',true,'VITAL // PERSONAL CARE',E'MOCK DATA ONLY\n\nMISSION\nProvide a dedicated space for personal routines and appointments.\n\nQUEUE\n• Plan a rest routine.\n• Add a sample appointment.\n• Review personal-care goals.\n\nBOUNDARY\nNo medical records or device monitoring. Not medical advice.'),
('scholar','SCHOLAR','Education / growth','member',false,'SCHOLAR // LEARNING TRACK',E'MOCK DATA ONLY\n\nMISSION\nGive education and skill development a clear structure.\n\nQUEUE\n• Outline a study schedule.\n• Compare course requirements.\n• Choose a practical skill milestone.\n\nBOUNDARY\nNo school account connected. Dates are not configured.');

create function nexus_private.request_agent_access(p_agent_id text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
 v_uid uuid:=auth.uid();
 v_role text;
 v_agent public.nexus_domain_agents%rowtype;
 v_reason text;
 v_allowed boolean:=false;
 v_request uuid:=gen_random_uuid();
 v_input text:=left(coalesce(p_agent_id,''),64);
 v_rank integer;
 v_required integer;
begin
 select * into v_agent from public.nexus_domain_agents where id=v_input;
 if v_agent.id is null then
  v_reason:='unknown_agent';
 elsif v_uid is null then
  v_reason:='sign_in_required';
 else
  select role into v_role from public.nexus_profiles where id=v_uid;
  v_rank:=case v_role when 'member' then 1 when 'operator' then 2 when 'admin' then 3 else 0 end;
  v_required:=case v_agent.min_role when 'member' then 1 when 'operator' then 2 when 'admin' then 3 else 999 end;
  if v_rank<v_required then
   v_reason:='clearance_required';
  elsif v_agent.requires_grant and not exists(
   select 1 from public.nexus_agent_grants g
   where g.user_id=v_uid and g.agent_id=v_agent.id
   and (g.expires_at is null or g.expires_at>now())
  ) then
   v_reason:='agent_grant_required';
  else
   v_allowed:=true;v_reason:='authorized';
  end if;
 end if;
 -- Denials return normally, so their audit INSERT is committed, not rolled back by an exception.
 insert into public.nexus_agent_access_log(actor_id,agent_id,outcome,reason,request_id)
 values(v_uid,v_input,case when v_allowed then 'granted' else 'denied' end,v_reason,v_request);
 if not v_allowed then
  return jsonb_build_object('allowed',false,'reason',v_reason,'request_id',v_request);
 end if;
 return jsonb_build_object('allowed',true,'reason',v_reason,'request_id',v_request,'role',v_role,
 'dossier',jsonb_build_object('title',v_agent.title,'body',v_agent.body));
end;
$$;
revoke all on function nexus_private.request_agent_access(text) from public;
grant execute on function nexus_private.request_agent_access(text) to anon,authenticated;
create function public.nexus_request_agent_access(p_agent_id text)
returns jsonb language sql security invoker set search_path=''
as $$ select nexus_private.request_agent_access(p_agent_id); $$;
revoke all on function public.nexus_request_agent_access(text) from public;
grant execute on function public.nexus_request_agent_access(text) to anon,authenticated;
commit;

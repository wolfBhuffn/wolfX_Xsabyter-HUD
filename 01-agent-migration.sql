-- NEXUS BUILD 06.1: additive agent dossiers, grants, and access-request log.
-- REVIEW BEFORE RUNNING. Run in Supabase SQL Editor as a trusted project administrator.
-- Does NOT change existing nexus_profiles/nexus_vault tables, roles, triggers, or policies.
-- Compatible with the earlier domain-upgrade schema if that exact migration was installed.
-- If these table names already exist with a DIFFERENT schema, STOP and inspect them first.
BEGIN;
DO $$ BEGIN
 IF to_regclass('public.nexus_profiles') IS NULL THEN
  RAISE EXCEPTION 'Existing nexus_profiles table required. Stop and inspect your project.';
 END IF;
END $$;
CREATE SCHEMA IF NOT EXISTS nexus_private;
REVOKE ALL ON SCHEMA nexus_private FROM PUBLIC;
GRANT USAGE ON SCHEMA nexus_private TO anon,authenticated;
-- Keep nexus_private OUT of Supabase's exposed API schemas.

CREATE TABLE IF NOT EXISTS public.nexus_domain_agents (
 id text PRIMARY KEY,
 codename text NOT NULL,
 domain text NOT NULL,
 min_role text NOT NULL CHECK(min_role IN ('member','operator','admin')),
 requires_grant boolean NOT NULL DEFAULT false,
 title text NOT NULL,
 body text NOT NULL
);
CREATE TABLE IF NOT EXISTS public.nexus_agent_grants (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 agent_id text NOT NULL REFERENCES public.nexus_domain_agents(id) ON DELETE CASCADE,
 granted_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz,
 PRIMARY KEY(user_id,agent_id)
);
CREATE TABLE IF NOT EXISTS public.nexus_agent_access_log (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 created_at timestamptz NOT NULL DEFAULT now(),
 actor_id uuid,
 agent_id text NOT NULL,
 outcome text NOT NULL CHECK(outcome IN ('granted','denied')),
 reason text NOT NULL,
 request_id uuid NOT NULL UNIQUE
);
CREATE INDEX IF NOT EXISTS nexus_agent_access_log_created
 ON public.nexus_agent_access_log(created_at DESC);
ALTER TABLE public.nexus_domain_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nexus_agent_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nexus_agent_access_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.nexus_domain_agents,public.nexus_agent_grants,public.nexus_agent_access_log FROM PUBLIC,anon,authenticated;
REVOKE ALL ON SEQUENCE public.nexus_agent_access_log_id_seq FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.nexus_agent_access_log TO authenticated;
-- No browser INSERT, UPDATE, DELETE, or direct dossier/grant SELECT.
-- Only this named policy is replaced; existing profiles/vault policies are untouched.
DROP POLICY IF EXISTS nexus_agent_log_admin_read ON public.nexus_agent_access_log;
CREATE POLICY nexus_agent_log_admin_read ON public.nexus_agent_access_log
 FOR SELECT TO authenticated USING(
 EXISTS(SELECT 1 FROM public.nexus_profiles p WHERE p.id=(SELECT auth.uid()) AND p.role='admin')
);

-- Sample text only. Do not overwrite existing dossier contents on re-run.
INSERT INTO public.nexus_domain_agents(id,codename,domain,min_role,requires_grant,title,body) VALUES
('ghost','GHOST','Family / relationships','member',false,'GHOST // FAMILY FIELD NOTES',E'MOCK DATA ONLY\n\nMISSION\nKeep important people and shared commitments visible.\n\nQUEUE\n- Confirm a shared meal.\n- Plan a weekly family check-in.\n- Review household responsibilities.\n\nBOUNDARY\nNo messages sent. No contact accounts connected.'),
('architect','ARCHITECT','Work / business','member',false,'ARCHITECT // EXECUTION BOARD',E'MOCK DATA ONLY\n\nMISSION\nTranslate work and business goals into clear next actions.\n\nQUEUE\n- Review three sourcing candidates.\n- Compare estimated costs and fees.\n- Choose the next project milestone.\n\nBOUNDARY\nNo Amazon connection. No purchases or listing changes.'),
('wolf','WOLF','Financial strategy','operator',true,'WOLF // FINANCIAL STRATEGY',E'MOCK DATA ONLY\n\nMISSION\nCoordinate long-term financial goals.\n\nQUEUE\n- Draft savings priorities.\n- Review a sample monthly budget.\n- Outline debt repayment goals.\n\nBOUNDARY\nNo bank connection or financial transactions.'),
('ledger','LEDGER','Bills / obligations','operator',true,'LEDGER // OBLIGATIONS BOARD',E'MOCK DATA ONLY\n\nMISSION\nSeparate upcoming obligations from completed payments.\n\nSAMPLE ITEMS\n- Utilities: due date not configured.\n- Subscription review: pending.\n- Rent: sample record only.\n\nBOUNDARY\nNo real bill amounts, reminders, or payment execution.'),
('vital','VITAL','Health / personal care','operator',true,'VITAL // PERSONAL CARE',E'MOCK DATA ONLY\n\nMISSION\nProvide space for personal routines and appointments.\n\nQUEUE\n- Plan a rest routine.\n- Add a sample appointment.\n- Review personal-care goals.\n\nBOUNDARY\nNo medical records or device monitoring. Not medical advice.'),
('scholar','SCHOLAR','Education / growth','member',false,'SCHOLAR // LEARNING TRACK',E'MOCK DATA ONLY\n\nMISSION\nGive education and skill development a clear structure.\n\nQUEUE\n- Outline a study schedule.\n- Compare course requirements.\n- Choose a skill milestone.\n\nBOUNDARY\nNo school connection. Dates are not configured.')
ON CONFLICT(id) DO NOTHING;

CREATE OR REPLACE FUNCTION nexus_private.request_agent_access(p_agent_id text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE
 v_uid uuid:=auth.uid();
 v_role text;
 v_agent public.nexus_domain_agents%ROWTYPE;
 v_reason text;
 v_allowed boolean:=false;
 v_request uuid:=pg_catalog.gen_random_uuid();
 v_input text:=left(coalesce(p_agent_id,''),64);
 v_rank integer;
 v_required integer;
BEGIN
 SELECT * INTO v_agent FROM public.nexus_domain_agents WHERE id=v_input;
 IF v_agent.id IS NULL THEN v_reason:='unknown_agent';
 ELSIF v_uid IS NULL THEN v_reason:='sign_in_required';
 ELSE
  SELECT role INTO v_role FROM public.nexus_profiles WHERE id=v_uid;
  v_rank:=CASE v_role WHEN 'member' THEN 1 WHEN 'operator' THEN 2 WHEN 'admin' THEN 3 ELSE 0 END;
  v_required:=CASE v_agent.min_role WHEN 'member' THEN 1 WHEN 'operator' THEN 2 WHEN 'admin' THEN 3 ELSE 999 END;
  IF v_rank<v_required THEN v_reason:='clearance_required';
  ELSIF v_agent.requires_grant AND NOT EXISTS(
   SELECT 1 FROM public.nexus_agent_grants g
   WHERE g.user_id=v_uid AND g.agent_id=v_agent.id
   AND(g.expires_at IS NULL OR g.expires_at>now())
  ) THEN v_reason:='agent_grant_required';
  ELSE v_allowed:=true;v_reason:='authorized';
  END IF;
 END IF;
 -- Denials return normally: raising an exception here would roll back their log entry.
 INSERT INTO public.nexus_agent_access_log(actor_id,agent_id,outcome,reason,request_id)
 VALUES(v_uid,v_input,CASE WHEN v_allowed THEN 'granted' ELSE 'denied' END,v_reason,v_request);
 IF NOT v_allowed THEN
  RETURN jsonb_build_object('allowed',false,'reason',v_reason,'request_id',v_request);
 END IF;
 RETURN jsonb_build_object('allowed',true,'reason',v_reason,'request_id',v_request,'role',v_role,
  'dossier',jsonb_build_object('title',v_agent.title,'body',v_agent.body));
END;
$$;
REVOKE ALL ON FUNCTION nexus_private.request_agent_access(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nexus_private.request_agent_access(text) TO anon,authenticated;
CREATE OR REPLACE FUNCTION public.nexus_request_agent_access(p_agent_id text)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path=''
AS $$ SELECT nexus_private.request_agent_access(p_agent_id); $$;
REVOKE ALL ON FUNCTION public.nexus_request_agent_access(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nexus_request_agent_access(text) TO anon,authenticated;
COMMIT;

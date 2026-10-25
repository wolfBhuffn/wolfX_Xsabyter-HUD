-- NEXUS BUILD 06.1 — trusted administrator operations.
-- DO NOT RUN THIS ENTIRE FILE AS A BATCH.
-- Read each section; select and execute only the intended statement.
-- No role promotion is performed by these examples.

-- 1. READ FIRST: resolve the CURRENT account. Do not assume a historical UUID.
SELECT u.id,u.email,p.role
FROM auth.users u LEFT JOIN public.nexus_profiles p ON p.id=u.id
WHERE lower(u.email)=lower('duff_beer-001@yopmail.com');

-- 2. AFTER verifying that exact account, grant selected agents.
-- Deliberately commented out to avoid accidental grants.
-- Admins also need these grants; members still fail the operator minimum.
-- INSERT INTO public.nexus_agent_grants(user_id,agent_id)
-- SELECT u.id,a.id FROM auth.users u CROSS JOIN public.nexus_domain_agents a
-- WHERE lower(u.email)=lower('duff_beer-001@yopmail.com')
-- AND a.id IN ('wolf','ledger','vital')
-- ON CONFLICT(user_id,agent_id) DO NOTHING;

-- 3. READ: list grants and expiration dates.
SELECT u.email,g.agent_id,g.granted_at,g.expires_at
FROM public.nexus_agent_grants g JOIN auth.users u ON u.id=g.user_id
ORDER BY u.email,g.agent_id;

-- 4. OPTIONAL: expire one grant after resolving the intended account.
-- UPDATE public.nexus_agent_grants g SET expires_at=now()
-- FROM auth.users u WHERE g.user_id=u.id
-- AND lower(u.email)=lower('duff_beer-001@yopmail.com') AND g.agent_id='wolf';

-- 5. READ: inspect recent server entry records.
SELECT id,created_at,actor_id,agent_id,outcome,reason,request_id
FROM public.nexus_agent_access_log ORDER BY id DESC LIMIT 100;

-- 6. OPTIONAL: edit a MOCK dossier through trusted administration.
-- UPDATE public.nexus_domain_agents
-- SET title='YOUR TITLE',body='YOUR MOCK DOSSIER TEXT'
-- WHERE id='ghost';

-- Use a private controlled admin email before storing personal data.
-- Never place passwords, tokens, or financial credentials in these records.

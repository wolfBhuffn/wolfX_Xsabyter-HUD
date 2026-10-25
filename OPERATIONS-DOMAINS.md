# NEXUS domain upgrade 06.0 — prototype

## What this is
An additive upgrade for the exact BUILD 05.2 source pasted in chat. It preserves the existing HUD, avatar sequence, public routes, login, vault, CLI, reveal effects and config.js. It adds six domain profiles, logged server-authorized dossier entry, explicit agent permissions, and an admin audit view. Domain assignments are proposals and all seeded records are mock data.

This package has NOT been deployed or tested against your Supabase project. No claim of browser/end-to-end verification is made. It is not a completed production personal-assistant service. It does not include autonomous agents, integrations, reminders, data-entry CRUD, reset/onboarding or MFA. The embedded BUILD 05.2 auth label remains; the footer identifies the upgrade.

## 1 — Save the baseline
Keep a Git checkpoint of the current working index.html and config.js. Export/record current schema, policies and grants before running any SQL. Do not commit credentials or a database export containing personal data. Keep the local backup outside the published repo: the patcher backup is for recovery, not deployment.

## 2 — Patch your actual source on your PC
Extract this package beside your current index.html. Keep config.js unchanged. With Python 3 installed, run `python upgrade.py` (or `py upgrade.py` on Windows).
The patcher checks the exact initialization anchor before changing anything and saves a baseline HTML backup. The resulting index.html is self-contained apart from your existing config.js, avatar images and Supabase CDN dependency. No script tag or disconnected snippet needs to be manually appended. Never append an entire HTML document to another file.
If the check fails, stop: your source differs from the supplied baseline.

## 3 — Review the additive migration
Inspect the real project schema first. Review migration-review-first.sql. New names must not already exist. Run it ONCE through your trusted Supabase SQL Editor. Putting SQL on GitHub does not execute it. The migration does not change your existing profiles/vault tables or their policies.
The log table's admin policy depends on your existing own-profile SELECT permission.
The nexus_private schema must NOT be added to Supabase's exposed API schemas.
No private dossier is selectable directly by a browser role; only the access RPC returns it after checking role and an explicit grant where required. The privileged helper lives outside the exposed schema. Protect all future read/export endpoints too or they may bypass the logged read path.

## 4 — Resolve the current account, then grant agent credentials
Special credentials mean trusted, per-account agent permissions, not extra shared passwords. Admin status alone does not bypass a required grant. Do not assume the historical account UUID is current.
Run a read first in SQL Editor:

```sql
select u.id,u.email,p.role
from auth.users u left join public.nexus_profiles p on p.id=u.id
where lower(u.email)=lower('duff_beer-001@yopmail.com');
```

After verifying the exact returned account, grant selected agents using the current email. Example grants for the test account, executed ONLY by the project administrator:

```sql
insert into public.nexus_agent_grants(user_id,agent_id)
select u.id,a.id
from auth.users u cross join public.nexus_domain_agents a
where lower(u.email)=lower('duff_beer-001@yopmail.com')
  and a.id in ('wolf','ledger','vital')
on conflict(user_id,agent_id) do nothing;
```

That permission does not elevate a member role. Role minimum AND agent permission must both pass. Permissions may have expires_at set; expired permissions are denied. Grant editing is deliberately not exposed in the browser. Use a private controlled admin email before real private data.

## 5 — Deploy
Upload the patched complete index.html through your existing GitHub workflow. Keep the existing config.js. The generated HTML includes the CSS/JS upgrade, so upgrade.py, nexus-domains.js and nexus-domains.css do not need to be hosted. Keep the baseline backup private/offline. No deployment was performed by the assistant.

## Experience
PERSONAS shows public agent identities and an entry toggle-styled link. Clicking it opens the public dossier shell and submits a server entry request. Approved contents glitch into view. Denied entries show the reason and server request ID, never protected text. Reduced motion suppresses the animation. Access attempts against this RPC are logged, including guest denials. ACCESS contains an admin-only log refresh panel. CLI adds `agents` and `audit`.
The button requests access; it never changes your role. Re-entering a dossier requests authorization again. Public card viewing itself is not a private-entry attempt.

## Logging limits — important
These are durable application access-request records, not comprehensive infrastructure/security logs. The server derives actor_id from the authenticated session, not browser-supplied identity. Clients cannot directly write, edit or delete the log. The RPC inserts the event and returns data in the same transaction; a logging failure prevents a successful response.
If a request never reaches the server, authentication is still connecting, SQL fails, or the network/CDN is down, a durable log cannot be guaranteed. The UI states this rather than pretending it logged. A timeout may occur after the server committed: the UI cannot confirm that case. Never log passwords, tokens or private record bodies.
Guest RPC calls can create log entries. There is no application-specific rate limiter or log retention job in this prototype; add an appropriately protected server gateway/rate limit and retention policy before broad public use. This log does not record every possible direct REST probe, database error, page visit, or Supabase dashboard action. Use platform/gateway auditing for that wider scope. It is not an immutable/tamper-proof compliance audit.

## Session limitations
The original BUILD 05.2 auth behavior is retained, including the documented cross-tab/session race review still outstanding. Server checks current roles/grants on EVERY entry, independently of stale badge state. Already displayed private contents cannot be un-seen or remotely erased after revocation; a fresh request will be denied. Session expiry/refresh and grant revocation while a page stays open need explicit negative tests. Demo mode never returns protected domain dossiers or claims a durable log.

## Test before private data
- Guest: request each agent; denied, sign-in-required log, no body.
- Member: GHOST/ARCHITECT/SCHOLAR succeed; WOLF/LEDGER/VITAL denied even with grants.
- Operator without grants: restricted agents denied.
- Operator with a grant: only that restricted agent succeeds.
- Admin without grants: restricted agents still denied.
- Admin with grants: permitted dossiers succeed, log readable.
- Non-admin direct log SELECT: no rows; direct agent/grant SELECT: denied.
- Direct RPC: repeat all checks without using the UI; validate server log outcome and actor_id.
- Try forged role metadata and agent IDs: never elevate access.
- Expire/revoke grant; next RPC denies. Change role; next RPC uses database role.
- Test rapid navigation, logout during pending request, cross-tab auth change, timeout, missing migration, unavailable CDN, reduced motion, keyboard and mobile.
- Verify original avatar cursor controls, all original routes, vault and CLI still work.

## Recovery
Restore your private baseline index.html and retain your working config.js. This removes the new UI but not new database objects. Do not drop tables containing records you need. Have a trusted database administrator review any database rollback; preserve/export logs first.

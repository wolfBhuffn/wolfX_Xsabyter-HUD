NEXUS BUILD 06.1 — COMPLETE REPLACEMENT FILES
================================================

CONTENTS
- index.html: complete replacement UI with inline CSS and JavaScript. No patcher.
- 01-agent-migration.sql: additive domain-agent database migration.
- 02-admin-operations.sql: read-first administrative queries; writes are commented out.
- README.txt: these installation instructions and boundaries.
- VALIDATION.txt: actual local checks performed for this package.

KEEP YOUR EXISTING config.js
It is intentionally NOT supplied: replacing it with a placeholder would break your working login.
Keep it next to index.html. Expected properties: mode='supabase', supabaseUrl, supabasePublishableKey.
Never use sb_secret_, service_role, database credentials or passwords in public client code.
No new browser libraries beyond the existing Supabase UMD dependency are introduced.

1 — BACK UP
Save a Git checkpoint/private local copy of your current working index.html and config.js.
Record/export the current database schema, policies and grants before migration.
Do not publish a database export containing private data.

2 — REPLACE THE HTML
Replace the entire existing index.html with the included complete index.html.
Do not append it. Do not use the earlier patcher. Keep your working config.js unchanged.
Publish through your existing GitHub workflow. This package does not deploy automatically.
The original hash-route structure, full HUD, cursor-follow avatar, CLI, reveal, login,
vault, telemetry, access map, and Herd views remain represented in this complete file.
Domain personas replace the old fictional cover/strategy/execution dossiers.
Demo-role selection is removed: missing auth never grants access.

3 — DATABASE SETUP
First inspect existing schema. Review 01-agent-migration.sql, then run it in your trusted
Supabase SQL Editor, not on GitHub. It adds agent tables/functions and a named log policy.
It does not replace existing nexus_profiles/nexus_vault tables or their policies.
If you already ran the PREVIOUS domain-upgrade migration, this migration accommodates
that exact schema and preserves existing dossier rows. It does not overwrite them.
If these table names exist with any other schema/policies, STOP and review differences.
Keep nexus_private OUT of Supabase's exposed API schemas.
No real database was inspected or migrated by the assistant.

4 — SPECIAL AGENT CREDENTIALS
Credential here means explicit account permission for an agent, not MFA or a shared PIN.
GHOST / family: member.
ARCHITECT / work: member.
SCHOLAR / education: member.
WOLF / financial strategy: operator + explicit grant.
LEDGER / bills: operator + explicit grant.
VITAL / personal care: operator + explicit grant.
Admin inherits role clearance but does NOT bypass the explicit grant requirement.
Use 02-admin-operations.sql one statement at a time. First resolve the current account
by email. Verify the returned ID/role. Only then intentionally uncomment/run the selected
grant query. No account passwords are provided or needed for trusted database grants.
The disposable test email is for MOCK records only. Use a private controlled admin email
before personal data. Agent-domain assignments are proposals, not final approved ontology.
The public cards mirror the bundled proposal; if you change server role requirements,
update card labels too. Server authorization remains authoritative even if labels differ.

5 — TEST
Public navigation should work with missing config/CDN; protected entry fails closed.
Request a dossier; look for a server request ID. Success glitches contents into view.
Denied requests reveal no private body. Reduced-motion suppresses animations.
Open ACCESS as admin and refresh the server log.
Test guest/member/operator/admin, with/without grants and with expired grants.
Test direct REST/RPC requests, not only navigation. Direct dossier/grant SELECT must fail;
non-admin log SELECT must not expose logs. Browser writes to roles/grants/logs must fail.
Changing user metadata or toggling UI cannot promote a role.
Test logout during requests, cross-tab sessions, timeouts, missing migration, mobile,
keyboard controls, frame retry, original vault, CLI and route navigation.
Avatar remains the supplied 130-frame chronological sequence, not a verified seamless 360.

WHAT THE LOG DOES / DOES NOT DO
Each RPC entry attempt logs its outcome on the server and returns a request ID.
Actor ID comes from auth.uid(), not a client-supplied username.
The same transaction inserts the log and returns authorized dossier contents.
Normal denials return without exceptions so their log entries commit.
Clients have no direct log write/update/delete permission.
This is not a comprehensive or tamper-proof infrastructure/security audit.
Requests that never reach the database, failed transactions and network outages cannot
be guaranteed logged. The UI does not claim success in those cases. A timeout can occur
after a commit, so logging may have happened even when the UI cannot confirm it.
Public profile views are not private-entry events. Automatic session refresh/re-entry may
produce additional genuine authorization requests. Direct denied table probes, dashboard
operations and page impressions require separate platform/gateway auditing.
Guest RPC requests can generate log rows: application-specific rate limiting and retention
are NOT implemented. Add a protected gateway/rate limiting and retention before broad
public deployment. Do not expose personal data while this is only a prototype.

SECURITY / COMPLETENESS BOUNDARIES
Mock dossier boards are provided, not editable life-management CRUD or autonomous agents.
No banks, bill payment, contact messaging, calendar backend, AI runtime, school account,
medical monitoring, reminder delivery or Amazon integration.
Reveal/redaction is visual narrative, not secrecy or encryption.
Only server-returned dossiers and your existing RLS vault are meant to be protected.
No MFA onboarding, reset flow, invitation UI, durable session revocation monitoring,
production backup automation, security audit, or rate limiter is delivered.
Server checks current role/grants on each entry. Already displayed content cannot be
un-seen; revocation affects new requests, not copies already obtained. Session badges may
lag external changes until refreshed. Cross-tab/concurrent auth needs live negative tests.
Third-party CDN delivery remains subject to dependency/security review.
No deployment, SQL execution, real credentials test, browser matrix or live security audit
was performed. Check VALIDATION.txt for the narrower checks actually completed.

RECOVERY
Restore your saved working index.html and keep config.js. New database objects remain;
do not drop logs/dossiers blindly. Export needed records and have a trusted administrator
review any database rollback. Existing profile/vault setup is not deliberately modified.

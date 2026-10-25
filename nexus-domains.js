
// Injected into the existing application closure by upgrade.py.
const domainAgents=[
{id:'ghost',name:'GHOST',title:'FAMILY / RELATIONSHIPS',directive:'Keep important people and shared commitments in view.',min:'member',credential:false,mark:'01'},
{id:'architect',name:'ARCHITECT',title:'WORK / BUSINESS',directive:'Turn projects, professional responsibilities, and business plans into deliberate action.',min:'member',credential:false,mark:'02'},
{id:'wolf',name:'WOLF',title:'FINANCIAL STRATEGY',directive:'Review the bigger picture: budgets, savings, debt, and long-term goals.',min:'operator',credential:true,mark:'03'},
{id:'ledger',name:'LEDGER',title:'BILLS / OBLIGATIONS',directive:'Know what is due, what is paid, and what needs attention.',min:'operator',credential:true,mark:'04'},
{id:'vital',name:'VITAL',title:'HEALTH / PERSONAL CARE',directive:'Give routines, wellbeing, and appointments their own space.',min:'operator',credential:true,mark:'05'},
{id:'scholar',name:'SCHOLAR',title:'EDUCATION / GROWTH',directive:'Organize courses, assignments, and skill development.',min:'member',credential:false,mark:'06'}
];
// These are public labels, not confidential dossiers. The server decides access.
personas.splice(0,personas.length,...domainAgents);
PERMISSIONS.dossier='guest'; // Public shell only; RPC authorizes every private dossier read.
let domainRequest=0;
const safeNode=(tag,text,cls)=>{const el=document.createElement(tag);if(text!==undefined)el.textContent=text;if(cls)el.className=cls;return el;};
function domainLink(a){return '#/personas/'+a.id;}
function paintDomainRegistry(){
 const host=$('personaCards');host.replaceChildren();
 domainAgents.forEach(a=>{
  const card=safeNode('article',undefined,'panel agent-card');
  card.append(safeNode('span',a.title,'eyebrow'),safeNode('h2',a.name),safeNode('p',a.directive));
  const meta=safeNode('div',undefined,'agent-clearance');
  meta.append(safeNode('div','MINIMUM: '+a.min.toUpperCase(),'agent-status'),safeNode('div',a.credential?'SPECIAL CREDENTIAL: AGENT GRANT REQUIRED':'SPECIAL CREDENTIAL: STANDARD SESSION','agent-status'));
  const link=safeNode('a',undefined,'button agent-entry');link.href=domainLink(a);
  link.append(safeNode('span','PUBLIC PROFILE ⇄ DOSSIER'),safeNode('span','REQUEST ENTRY →'));
  card.append(meta,link);host.append(card);
 });
}
paintDomainRegistry();
const registry=document.querySelector('[data-page="personas"]');
registry.querySelector('.eyebrow').textContent='NEXUS // LIFE-DOMAIN AGENT REGISTRY';
registry.querySelector('h1').innerHTML='ONE NEXUS.<br><span class="gradient">DEDICATED DOMAINS.</span>';
registry.querySelector('p').textContent='Proposed domain assignments. Public profiles are visible; dossier entry requires server approval. Each entry request is submitted for logging.';
const nexusPage=document.querySelector('[data-page="nexus"]');
nexusPage.querySelector('h1').innerHTML='NEXUS.<br><span class="gradient">CENTRAL COORDINATOR.</span>';
nexusPage.querySelector('.hero > div:last-child > .tag').textContent='MAIN AGENT // IDENTITY · PRIORITIES · DOMAINS';
nexusPage.querySelector('.hero > div:last-child > p').textContent='One coordinating identity. Dedicated agents for family, work, financial strategy, bills, wellbeing, and learning. Open the registry to request entry to a domain.';
const nxButtons=nexusPage.querySelector('.buttons');
const registryLink=safeNode('a','DOMAIN AGENTS →','button');registryLink.href='#/personas';nxButtons.prepend(registryLink);
const homePage=document.querySelector('[data-page="home"]');
homePage.querySelector('.eyebrow').textContent='NEXUS // PERSONAL COMMAND SYSTEM';
homePage.querySelector('.landing p').textContent='NEXUS is the main coordinating agent. Specialized codenames organize the domains of your life, with restricted dossiers behind server-checked clearance.';
const nxBrief=safeNode('div',undefined,'panel agent-audit');
nxBrief.append(safeNode('span','DOMAIN NETWORK // MOCK-DATA PROTOTYPE','eyebrow'),safeNode('h2','Choose a domain. Request entry.'));
const nxGrid=safeNode('div',undefined,'agent-grid');
domainAgents.forEach(a=>{const link=safeNode('a',a.name+' // '+a.title,'button');link.href=domainLink(a);nxGrid.append(link);});
nxBrief.append(nxGrid,safeNode('p','No external accounts connected. No payments, messages, health monitoring, or autonomous actions.'));
nexusPage.append(nxBrief);
const auditPanel=safeNode('section',undefined,'panel agent-audit');
auditPanel.append(safeNode('span','SERVER EVENTS // ADMIN ONLY','eyebrow'),safeNode('h2','Agent access attempts'));
const auditIntro=safeNode('p','Records are read from the database. This is separate from the local session-event display.');
const auditButton=safeNode('button','REFRESH ACCESS LOG');auditButton.type='button';
const auditStatus=safeNode('p','','agent-status'),auditBody=safeNode('div',undefined,'tablewrap');
auditPanel.append(auditIntro,auditButton,auditStatus,auditBody);document.querySelector('[data-page="access"]').append(auditPanel);
async function refreshAgentAudit(){
 auditBody.replaceChildren();auditStatus.textContent='Loading server log…';
 if(!client||role()!=='admin'){auditStatus.textContent='An authenticated admin session is required.';return;}
 try{
  const result=await deadline(client.from('nexus_agent_access_log').select('id,created_at,actor_id,agent_id,outcome,reason,request_id').order('id',{ascending:false}).limit(100),12000,'Agent audit log');
  if(result.error)throw result.error;
  if(role()!=='admin'){auditStatus.textContent='Session changed. Request again.';return;}
  const table=safeNode('table'),head=safeNode('thead'),tr=safeNode('tr');
  ['UTC TIME','ACTOR ID','AGENT','RESULT / REASON','REQUEST ID'].forEach(t=>tr.append(safeNode('th',t)));head.append(tr);table.append(head);
  const body=safeNode('tbody');(result.data||[]).forEach(row=>{const r=safeNode('tr');[row.created_at,row.actor_id||'UNAUTHENTICATED',row.agent_id,row.outcome+' / '+row.reason,row.request_id].forEach(v=>r.append(safeNode('td',String(v))));body.append(r);});
  table.append(body);auditBody.append(table);auditStatus.textContent=(result.data||[]).length+' most recent events. Refresh to update.';
 }catch(e){auditStatus.textContent='Log unavailable: '+e.message+' Apply the reviewed migration if it has not been installed.';}
}
auditButton.onclick=refreshAgentAudit;
const originalClearPrivate=clearPrivate;
clearPrivate=function(){domainRequest++;auditBody.replaceChildren();auditStatus.textContent='';originalClearPrivate();};
renderDossier=function(a){
 const ticket=++domainRequest,host=$('dossierContent');host.replaceChildren();
 const card=safeNode('article',undefined,'panel agent-audit');
 card.append(safeNode('span','NEXUS // DOMAIN AGENT '+a.mark,'eyebrow'),safeNode('h1',a.name),safeNode('span',a.title,'tag'),safeNode('p',a.directive));
 card.append(safeNode('p','REQUIRED: '+a.min.toUpperCase()+(a.credential?' + EXPLICIT AGENT GRANT':''),'agent-status'));
 const status=safeNode('div','Submitting entry request…','agent-result agent-status');
 const actions=safeNode('div',undefined,'buttons'),retry=safeNode('button','REQUEST ENTRY AGAIN');retry.onclick=()=>renderDossier(a);
 const login=safeNode('a','ACCESS PORTAL','button');login.href='#/login';login.onclick=()=>{pendingRoute='/personas/'+a.id;};
 actions.append(retry,login);card.append(status,actions,safeNode('p','Public identity labels are not secret. Protected dossier contents come only from the server.','notice'));host.append(card);
 const valid=()=>ticket===domainRequest&&location.hash.replace(/^#\/?/,'')==='personas/'+a.id;
 (async()=>{
  if(DEMO){status.textContent='Restricted dossiers are disabled in demo mode. No durable access log was written.';return;}
  if(authState==='connecting'){
   status.textContent='Authentication is still connecting. Use REQUEST ENTRY AGAIN when ready. No server attempt recorded yet.';return;
  }
  if(!client){status.textContent='Connection unavailable. Access denied locally; this attempt could not be recorded on the server.';return;}
  retry.disabled=true;
  try{
   const result=await deadline(client.rpc('nexus_request_agent_access',{p_agent_id:a.id}),12000,'Agent entry');
   if(!valid())return;
   if(result.error)throw result.error;
   const data=result.data;
   if(!data||typeof data.allowed!=='boolean')throw new Error('Unexpected response. Access remains closed.');
   status.replaceChildren();
   status.append(safeNode('div','REQUEST '+data.request_id+' // '+(data.allowed?'GRANTED':'DENIED'),'eyebrow'));
   if(!data.allowed){
    const reasons={sign_in_required:'Sign in, then request entry again.',clearance_required:'Your account clearance does not meet this agent’s requirement.',agent_grant_required:'An explicit permission for this agent is required—even for admin accounts.',unknown_agent:'This agent is not registered on the server.'};
    status.classList.add('agent-locked');status.append(safeNode('p',reasons[data.reason]||'Entry denied.'));status.append(safeNode('p','Server attempt recorded. No private dossier returned.','agent-status'));return;
   }
   login.hidden=true;status.classList.remove('agent-locked');
   const content=safeNode('section');
   content.append(safeNode('h2',data.dossier.title),safeNode('div',data.dossier.body,'agent-record'),safeNode('p','Server-authorized dossier // '+data.role.toUpperCase()+' // access event recorded','agent-status'));
   status.append(content);
   if(!reduced.matches){content.classList.add('agent-transition');pulse();setTimeout(()=>content.classList.remove('agent-transition'),500);}
   log('Agent entry granted: '+a.id+'. Server request '+data.request_id);
  }catch(e){if(valid())status.textContent='ENTRY CLOSED: '+e.message+' Server logging could not be confirmed; do not assume this attempt was recorded.';}
  finally{if(valid())retry.disabled=false;}
 })();
};
// Extra commands use existing history/output behavior via the original runner.
const originalRun=run;
run=function(raw){const t=raw.trim().toLowerCase();if(!allowed('terminal')){route();return;}if(t==='agents'){out(domainAgents.map(a=>a.id+' — '+a.title+' ['+a.min+(a.credential?' + grant':'')+']').join('\n'));return;}if(t==='audit'){if(role()!=='admin'){out('Admin clearance required.','error');return;}location.hash='/access';refreshAgentAudit();return;}originalRun(raw);};
commands.push('agents','audit');
const oldRoute=route;
route=function(){oldRoute();if(location.hash==='#/access'&&role()==='admin')refreshAgentAudit();};
// The initial hash listener still calls oldRoute; auto audit refresh is optional.
window.addEventListener('hashchange',()=>{if(location.hash==='#/access'&&role()==='admin')refreshAgentAudit();});
$('authbar').setAttribute('aria-live','polite');
const footer=document.querySelector('footer');footer.textContent='NEXUS // DOMAIN UPGRADE 06.0 · MOCK RECORDS · REAL AUTHORIZATION WHEN MIGRATED · NO EXTERNAL ACTIONS';

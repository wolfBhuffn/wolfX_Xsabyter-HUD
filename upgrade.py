from pathlib import Path
import shutil
root=Path(__file__).resolve().parent
p=root/'index.html'
if not p.exists():
    raise SystemExit('Place this package beside your current index.html and config.js, then run again.')
s=p.read_text(encoding='utf-8-sig')
marker='/* NEXUS DOMAIN UPGRADE 06.0 */'
if marker in s:
    raise SystemExit('Upgrade already installed. Restore your baseline before reinstalling.')
anchor='tick();setInterval(tick,1000);renderSession();log(\'Interface initialized.\');route();connectAuth();'
if s.count(anchor)!=1:
    raise SystemExit('Expected BUILD 05.2 initialization not found exactly once. No files changed.')
backup=root/'index.build-05.2.backup.html'
if backup.exists():
    raise SystemExit('Backup already exists. Move it somewhere safe before proceeding. No files changed.')
shutil.copy2(p,backup)
js=(root/'nexus-domains.js').read_text(encoding='utf-8')
css=(root/'nexus-domains.css').read_text(encoding='utf-8')
s=s.replace('</style>', '\n'+css+'\n</style>',1)
s=s.replace(anchor,marker+'\n'+js+'\n'+anchor)
p.write_text(s,encoding='utf-8')
print('Created upgraded index.html. config.js was not changed. Baseline backup saved locally.')

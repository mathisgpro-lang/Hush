import subprocess,time,os
from pathlib import Path
log=Path(os.environ.get('HUSH_PHONE_BUILD_LOG','/tmp/hush-wide-phone.log'))
for _ in range(240):
 text=log.read_text()
 if '** BUILD FAILED **' in text:raise SystemExit('Phone build failed; installation skipped.')
 if '** BUILD SUCCEEDED **' in text:break
 time.sleep(5)
else:raise SystemExit('Build still pending; installation skipped.')
device='00008120-001411043639A01E';bundle='com.mathis.lifegamified.spikelab'
r=subprocess.run(['xcrun','devicectl','device','install','app','--device',device,'prototypes/p2-spikes/dd-spikelab-dev/Build/Products/Release-iphoneos/SpikeLab.app'],text=True,capture_output=True)
Path('/tmp/hush-wide-install.log').write_text(r.stdout+r.stderr)
print(r.stdout+r.stderr,flush=True)
if r.returncode:raise SystemExit(r.returncode)
r=subprocess.run(['xcrun','devicectl','device','process','launch','--device',device,'--terminate-existing',bundle,'--','-skipintro','-nogift'],text=True,capture_output=True)
Path('/tmp/hush-wide-launch.log').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr,flush=True)
raise SystemExit(r.returncode)

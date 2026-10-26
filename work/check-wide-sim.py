import subprocess,time
from pathlib import Path
for _ in range(240):
 s=Path('/tmp/hush-wide-sim.log').read_text()
 if '** BUILD FAILED **' in s:raise SystemExit('Simulator build failed')
 if '** BUILD SUCCEEDED **' in s:break
 time.sleep(5)
else:raise SystemExit('Simulator build pending')
subprocess.run(['xcrun','simctl','install','448DC48F-484B-45CD-86CC-89FFF3182EC6','/tmp/hush-depth-sim/Build/Products/Release-iphonesimulator/SpikeLab.app'],check=True)
subprocess.run(['python3','work/capture-wide.py'],check=True)
